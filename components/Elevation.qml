import QtQuick
import QtQuick.Effects
import qs.utils

// Bayangan keras ala retro: tanpa blur, bergeser ke kanan bawah sesuai level.
// Taruh di belakang item dengan anchors.fill dan radius yang sama.
RectangularShadow {
    property int level: 1
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Appearance.alpha(Appearance.colors.shadow, 0.6)
    blur: 0
    offset.x: dp / 2
    offset.y: dp / 2

    Behavior on dp {
        Anim {}
    }
}
