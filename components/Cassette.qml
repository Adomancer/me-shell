import QtQuick
import qs.utils

// Kaset dengan dua roda yang berputar saat `playing`.
Item {
    id: root

    property string label: ""
    property bool playing: false
    property bool big: false

    readonly property real reelSize: big ? 76 : 36
    readonly property real ring: big ? 10 : 5
    readonly property real winY: big ? 72 : 34

    implicitWidth: big ? 380 : 172
    implicitHeight: big ? 200 : 92

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.surfaceHigh
        border.width: Appearance.border.normal
        border.color: Appearance.colors.outline
        radius: Appearance.radius.normal
    }

    Rectangle {
        x: 8
        y: root.big ? 10 : 6
        width: root.width - 16
        height: root.big ? 28 : 18
        color: Appearance.colors.primary

        StyledText {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacing.normal
            anchors.rightMargin: Appearance.spacing.normal
            verticalAlignment: Text.AlignVCenter
            text: root.label.toUpperCase()
            color: Appearance.colors.primaryText
            font.pixelSize: root.big ? Appearance.font.size.normal : Appearance.font.size.small
            font.bold: true
            elide: Text.ElideRight
        }
    }

    // Jendela pita
    Rectangle {
        x: root.width * 0.22
        y: root.winY
        width: root.width * 0.56
        height: root.reelSize
        radius: height / 2
        color: Appearance.colors.background
        border.width: Appearance.border.normal
        border.color: Appearance.colors.outline
    }

    Repeater {
        model: 2

        Item {
            id: reel

            required property int index

            x: index === 0 ? root.width * 0.22 - root.ring : root.width * 0.78 - root.reelSize + root.ring
            y: root.winY
            width: root.reelSize
            height: root.reelSize

            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 2400
                loops: Animation.Infinite
                running: true
                paused: !root.playing
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: root.ring
                border.color: Appearance.colors.textDim
            }

            // Jari-jari roda supaya putarannya kelihatan
            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: root.reelSize - root.ring
                    height: root.big ? 4 : 2
                    rotation: index * 60
                    color: Appearance.colors.textDim
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: root.reelSize * 0.3
                height: width
                radius: width / 2
                color: Appearance.colors.surfaceHigh
                border.width: Appearance.border.thin
                border.color: Appearance.colors.textDim
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width * 0.4
        height: root.big ? 14 : 8
        color: "transparent"
        border.width: Appearance.border.thin
        border.color: Appearance.colors.outline
    }
}
