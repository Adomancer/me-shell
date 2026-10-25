import QtQuick
import qs.utils

// Slider bersegmen ala meter VU. Klik, drag, atau scroll untuk mengubah.
Item {
    id: root

    property real value: 0
    property string label: ""
    property int segments: 20
    property bool showValue: true

    signal moved(real value)

    implicitWidth: 260
    implicitHeight: 18

    StyledText {
        id: lbl

        visible: root.label !== ""
        width: visible ? 40 : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    StyledText {
        id: pct

        visible: root.showValue
        width: visible ? 44 : 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(root.value * 100)}%`
    }

    Item {
        id: track

        readonly property int gap: 2

        anchors.left: lbl.right
        anchors.right: pct.left
        anchors.leftMargin: lbl.visible ? Appearance.spacing.normal : 0
        anchors.rightMargin: pct.visible ? Appearance.spacing.normal : 0
        height: parent.height

        Row {
            spacing: track.gap

            Repeater {
                model: root.segments

                Rectangle {
                    required property int index

                    width: (track.width - track.gap * (root.segments - 1)) / root.segments
                    height: track.height
                    color: index < Math.round(root.value * root.segments) ? Appearance.colors.primary : Appearance.colors.surfaceHigh

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.anim.duration.fast
                        }
                    }
                }
            }
        }

        MouseArea {
            function update(x: real): void {
                root.moved(Math.max(0, Math.min(1, x / width)));
            }

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => update(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    update(mouse.x);
            }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
