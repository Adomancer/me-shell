import QtQuick
import qs.utils

// Cincin titik ala Nothing: titik di keliling lingkaran, yang menyala = value (mulai dari atas, searah
// jarum jam). spinning = berputar pelan, untuk status sibuk. Isi tengah ditaruh sebagai anak.
Item {
    id: root

    property real value: 0
    property int dots: 24
    property real dotSize: 4
    property int size: 72
    property bool spinning: false
    property color onColor: Appearance.colors.primary
    property color offColor: Appearance.colors.hairline
    readonly property real r: (size - dotSize) / 2
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * dots)

    implicitWidth: size
    implicitHeight: size

    Item {
        id: ring

        anchors.fill: parent

        Repeater {
            model: root.dots

            Rectangle {
                required property int index
                readonly property real angle: (-90 + 360 * index / root.dots) * Math.PI / 180
                readonly property bool on: index < root.lit

                x: root.size / 2 + root.r * Math.cos(angle) - width / 2
                y: root.size / 2 + root.r * Math.sin(angle) - height / 2
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: on ? root.onColor : root.offColor
                scale: on ? 1.25 : 1

                Behavior on color {
                    CAnim {
                        duration: Appearance.anim.durations.small
                    }
                }
            }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 1800
            loops: Animation.Infinite
            running: root.spinning
        }
    }
}
