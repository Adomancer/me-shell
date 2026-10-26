import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Pratinjau langsung window aktif plus tombol cepat (mengambang, layar penuh, tutup).
ColumnLayout {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property var entry: toplevel?.appId ? DesktopEntries.heuristicLookup(toplevel.appId) : null
    readonly property int previewWidth: 360
    readonly property int pageWidth: previewWidth

    spacing: Appearance.spacing.normal

    StyledClippingRect {
        Layout.fillWidth: true
        implicitHeight: root.toplevel && preview.sourceSize.width > 0 ? Math.min(260, root.previewWidth * preview.sourceSize.height / preview.sourceSize.width) : 120
        radius: Appearance.radius.normal
        color: Appearance.colors.surfaceContainer

        ScreencopyView {
            id: preview

            anchors.fill: parent
            captureSource: root.toplevel
            live: true
            constraintSize: Qt.size(root.previewWidth * 2, 520)
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: !root.toplevel || !preview.hasContent
            text: root.toplevel ? "hourglass_empty" : "desktop_windows"
            font.pixelSize: Appearance.font.size.huge
            color: Appearance.colors.outline
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        AppIcon {
            visible: root.toplevel !== null
            size: 32
            icon: root.entry?.icon ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.entry?.name ?? root.toplevel?.appId ?? "Desktop"
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.toplevel?.title ?? "Tidak ada window aktif"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            visible: root.toplevel !== null
            icon: "picture_in_picture_alt"
            type: "tonal"
            onClicked: Hyprland.dispatch("togglefloating")
        }

        IconButton {
            visible: root.toplevel !== null
            icon: "fullscreen"
            type: "tonal"
            onClicked: Hyprland.dispatch("fullscreen 1")
        }

        IconButton {
            visible: root.toplevel !== null
            icon: "close"
            type: "tonal"
            onClicked: {
                Hyprland.dispatch("killactive");
                DrawerState.close();
            }
        }
    }
}
