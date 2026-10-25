import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services
import qs.utils

// Wallpaper dirender oleh shell. Matikan dengan "renderWallpaper": false kalau pakai swww/hyprpaper.
Variants {
    model: Config.renderWallpaper ? Quickshell.screens : []

    PanelWindow {
        id: win

        required property ShellScreen modelData

        function apply(): void {
            const url = Wallpaper.current ? `file://${Wallpaper.current}` : "";
            if (url === cur.source.toString())
                return;
            prev.source = cur.source;
            prev.opacity = 1;
            cur.source = url;
        }

        screen: modelData
        color: Appearance.colors.background
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "me-shell-background"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Image {
            id: cur

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.modelData.width, win.modelData.height)
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && prev.opacity > 0)
                    swap.restart();
            }
        }

        // Gambar lama, memudar setelah gambar baru siap
        Image {
            id: prev

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.modelData.width, win.modelData.height)
            opacity: 0
        }

        // Gambar baru menyusut pelan ke ukuran asli sementara yang lama memudar
        ParallelAnimation {
            id: swap

            Anim {
                target: prev
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.extraLarge
            }
            Anim {
                target: cur
                property: "scale"
                from: 1.08
                to: 1
                duration: Appearance.anim.durations.extraLarge * 1.4
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }

        Connections {
            target: Wallpaper

            function onCurrentChanged(): void {
                win.apply();
            }
        }

        Component.onCompleted: apply()
    }
}
