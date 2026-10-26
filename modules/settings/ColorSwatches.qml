import QtQuick
import qs.components
import qs.utils

// Lingkaran warna dari palet aktif
Row {
    spacing: -6

    Repeater {
        model: ["surfaceContainer", "secondaryContainer", "outline", "tertiary", "secondary", "primary"]

        StyledRect {
            required property string modelData

            width: 30
            height: 30
            radius: width / 2
            color: Appearance.colors[modelData]
            border.width: 2
            border.color: Appearance.colors.surfaceContainer
        }
    }
}
