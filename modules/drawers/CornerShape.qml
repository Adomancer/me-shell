import QtQuick
import QtQuick.Shapes
import qs.components
import qs.utils

// Latar drawer di pojok kanan: menempel ke tepi horizontal (bar atau bingkai bawah) dan bingkai kanan.
// Saat tingginya 0, yang tersisa persis lengkungan pojok bingkai, jadi tidak ada bekas.
// Koordinat v diukur dari tepi horizontal ke dalam layar, lalu dicerminkan untuk pojok bawah.
ShapePath {
    id: root

    required property Item wrapper
    // "top" = pojok kanan atas (di bawah bar), "bottom" = pojok kanan bawah
    property string edge: "top"
    property real rounding: Appearance.frame.rounding

    readonly property bool bottom: edge === "bottom"
    readonly property real x0: wrapper.x
    readonly property real e: bottom ? wrapper.y + wrapper.height : wrapper.y
    readonly property real w: wrapper.width
    readonly property real h: wrapper.height
    readonly property real r: rounding
    readonly property real rd: Math.min(rounding, h / 2)
    readonly property int cw: bottom ? PathArc.Counterclockwise : PathArc.Clockwise
    readonly property int ccw: bottom ? PathArc.Clockwise : PathArc.Counterclockwise

    function py(v: real): real {
        return bottom ? e - v : e + v;
    }

    strokeWidth: -1
    fillColor: Appearance.colors.surface
    startX: x0 - r
    startY: e

    Behavior on fillColor {
        CAnim {}
    }

    PathArc {
        x: root.x0
        y: root.py(root.rd)
        radiusX: root.r
        radiusY: root.rd
        direction: root.cw
    }
    PathLine {
        x: root.x0
        y: root.py(root.h - root.rd)
    }
    PathArc {
        x: root.x0 + root.r
        y: root.py(root.h)
        radiusX: root.r
        radiusY: root.rd
        direction: root.ccw
    }
    PathLine {
        x: root.x0 + root.w - root.r
        y: root.py(root.h)
    }
    PathArc {
        x: root.x0 + root.w
        y: root.py(root.h + root.r)
        radiusX: root.r
        radiusY: root.r
        direction: root.cw
    }
    PathLine {
        x: root.x0 + root.w
        y: root.e
    }
    PathLine {
        x: root.startX
        y: root.startY
    }
}
