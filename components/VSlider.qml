import QtQuick
import qs.utils

// Slider vertikal bersegmen (isi dari bawah) dengan ikon di bawahnya.
Item {
    id: root

    property real value: 0
    property string icon: ""
    readonly property real shown: drag.pressed ? drag.live : value

    signal moved(real value)

    implicitWidth: 44
    implicitHeight: 180

    SegmentBar {
        id: bar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: icon.top
        anchors.bottomMargin: Appearance.spacing.normal
        width: 22
        vertical: true
        segments: Math.max(8, Math.round(height / 7))
        value: root.shown
        instant: drag.pressed
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: root.icon
        color: Appearance.colors.textDim
    }

    MouseArea {
        id: drag

        property real live: 0

        function update(y: real): void {
            live = Math.max(0, Math.min(1, 1 - (y - bar.y) / bar.height));
            root.moved(live);
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => update(event.y)
        onPositionChanged: event => update(event.y)
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
