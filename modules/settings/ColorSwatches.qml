import QtQuick
import qs.utils

// Kotak-kotak warna dari palet aktif
Row {
    spacing: Appearance.spacing.small

    Repeater {
        model: ["background", "surface", "surfaceHigh", "outline", "text", "textDim", "primary", "error"]

        Rectangle {
            required property string modelData

            width: 26
            height: 26
            color: Appearance.colors[modelData]
            border.width: Appearance.border.thin
            border.color: Appearance.colors.outline
        }
    }
}
