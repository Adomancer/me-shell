import QtQuick
import qs.utils

// Tombol pil berlabel mono huruf besar (ikon opsional). type: "filled" (aksen), "tonal" (cincin), "text".
StyledRect {
    id: root

    property string text: ""
    property string icon: ""
    property string type: "tonal"
    property bool disabled: false

    readonly property color ink: type === "filled" ? Appearance.colors.primaryText : type === "tonal" ? Appearance.colors.text : Appearance.colors.primary

    signal clicked

    implicitWidth: row.implicitWidth + Appearance.padding.large * 2
    implicitHeight: 34
    radius: height / 2
    color: type === "filled" ? Appearance.colors.primary : "transparent"
    border.width: type === "tonal" ? 1 : 0
    border.color: Appearance.colors.hairline
    opacity: disabled ? 0.38 : 1

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Appearance.font.size.larger
            color: root.ink
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.ink
        }
    }

    StateLayer {
        disabled: root.disabled
        color: root.ink
        onClicked: root.clicked()
    }
}
