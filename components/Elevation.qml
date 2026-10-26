import QtQuick
import QtQuick.Effects
import qs.utils

// Bayangan lembut dan tipis. Taruh di belakang item dengan anchors.fill dan radius yang sama.
RectangularShadow {
    property int level: 1
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Appearance.alpha(Appearance.colors.shadow, 0.35)
    blur: Math.pow(dp * 5, 0.7)
    spread: -dp * 0.3
    offset.y: dp / 2

    Behavior on dp {
        Anim {}
    }
}
