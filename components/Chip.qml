import QtQuick
import qs.utils

// Chip kecil berisi ikon + teks, untuk info singkat (uptime, jaringan)
StyledRect {
    id: root

    property string icon: ""
    property string text: ""

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: 26
    radius: Appearance.radius.small - 2
    color: Appearance.colors.surfaceContainerHigh
    border.width: Appearance.border.thin
    border.color: Appearance.colors.outlineVariant

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 4

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Appearance.font.size.larger
            color: Appearance.colors.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: Appearance.font.size.small
        }
    }
}
