import QtQuick
import qs.components
import qs.utils

// Satu kotak bento lockscreen. Posisi dari sel grid induk (cellW, cellH, gap): col, row, colSpan, rowSpan.
// Muncul bergiliran sesuai order, lalu keluar lebih cepat saat leaving (password benar).
StyledRect {
    id: root

    property int col: 0
    property int row: 0
    property int colSpan: 1
    property int rowSpan: 1
    property int order: 0
    property bool leaving: false
    property int pad: Appearance.padding.large + 2
    // 0 = tersembunyi, 1 = tampil (pegas sedikit melewati 1)
    property real t: 0
    default property alias content: body.data

    x: col * (parent.cellW + parent.gap)
    y: row * (parent.cellH + parent.gap)
    width: colSpan * parent.cellW + (colSpan - 1) * parent.gap
    height: rowSpan * parent.cellH + (rowSpan - 1) * parent.gap
    radius: Appearance.radius.large
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.82)
    opacity: Math.min(1, t)
    scale: 0.9 + 0.1 * t

    transform: Translate {
        y: (1 - root.t) * 40
    }

    onLeavingChanged: {
        if (leaving) {
            enter.stop();
            leave.start();
        }
    }

    Item {
        id: body

        anchors.fill: parent
        anchors.margins: root.pad
    }

    SequentialAnimation {
        id: enter

        running: true

        PauseAnimation {
            duration: 150 + root.order * 60
        }
        Anim {
            target: root
            property: "t"
            to: 1
            duration: Appearance.anim.durations.expressiveDefault
            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
        }
    }

    SequentialAnimation {
        id: leave

        PauseAnimation {
            duration: root.order * 25
        }
        Anim {
            target: root
            property: "t"
            to: 0
            duration: Appearance.anim.durations.normal - 50
            easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
        }
    }
}
