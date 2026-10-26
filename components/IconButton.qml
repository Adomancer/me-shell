import QtQuick
import qs.utils

// Tombol ikon bersudut kecil. type: "text" (tanpa latar), "tonal", "filled". toggled = aktif.
StyledRect {
    id: root

    property string icon
    property bool toggled: false
    property string type: "text"
    property int size: Appearance.font.size.large
    property int padding: Appearance.padding.small
    property bool disabled: false

    readonly property color activeColor: type === "filled" ? Appearance.colors.primary : Appearance.colors.secondaryContainer
    readonly property color activeText: type === "filled" ? Appearance.colors.primaryText : Appearance.colors.secondaryContainerText
    readonly property color idleColor: type === "text" ? "transparent" : Appearance.colors.surfaceContainerHigh

    signal clicked

    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: label.implicitHeight + padding * 2
    radius: Appearance.radius.small
    border.width: type === "text" ? 0 : Appearance.border.thin
    border.color: toggled ? activeColor : Appearance.colors.outlineVariant
    color: toggled ? activeColor : idleColor
    opacity: disabled ? 0.38 : 1

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        fill: root.toggled ? 1 : 0
        color: root.toggled ? root.activeText : Appearance.colors.textDim
    }

    StateLayer {
        disabled: root.disabled
        color: root.toggled ? root.activeText : Appearance.colors.text
        onClicked: root.clicked()
    }
}
