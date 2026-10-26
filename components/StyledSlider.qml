import QtQuick
import qs.utils

// Slider Material 3: track tebal yang terisi, pegangan tipis, ikon opsional di dalam track.
Item {
    id: root

    property real value: 0
    property string icon: ""
    // Selama digeser, tampilan mengikuti mouse dulu
    readonly property real shown: drag.pressed ? drag.live : value

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 40

    StyledRect {
        anchors.fill: parent
        radius: Appearance.radius.small
        color: Appearance.colors.secondaryContainer
        border.width: Appearance.border.thin
        border.color: Appearance.colors.outlineVariant

        StyledRect {
            id: fill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(parent.height, root.shown * parent.width)
            radius: parent.radius
            color: Appearance.colors.primary

            Behavior on width {
                enabled: !drag.pressed

                Anim {
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }
        }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: (parent.height - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            fill: 1
            color: Appearance.colors.primaryText
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: fill.width - width - 6
        width: 4
        height: drag.pressed ? root.height - 4 : root.height - 16
        radius: 2
        color: Appearance.colors.primaryText
        opacity: 0.7

        Behavior on height {
            Anim {
                duration: Appearance.anim.durations.expressiveFast
                easing.bezierCurve: Appearance.anim.curves.expressiveFast
            }
        }
    }

    MouseArea {
        id: drag

        property real live: 0

        function update(x: real): void {
            live = Math.max(0, Math.min(1, x / width));
            root.moved(live);
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => update(event.x)
        onPositionChanged: event => update(event.x)
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
