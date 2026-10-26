import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services
import qs.utils

// Widget di atas wallpaper (layer Bottom, di bawah semua window): jam besar dan visualizer cava.
// Window terpisah dari Background supaya tetap jalan walau wallpaper dirender swww/hyprpaper.
// Tidak menangkap input sama sekali.
Variants {
    model: Config.desktopClock || Config.desktopVisualizer ? Quickshell.screens : []

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property int margin: Appearance.frame.thickness + 56
        readonly property int vizHeight: Math.round(height * 0.18)
        readonly property string pos: Config.desktopClockPosition
        // Window fullscreen menutupi visualizer; cava tidak perlu jalan untuknya
        readonly property bool covered: Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false
        property bool usingCava: Config.desktopVisualizer && !covered

        screen: modelData
        color: "transparent"
        mask: Region {}
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "me-shell-desktop"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onUsingCavaChanged: Cava.users += usingCava ? 1 : -1
        Component.onCompleted: {
            if (usingCava)
                Cava.users++;
        }
        Component.onDestruction: {
            if (usingCava)
                Cava.users--;
        }

        Visualizer {
            visible: Config.desktopVisualizer
            x: Appearance.frame.thickness
            y: parent.height - Appearance.frame.thickness - height
            width: parent.width - Appearance.frame.thickness * 2
            height: win.vizHeight
        }

        // Memudar saat ada drawer terbuka di monitor ini, supaya tidak ada dua jam sekaligus
        Item {
            anchors.fill: parent
            opacity: DrawerState.active !== "" && DrawerState.screen === win.modelData.name ? 0 : 1

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.normal
                }
            }

            DesktopClock {
                id: clock

                visible: Config.desktopClock
                align: win.pos.includes("kanan") ? Text.AlignRight : win.pos === "tengah" ? Text.AlignHCenter : Text.AlignLeft
                x: win.pos.includes("kanan") ? parent.width - width - win.margin : win.pos === "tengah" ? (parent.width - width) / 2 : win.margin
                y: win.pos.includes("atas") ? Config.barHeight + win.margin - Appearance.frame.thickness : win.pos === "tengah" ? (parent.height - height) / 2 : parent.height - height - win.margin - (Config.desktopVisualizer ? win.vizHeight / 3 : 0)
                opacity: 0

                transform: Translate {
                    id: rise

                    y: 24
                }

                // Masuk pelan dari bawah saat shell start
                ParallelAnimation {
                    running: true

                    Anim {
                        target: clock
                        property: "opacity"
                        to: 1
                        duration: Appearance.anim.durations.extraLarge
                    }
                    Anim {
                        target: rise
                        property: "y"
                        to: 0
                        duration: Appearance.anim.durations.extraLarge
                        easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                    }
                }
            }
        }
    }
}
