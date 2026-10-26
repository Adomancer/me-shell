import QtQuick
import qs.utils

// Slider bersegmen: ikon (atau label mono) di kiri, deretan segmen, angka opsional di kanan.
Item {
    id: root

    property real value: 0
    property string icon: ""
    // Label mono pendek pengganti ikon, misalnya "VOL"
    property string label: ""
    property bool showValue: false
    // Selama digeser, tampilan mengikuti mouse dulu
    readonly property real shown: drag.pressed ? drag.live : value

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 32

    MaterialIcon {
        id: lead

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== "" && root.label === ""
        text: root.icon
        color: Appearance.colors.textDim
    }

    Caption {
        id: leadLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.label !== ""
        width: 36
        text: root.label
        color: Appearance.colors.textDim
    }

    StyledText {
        id: valueText

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showValue
        width: 32
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.shown * 100)
        font.family: Appearance.font.family.mono
        font.pixelSize: Appearance.font.size.smaller
    }

    SegmentBar {
        id: bar

        anchors.left: leadLabel.visible ? leadLabel.right : lead.visible ? lead.right : parent.left
        anchors.leftMargin: leadLabel.visible || lead.visible ? Appearance.spacing.normal : 0
        anchors.right: valueText.visible ? valueText.left : parent.right
        anchors.rightMargin: valueText.visible ? Appearance.spacing.small : 0
        anchors.verticalCenter: parent.verticalCenter
        height: Math.min(18, root.height - 8)
        segments: Math.max(8, Math.round(width / 7))
        value: root.shown
        instant: drag.pressed
    }

    MouseArea {
        id: drag

        property real live: 0

        function update(x: real): void {
            live = Math.max(0, Math.min(1, (x - bar.x) / bar.width));
            root.moved(live);
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => update(event.x)
        onPositionChanged: event => update(event.x)
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
