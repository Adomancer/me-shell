import QtQuick
import qs.utils

// Foto profil bulat; tampil inisial kalau gambar tidak ada.
StyledClippingRect {
    id: root

    property string source: ""
    property string initial: ""
    property int size: 112

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Appearance.colors.primaryContainer

    Image {
        id: img

        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        visible: status === Image.Ready
    }

    StyledText {
        anchors.centerIn: parent
        visible: !img.visible
        text: root.initial
        color: Appearance.colors.primaryContainerText
        font.pixelSize: root.size * 0.45
        font.weight: Font.Medium
    }
}
