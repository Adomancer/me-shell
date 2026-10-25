import QtQuick
import qs.utils

// NumberAnimation dengan kurva Material 3. Ganti easing.bezierCurve untuk gerak lain.
NumberAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
