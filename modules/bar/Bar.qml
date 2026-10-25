import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.utils

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    color: "transparent"
    implicitHeight: Config.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    StyledRect {
        anchors.fill: parent
        color: Appearance.colors.surface
        radius: Appearance.radius.none

        // Garis bawah tegas ala retro
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Appearance.border.normal
            color: Appearance.colors.outline
        }
    }

    // Kiri: nanti workspace
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal
    }

    // Tengah: jam, nanti jadi pemicu control panel
    StyledText {
        anchors.centerIn: parent
        text: Time.time
        color: Appearance.colors.primary
        font.bold: true
    }

    // Kanan: nanti tray + status
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        StyledText {
            text: Time.dateText
            color: Appearance.colors.textDim
        }
    }
}
