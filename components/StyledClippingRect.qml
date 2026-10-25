import Quickshell.Widgets
import QtQuick

// Rectangle yang memotong anaknya mengikuti sudut bulat
ClippingRectangle {
    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
