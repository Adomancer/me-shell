import QtQuick
import qs.components
import qs.utils

// Kolom teks; disimpan saat Enter atau fokus pindah.
StyledRect {
    id: root

    property string value: ""
    property string placeholder: ""

    signal committed(string value)

    implicitWidth: 240
    implicitHeight: 28
    color: Appearance.colors.background
    border.width: Appearance.border.thin
    border.color: input.activeFocus ? Appearance.colors.primary : Appearance.colors.outline

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.normal
        anchors.rightMargin: Appearance.spacing.normal
        verticalAlignment: TextInput.AlignVCenter
        text: root.value
        color: Appearance.colors.text
        font.family: Appearance.font.family.mono
        font.pixelSize: Appearance.font.size.normal
        selectByMouse: true
        selectionColor: Appearance.colors.primary
        selectedTextColor: Appearance.colors.primaryText
        clip: true
        onEditingFinished: root.committed(text)
        cursorDelegate: Rectangle {
            width: 8
            color: Appearance.colors.primary
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacing.normal
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Appearance.colors.textDim
    }
}
