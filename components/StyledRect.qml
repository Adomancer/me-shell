import QtQuick
import qs.utils

Rectangle {
    color: "transparent"
    radius: Appearance.radius.small

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.duration.normal
            easing.type: Appearance.anim.easing.standard
        }
    }
}
