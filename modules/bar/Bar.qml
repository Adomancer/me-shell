import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.utils

Item {
    id: root

    // Window induk, dibutuhkan untuk membuka menu tray
    property var window

    implicitHeight: Config.barHeight

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.surface

        // Garis bawah tegas ala retro
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Appearance.border.normal
            color: Appearance.colors.outline
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.large

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTitle
            width: Math.min(implicitWidth, 320)
            elide: Text.ElideRight
            text: ToplevelManager.activeToplevel?.title ?? ""
            color: Appearance.colors.textDim
        }
    }

    Clock {
        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.large

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTray
            window: root.window
        }

        Status {
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
