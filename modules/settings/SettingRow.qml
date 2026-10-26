import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Satu baris setting di dalam grup: judul + penjelasan di kiri, kontrol di kanan.
// Tanpa kotak: baris dipisah garis tipis di bawahnya.
StyledRect {
    id: root

    property string label: ""
    property string description: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(texts.implicitHeight, slot.childrenRect.height) + Appearance.padding.normal * 2 + 4

    Divider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    ColumnLayout {
        id: texts

        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.large
        anchors.right: slot.left
        anchors.rightMargin: Appearance.spacing.huge
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: root.label
            font.pixelSize: Appearance.font.size.larger
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.description
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.smaller
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot

        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.large
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
