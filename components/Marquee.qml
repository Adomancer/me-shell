import QtQuick
import qs.utils

// Teks berjalan ala papan LED.
Rectangle {
    id: root

    property string text: ""
    property int pixelSize: 22

    implicitHeight: label.implicitHeight + Appearance.spacing.normal * 2
    color: Appearance.colors.background
    border.width: Appearance.border.thin
    border.color: Appearance.colors.outline
    clip: true

    StyledText {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Appearance.colors.primary
        font.pixelSize: root.pixelSize
        font.bold: true

        NumberAnimation on x {
            from: root.width
            to: -label.implicitWidth
            duration: Math.max(4000, (root.width + label.implicitWidth) * 12)
            loops: Animation.Infinite
            running: root.visible && root.width > 0
        }
    }
}
