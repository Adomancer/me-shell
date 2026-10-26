import QtQuick
import qs.utils

// Cover lagu. Tanpa cover tidak ada kotak abu-abu: hanya cincin titik (progres lagu) dengan huruf pertama
// judul dalam dot-matrix di tengahnya.
Item {
    id: root

    property string source
    property string title
    // 0..1
    property real progress: 0
    property real radius: Appearance.radius.large
    readonly property bool hasArt: art.status === Image.Ready
    readonly property real side: Math.min(width, height)

    StyledClippingRect {
        anchors.fill: parent
        visible: root.hasArt
        radius: root.radius
        color: "transparent"

        Image {
            id: art

            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(root.side * 2, root.side * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    DotRing {
        anchors.centerIn: parent
        visible: !root.hasArt
        size: Math.round(root.side * 0.86)
        dots: size > 160 ? 48 : size > 80 ? 32 : 20
        dotSize: size > 160 ? 5 : size > 80 ? 4 : 3
        value: root.progress

        DisplayText {
            anchors.centerIn: parent
            visible: root.title.trim() !== ""
            text: root.title.trim().charAt(0).toUpperCase()
            weight: 800
            font.pixelSize: Math.round(parent.size * 0.42)
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.title.trim() === ""
            text: "music_note"
            color: Appearance.colors.outline
            font.pixelSize: Math.round(parent.size * 0.36)
        }
    }
}
