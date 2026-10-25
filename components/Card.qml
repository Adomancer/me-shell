import QtQuick
import QtQuick.Layouts
import qs.utils

// Kartu Material 3: latar container, sudut bulat, judul kecil ber-ikon (opsional).
// Isi disusun vertikal; anak pakai Layout.fillWidth.
StyledRect {
    id: root

    property string title: ""
    property string icon: ""
    property string note: ""
    property int pad: Appearance.padding.normal + 2
    default property alias content: body.data

    implicitWidth: col.implicitWidth + pad * 2
    implicitHeight: col.implicitHeight + pad * 2
    radius: Appearance.radius.normal
    color: Appearance.colors.surfaceContainer

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== ""
            spacing: Appearance.spacing.small

            MaterialIcon {
                visible: root.icon !== ""
                text: root.icon
                font.pixelSize: Appearance.font.size.larger
                color: Appearance.colors.primary
            }

            StyledText {
                text: root.title
                color: Appearance.colors.primary
                font.weight: Font.Medium
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.maximumWidth: 180
                text: root.note
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: Appearance.spacing.small
        }
    }
}
