import QtQuick
import QtQuick.Shapes
import qs.components
import qs.utils

// Bar + bingkai layar dalam satu bentuk: persegi layar dikurangi area kerja yang sudutnya bulat.
ShapePath {
    id: root

    required property real screenWidth
    required property real screenHeight
    required property real barHeight

    readonly property real t: Appearance.frame.thickness
    readonly property real r: Appearance.frame.rounding
    // Tanpa bingkai, sudut bawah area kerja menempel ke tepi layar
    readonly property real rb: Config.frameEnabled ? r : 0

    strokeWidth: -1
    fillColor: Appearance.colors.surface
    fillRule: ShapePath.OddEvenFill

    Behavior on fillColor {
        CAnim {}
    }

    PathRectangle {
        x: 0
        y: 0
        width: root.screenWidth
        height: root.screenHeight
    }
    PathRectangle {
        x: root.t
        y: root.barHeight
        width: root.screenWidth - root.t * 2
        height: root.screenHeight - root.barHeight - root.t
        topLeftRadius: root.r
        topRightRadius: root.r
        bottomLeftRadius: root.rb
        bottomRightRadius: root.rb
    }
}
