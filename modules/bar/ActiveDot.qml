import QtQuick
import qs.components
import qs.utils

// Penanda "terbuka" di bawah item bar: strip aksen kecil yang melar saat aktif.
// Taruh sebagai anak item bar; menempel di bawahnya.
Rectangle {
    property bool active: false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.bottom
    anchors.topMargin: 1
    width: active ? 14 : 4
    height: 3
    radius: 1.5
    color: Appearance.colors.primary
    opacity: active ? 1 : 0

    Behavior on width {
        Anim {
            duration: Appearance.anim.durations.expressiveFast
            easing.bezierCurve: Appearance.anim.curves.expressiveFast
        }
    }
    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.small
        }
    }
}
