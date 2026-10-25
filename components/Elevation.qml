import QtQuick
import QtQuick.Effects
import qs.utils

// Bayangan lembut Material 3. Taruh di belakang item dengan anchors.fill dan radius yang sama.
RectangularShadow {
    property int level: 1
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Appearance.alpha(Appearance.colors.shadow, 0.6)
    blur: Math.pow(dp * 5, 0.7)
    spread: -dp * 0.3 + Math.pow(dp * 0.1, 2)
    offset.y: dp / 2

    Behavior on dp {
        Anim {}
    }
}
