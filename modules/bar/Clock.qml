import QtQuick
import qs.components
import qs.services
import qs.utils

// Jam di tengah bar. Klik untuk membuka control panel.
StyledRect {
    id: root

    readonly property bool active: DrawerState.active === "panel"
    property bool cursorOn: true

    implicitWidth: row.implicitWidth + Appearance.spacing.large * 2
    implicitHeight: Config.barHeight - Appearance.spacing.small * 2 - Appearance.border.normal
    color: active ? Appearance.colors.primary : mouse.containsMouse ? Appearance.colors.surfaceHigh : "transparent"

    Row {
        id: row

        anchors.centerIn: parent

        StyledText {
            text: Time.time
            color: root.active ? Appearance.colors.primaryText : Appearance.colors.primary
            font.bold: true
        }

        // Kursor terminal yang berkedip
        StyledText {
            text: "_"
            opacity: root.cursorOn ? 1 : 0
            color: root.active ? Appearance.colors.primaryText : Appearance.colors.primary
            font.bold: true
        }
    }

    Timer {
        interval: 530
        repeat: true
        running: Config.blinkCursor
        onTriggered: root.cursorOn = !root.cursorOn
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: DrawerState.toggle("panel")
    }
}
