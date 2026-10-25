import QtQuick
import qs.utils

// Lapisan hover/tekan Material 3 dengan efek riak. Taruh sebagai anak terakhir item yang bisa diklik.
MouseArea {
    id: root

    property bool disabled: false
    property color color: Appearance.colors.text
    property real radius: parent?.radius ?? 0

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: event => {
        const d = (dx, dy) => dx * dx + dy * dy;
        ripple.x = event.x;
        ripple.y = event.y;
        rippleAnim.radius = Math.sqrt(Math.max(d(event.x, event.y), d(event.x, height - event.y), d(width - event.x, event.y), d(width - event.x, height - event.y)));
        rippleAnim.restart();
    }

    SequentialAnimation {
        id: rippleAnim

        property real radius

        PropertyAction {
            target: ripple
            property: "opacity"
            value: 0.12
        }
        Anim {
            target: ripple
            properties: "implicitWidth,implicitHeight"
            from: 0
            to: rippleAnim.radius * 2
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
        Anim {
            target: ripple
            property: "opacity"
            to: 0
        }
    }

    StyledClippingRect {
        anchors.fill: parent
        radius: root.radius
        color: Appearance.alpha(root.color, root.disabled ? 0 : root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0)

        Rectangle {
            id: ripple

            radius: Appearance.radius.full
            color: root.color
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }
}
