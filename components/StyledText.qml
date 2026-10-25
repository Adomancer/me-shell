import QtQuick
import qs.utils

Text {
    color: Appearance.colors.text
    font.family: Appearance.font.family.mono
    font.pixelSize: Appearance.font.size.normal

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.duration.normal
            easing.type: Appearance.anim.easing.standard
        }
    }
}
