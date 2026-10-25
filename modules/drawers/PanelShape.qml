import QtQuick
import QtQuick.Shapes
import qs.components
import qs.utils

// Latar drawer yang menempel di satu tepi bingkai. Di titik sambung ada sudut cekung,
// jadi drawer terlihat "tumbuh" dari bingkai. Koordinat dihitung di ruang tepi:
// u = sepanjang tepi, v = masuk ke dalam layar, lalu dipetakan ke x/y layar.
ShapePath {
    id: root

    required property Item wrapper
    // "top", "bottom", "left", "right"
    property string edge: "top"
    property real rounding: Appearance.frame.rounding

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real len: vertical ? wrapper.height : wrapper.width
    readonly property real depth: vertical ? wrapper.width : wrapper.height
    readonly property real r: rounding
    // Saat drawer masih tipis, lengkungan ikut memipih supaya tidak menonjol
    readonly property real rd: Math.min(rounding, depth / 2)
    readonly property real u0: vertical ? wrapper.y : wrapper.x
    readonly property real e: edge === "top" ? wrapper.y : edge === "bottom" ? wrapper.y + wrapper.height : edge === "left" ? wrapper.x : wrapper.x + wrapper.width
    readonly property real s: edge === "top" || edge === "left" ? 1 : -1
    // Pemetaan bottom/left adalah cermin, jadi arah busur dibalik
    readonly property bool mirrored: edge === "bottom" || edge === "left"
    readonly property int cw: mirrored ? PathArc.Counterclockwise : PathArc.Clockwise
    readonly property int ccw: mirrored ? PathArc.Clockwise : PathArc.Counterclockwise
    readonly property real rx: vertical ? rd : r
    readonly property real ry: vertical ? r : rd

    function px(u: real, v: real): real {
        return vertical ? e + s * v : u;
    }

    function py(u: real, v: real): real {
        return vertical ? u : e + s * v;
    }

    strokeWidth: -1
    fillColor: Appearance.colors.surface
    startX: px(u0 - r, 0)
    startY: py(u0 - r, 0)

    Behavior on fillColor {
        CAnim {}
    }

    PathArc {
        x: root.px(root.u0, root.rd)
        y: root.py(root.u0, root.rd)
        radiusX: root.rx
        radiusY: root.ry
        direction: root.cw
    }
    PathLine {
        x: root.px(root.u0, root.depth - root.rd)
        y: root.py(root.u0, root.depth - root.rd)
    }
    PathArc {
        x: root.px(root.u0 + root.r, root.depth)
        y: root.py(root.u0 + root.r, root.depth)
        radiusX: root.rx
        radiusY: root.ry
        direction: root.ccw
    }
    PathLine {
        x: root.px(root.u0 + root.len - root.r, root.depth)
        y: root.py(root.u0 + root.len - root.r, root.depth)
    }
    PathArc {
        x: root.px(root.u0 + root.len, root.depth - root.rd)
        y: root.py(root.u0 + root.len, root.depth - root.rd)
        radiusX: root.rx
        radiusY: root.ry
        direction: root.ccw
    }
    PathLine {
        x: root.px(root.u0 + root.len, root.rd)
        y: root.py(root.u0 + root.len, root.rd)
    }
    PathArc {
        x: root.px(root.u0 + root.len + root.r, 0)
        y: root.py(root.u0 + root.len + root.r, 0)
        radiusX: root.rx
        radiusY: root.ry
        direction: root.cw
    }
    PathLine {
        x: root.startX
        y: root.startY
    }
}
