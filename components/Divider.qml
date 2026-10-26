import QtQuick
import QtQuick.Layouts
import qs.utils

// Garis pemisah tipis. Pengganti kotak: kelompokkan dengan jarak + garis ini, bukan fill + border.
Rectangle {
    property bool vertical: false

    Layout.fillWidth: !vertical
    Layout.fillHeight: vertical
    implicitWidth: vertical ? 1 : 0
    implicitHeight: vertical ? 0 : 1
    color: Appearance.colors.hairline
}
