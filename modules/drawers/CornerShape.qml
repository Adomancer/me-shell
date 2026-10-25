import QtQuick
import QtQuick.Shapes
import qs.components
import qs.utils

// Latar drawer di pojok kanan atas (popup notifikasi): menempel ke bar dan ke bingkai kanan.
// Saat tingginya 0, yang tersisa persis lengkungan pojok bingkai, jadi tidak ada bekas.
ShapePath {
    id: root

    required property Item wrapper
    property real rounding: Appearance.frame.rounding

    readonly property real x0: wrapper.x
    readonly property real y0: wrapper.y
    readonly property real w: wrapper.width
    readonly property real h: wrapper.height
    readonly property real r: rounding
    readonly property real rd: Math.min(rounding, h / 2)

    strokeWidth: -1
    fillColor: Appearance.colors.surface
    startX: x0 - r
    startY: y0

    Behavior on fillColor {
        CAnim {}
    }

    PathArc {
        x: root.x0
        y: root.y0 + root.rd
        radiusX: root.r
        radiusY: root.rd
        direction: PathArc.Clockwise
    }
    PathLine {
        x: root.x0
        y: root.y0 + root.h - root.rd
    }
    PathArc {
        x: root.x0 + root.r
        y: root.y0 + root.h
        radiusX: root.r
        radiusY: root.rd
        direction: PathArc.Counterclockwise
    }
    PathLine {
        x: root.x0 + root.w - root.r
        y: root.y0 + root.h
    }
    PathArc {
        x: root.x0 + root.w
        y: root.y0 + root.h + root.r
        radiusX: root.r
        radiusY: root.r
        direction: PathArc.Clockwise
    }
    PathLine {
        x: root.x0 + root.w
        y: root.y0
    }
    PathLine {
        x: root.startX
        y: root.startY
    }
}
