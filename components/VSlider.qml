import QtQuick
import qs.utils

// Slider vertikal Material 3 (isi dari bawah) dengan ikon di dasar track.
Item {
    id: root

    property real value: 0
    property string icon: ""
    readonly property real shown: drag.pressed ? drag.live : value

    signal moved(real value)

    implicitWidth: 44
    implicitHeight: 180

    StyledRect {
        anchors.fill: parent
        radius: Appearance.radius.small
        color: Appearance.colors.secondaryContainer
        border.width: Appearance.border.thin
        border.color: Appearance.colors.outlineVariant

        StyledRect {
            id: fill

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(parent.width, root.shown * parent.height)
            radius: parent.radius
            color: Appearance.colors.primary

            Behavior on height {
                enabled: !drag.pressed

                Anim {
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }
        }

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (parent.width - height) / 2
            text: root.icon
            fill: 1
            color: Appearance.colors.primaryText
        }
    }

    MouseArea {
        id: drag

        property real live: 0

        function update(y: real): void {
            live = Math.max(0, Math.min(1, 1 - y / height));
            root.moved(live);
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => update(event.y)
        onPositionChanged: event => update(event.y)
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
