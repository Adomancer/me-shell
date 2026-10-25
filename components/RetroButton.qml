import QtQuick
import qs.utils

StyledRect {
    id: root

    property string text: ""
    property bool active: false
    readonly property alias hovered: mouse.containsMouse

    signal clicked

    implicitWidth: label.implicitWidth + Appearance.spacing.large * 2
    implicitHeight: label.implicitHeight + Appearance.spacing.normal * 2
    color: active ? Appearance.colors.primary : mouse.containsMouse ? Appearance.colors.surfaceHigh : "transparent"
    border.width: Appearance.border.thin
    border.color: active ? Appearance.colors.primary : Appearance.colors.outline
    opacity: enabled ? 1 : 0.4

    // Efek "ditekan": turun 1px
    transform: Translate {
        y: mouse.pressed ? 1 : 0
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.active ? Appearance.colors.onPrimary : Appearance.colors.text
        font.bold: root.active
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
