import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Satu baris setting: judul + penjelasan di kiri, kontrol di kanan.
Item {
    id: root

    property string label: ""
    property string description: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(texts.implicitHeight, slot.childrenRect.height) + Appearance.spacing.large * 2

    ColumnLayout {
        id: texts

        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: Appearance.spacing.huge
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: root.label
            font.bold: true
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.description
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    // Garis putus-putus di bawah
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 3
        clip: true

        Repeater {
            model: Math.ceil(root.width / 6)

            Rectangle {
                width: 3
                height: 1
                color: Appearance.colors.outline
            }
        }
    }
}
