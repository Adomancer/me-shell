import QtQuick
import qs.utils

// Meter vertikal bersegmen ala VU meter; segmen paling atas merah.
Column {
    id: root

    property real value: 0
    property string label: ""
    property int segments: 14
    property int hot: 3
    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * segments)

    spacing: Appearance.spacing.small

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        Repeater {
            model: root.segments

            Rectangle {
                required property int index
                readonly property int level: root.segments - 1 - index

                width: 16
                height: 6
                color: level < root.filled ? (level >= root.segments - root.hot ? Appearance.colors.error : Appearance.colors.primary) : Appearance.colors.surfaceHigh

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.anim.duration.fast
                    }
                }
            }
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }
}
