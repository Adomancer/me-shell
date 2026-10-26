import QtQuick
import qs.utils

// Switch Material 3: pegangan membesar dan bergeser saat aktif, ikon centang di dalamnya.
Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 32

    StyledRect {
        anchors.fill: parent
        radius: Appearance.radius.small
        color: root.checked ? Appearance.colors.primary : Appearance.colors.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Appearance.colors.outline

        StyledRect {
            id: handle

            property real size: mouse.pressed ? 28 : root.checked ? 24 : 16

            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - size - (parent.height - size) / 2 : (parent.height - size) / 2
            width: size
            height: size
            radius: 2
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

            MaterialIcon {
                anchors.centerIn: parent
                text: "check"
                font.pixelSize: 16
                color: Appearance.colors.primary
                opacity: root.checked ? 1 : 0
                scale: root.checked ? 1 : 0.4

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }
                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
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
