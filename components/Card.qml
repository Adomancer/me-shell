import QtQuick
import QtQuick.Layouts
import qs.utils

// Kartu berjudul: "TITLE ........ note". Isi disusun vertikal; anak pakai Layout.fillWidth.
StyledRect {
    id: root

    property string title: ""
    property string note: ""
    default property alias content: body.data
    readonly property int pad: Appearance.spacing.large

    implicitWidth: col.implicitWidth + pad * 2
    implicitHeight: col.implicitHeight + pad * 2
    color: Appearance.colors.background
    border.width: Appearance.border.thin
    border.color: Appearance.colors.outline

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== ""

            StyledText {
                text: root.title.toUpperCase()
                color: Appearance.colors.primary
                font.pixelSize: Appearance.font.size.small
                font.bold: true
                font.letterSpacing: 2
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: root.note
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
                Layout.maximumWidth: 180
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: 6
        }
    }
}
