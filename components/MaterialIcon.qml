import QtQuick
import qs.utils

// Ikon dari font Material Symbols Rounded. text = nama ikon, misalnya "volume_up".
StyledText {
    // 0 = garis, 1 = penuh; bisa dianimasikan
    property real fill: 0
    property int grade: -25

    font.family: Appearance.font.family.icon
    font.pixelSize: Appearance.font.size.large
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })

    Behavior on fill {
        Anim {
            duration: Appearance.anim.durations.small
        }
    }
}
