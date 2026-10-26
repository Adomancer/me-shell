import QtQuick
import qs.utils

// Switch pil kecil: mati = cincin tipis + titik redup di kiri, nyala = pil aksen + titik gelap di kanan.
Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 42
    implicitHeight: 24

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Appearance.colors.primary : "transparent"
        border.width: root.checked ? 0 : 1
        border.color: Appearance.colors.outline

        StyledRect {
            id: dot

            property real size: mouse.pressed ? 16 : root.checked ? 14 : 10

            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - size - (parent.height - size) / 2 : (parent.height - size) / 2
            width: size
            height: size
            radius: size / 2
            color: root.checked ? Appearance.colors.primaryText : Appearance.colors.outline

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveFast
                }
            }
            Behavior on size {
                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveFast
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
