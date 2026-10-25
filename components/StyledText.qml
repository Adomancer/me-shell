import QtQuick
import qs.utils

Text {
    color: Appearance.colors.text
    font.family: Appearance.font.family.sans
    font.pixelSize: Appearance.font.size.normal

    Behavior on color {
        CAnim {}
    }
}
