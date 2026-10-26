import QtQuick
import qs.utils

// Tombol ikon bulat. type: "text" (tanpa latar), "tonal" (cincin tipis), "filled".
// toggled = aktif: lingkaran aksen penuh (untuk "text": ikon jadi warna aksen saja).
StyledRect {
    id: root

    property string icon
    property bool toggled: false
    property string type: "text"
    property int size: Appearance.font.size.large
    property int padding: Appearance.padding.small
    property bool disabled: false

    readonly property bool solid: toggled && type !== "text"
    readonly property color ink: solid ? Appearance.colors.primaryText : toggled ? Appearance.colors.primary : type === "text" ? Appearance.colors.textDim : Appearance.colors.text

    signal clicked

    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: label.implicitHeight + padding * 2
    radius: height / 2
    color: solid ? Appearance.colors.primary : "transparent"
    border.width: type === "tonal" && !solid ? 1 : 0
    border.color: Appearance.colors.hairline
    opacity: disabled ? 0.38 : 1

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        fill: root.toggled ? 1 : 0
        color: root.ink
    }

    StateLayer {
        disabled: root.disabled
        color: root.ink
        onClicked: root.clicked()
    }
}
