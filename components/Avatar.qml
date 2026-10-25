import QtQuick
import qs.utils

// Foto profil berbingkai amber dengan bayangan keras; tampil inisial kalau gambar tidak ada.
Item {
    id: root

    property string source: ""
    property string initial: ""
    property int size: 112

    implicitWidth: size + Appearance.shadowOffset.small
    implicitHeight: size + Appearance.shadowOffset.small

    Rectangle {
        x: Appearance.shadowOffset.small
        y: Appearance.shadowOffset.small
        width: root.size
        height: root.size
        color: Appearance.colors.shadow
        opacity: 0.6
    }

    Rectangle {
        width: root.size
        height: root.size
        color: Appearance.colors.surfaceHigh
        border.width: Appearance.border.normal
        border.color: Appearance.colors.primary

        Image {
            id: img

            anchors.fill: parent
            anchors.margins: Appearance.border.normal
            source: root.source
            fillMode: Image.PreserveAspectCrop
            smooth: !Config.pixelArt
            sourceSize: Config.pixelArt ? Qt.size(32, 32) : Qt.size(root.size * 2, root.size * 2)
            asynchronous: true
            visible: status === Image.Ready
        }

        StyledText {
            anchors.centerIn: parent
            visible: !img.visible
            text: root.initial
            color: Appearance.colors.primary
            font.pixelSize: root.size / 2
            font.bold: true
        }
    }
}
