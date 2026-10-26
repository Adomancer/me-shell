import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.services
import qs.utils

// Isi bar. Latarnya digambar oleh Frame di Drawers; item di sini tanpa kotak, dikelompokkan
// dengan jarak dan garis pemisah tipis. Drawer yang terbuka ditandai strip aksen (ActiveDot).
Item {
    id: root

    // Window induk, dibutuhkan untuk membuka menu tray
    property var window
    readonly property bool clockHovered: clock.hovered

    // Garis pemisah tegak antar kelompok
    component Separator: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 14
        color: Appearance.colors.hairline
    }

    implicitHeight: Config.barHeight

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.frame.thickness + Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.large

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "apps"
            toggled: DrawerState.active === "launcher"
            onClicked: DrawerState.toggleLauncher("")

            ActiveDot {
                active: parent.toggled
            }
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
        }

        Separator {
            visible: Config.barShowTitle && ToplevelManager.activeToplevel !== null
        }

        ActiveWindow {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTitle
        }
    }

    Clock {
        id: clock

        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.frame.thickness + Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        BarRecording {
            anchors.verticalCenter: parent.verticalCenter
            visible: Recorder.recording
        }

        BarMedia {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowMedia && Media.active !== null
        }

        Separator {
            visible: Recorder.recording || (Config.barShowMedia && Media.active !== null)
        }

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTray && count > 0
            window: root.window
        }

        Status {
            anchors.verticalCenter: parent.verticalCenter
        }

        Separator {}

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "widgets"
            toggled: DrawerState.active === "utilities"
            onClicked: DrawerState.toggle("utilities")

            ActiveDot {
                active: parent.toggled
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "power_settings_new"
            toggled: DrawerState.active === "session"
            onClicked: DrawerState.toggle("session")

            ActiveDot {
                active: parent.toggled
            }
        }
    }
}
