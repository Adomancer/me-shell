import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.utils

// Isi bar. Latarnya digambar oleh Frame di Drawers, jadi di sini transparan.
Item {
    id: root

    // Window induk, dibutuhkan untuk membuka menu tray
    property var window

    implicitHeight: Config.barHeight

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.frame.thickness + Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "apps"
            toggled: DrawerState.active === "launcher"
            onClicked: DrawerState.toggleLauncher("")
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
        }

        ActiveWindow {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTitle
        }
    }

    Clock {
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

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.barShowTray && count > 0
            window: root.window
        }

        Status {
            anchors.verticalCenter: parent.verticalCenter
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "power_settings_new"
            toggled: DrawerState.active === "session"
            onClicked: DrawerState.toggle("session")
        }
    }
}
