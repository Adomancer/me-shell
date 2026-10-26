import QtQuick
import qs.utils

// Tombol pill dengan label (dan ikon opsional). type: "filled", "tonal", "text".
StyledRect {
    id: root

    property string text: ""
    property string icon: ""
    property string type: "tonal"
    property bool disabled: false

    readonly property color ink: type === "filled" ? Appearance.colors.primaryText : type === "tonal" ? Appearance.colors.secondaryContainerText : Appearance.colors.primary

    signal clicked

    implicitWidth: row.implicitWidth + Appearance.padding.large * 2
    implicitHeight: 36
    radius: Appearance.radius.small
    border.width: type === "text" ? 0 : Appearance.border.thin
    border.color: type === "filled" ? Appearance.colors.primary : Appearance.colors.outlineVariant
    color: type === "filled" ? Appearance.colors.primary : type === "tonal" ? Appearance.colors.secondaryContainer : "transparent"
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

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.ink
            font.weight: Font.Medium
        }
    }

    StateLayer {
        disabled: root.disabled
        color: root.ink
        onClicked: root.clicked()
    }
}
