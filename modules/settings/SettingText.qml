import QtQuick
import qs.components
import qs.utils

// Kolom teks; disimpan saat Enter atau fokus pindah. Garis bawah menebal saat aktif.
StyledRect {
    id: root

    property string value: ""
    property string placeholder: ""

    signal committed(string value)

    implicitWidth: 260
    implicitHeight: 40
    topLeftRadius: Appearance.radius.small - 4
    topRightRadius: Appearance.radius.small - 4
    color: Appearance.colors.surfaceContainerHighest

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        verticalAlignment: TextInput.AlignVCenter
        text: root.value
        color: Appearance.colors.text
        font.family: Appearance.font.family.sans
        font.pixelSize: Appearance.font.size.normal
        selectByMouse: true
        selectionColor: Appearance.colors.primary
        selectedTextColor: Appearance.colors.primaryText
        clip: true
        onEditingFinished: root.committed(text)
        cursorDelegate: Rectangle {
            width: 2
            color: Appearance.colors.primary
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Appearance.colors.textDim
    }

    StyledRect {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: input.activeFocus ? parent.width : parent.width - 2
        height: input.activeFocus ? 2 : 1
        color: input.activeFocus ? Appearance.colors.primary : Appearance.colors.outline

        Behavior on height {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }
}
