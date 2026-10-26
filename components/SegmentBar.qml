import QtQuick
import qs.utils

// Bar bersegmen ala Nothing/TE: deretan garis tipis, yang menyala = value × jumlah segmen.
// Saat nilai berubah, segmen menyala/padam bergelombang mulai dari yang terdekat ke nilai lama.
Item {
    id: root

    property real value: 0
    property bool vertical: false
    property int segments: 24
    // Tebal satu segmen searah bar
    property real thickness: 3
    // true selama diseret: tanpa gelombang supaya tidak terasa telat
    property bool instant: false
    property color onColor: Appearance.colors.primary
    property color offColor: Appearance.colors.hairline
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)
    readonly property real step: ((vertical ? height : width) - thickness) / Math.max(1, segments - 1)

    Repeater {
        model: root.segments

        Rectangle {
            id: seg

            required property int index
            readonly property bool on: index < root.lit

            x: root.vertical ? 0 : index * root.step
            y: root.vertical ? root.height - root.thickness - index * root.step : 0
            width: root.vertical ? root.width : root.thickness
            height: root.vertical ? root.thickness : root.height
            radius: root.thickness / 2
            color: on ? root.onColor : root.offColor

            Behavior on color {
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.instant ? 0 : Math.abs(seg.index - root.lit) * 10
                    }
                    CAnim {
                        duration: Appearance.anim.durations.small / 2
                    }
                }
            }
        }
    }
}
