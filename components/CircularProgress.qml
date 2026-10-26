import QtQuick
import qs.utils

// Cincin progres dot-matrix: titik-titik di busur 270°, yang menyala mengikuti nilai. Nilai tampil
// dianimasikan, jadi titik menyala berurutan. Angka dot-matrix di tengah.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property string label: ""
    property int size: 88
    property int thickness: 8
    property color color: Appearance.colors.primary
    property real shown: Math.max(0, Math.min(1, value))
    readonly property real r: (size - thickness) / 2
    readonly property int dots: Math.max(12, Math.round(Math.PI * 1.5 * r / (thickness * 1.9)))
    readonly property int lit: Math.round(shown * dots)

    implicitWidth: size
    implicitHeight: size

    Behavior on shown {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Repeater {
        model: root.dots

        Rectangle {
            required property int index
            // Mulai dari kiri bawah (135°), celah di bawah ala pengukur
            readonly property real angle: (135 + 270 * index / (root.dots - 1)) * Math.PI / 180

            x: root.size / 2 + root.r * Math.cos(angle) - width / 2
            y: root.size / 2 + root.r * Math.sin(angle) - height / 2
            width: root.thickness * 0.75
            height: width
            radius: width / 2
            color: index < root.lit ? root.color : Appearance.colors.hairline

            Behavior on color {
                CAnim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        DisplayText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.value * 100)
            font.pixelSize: Math.round(root.size * 0.28)
        }

        Caption {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label !== ""
            text: root.label
        }
    }
}
