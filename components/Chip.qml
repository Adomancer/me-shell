import QtQuick
import qs.utils

// Info singkat tanpa kotak: ikon tipis + teks mono kecil (uptime, jaringan). color bisa diisi untuk menyorot.
StyledRect {
    id: root

    property string icon: ""
    property string text: ""

    implicitWidth: row.implicitWidth + (color.a > 0 ? Appearance.padding.normal * 2 : 0)
    implicitHeight: 24
    radius: height / 2

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 4

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Appearance.font.size.larger
            color: Appearance.colors.textDim
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: Appearance.colors.textDim
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.small
        }
    }
}
