import QtQuick
import qs.utils

// Bar teks: █████░░░░░
StyledText {
    id: root

    property real value: 0
    // Jumlah segmen minimal; dengan Layout.fillWidth bar memanjang mengisi lebar
    property int segments: 16
    readonly property int count: Math.max(segments, Math.floor(width / cell.advanceWidth))
    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * count)

    text: "█".repeat(filled) + "░".repeat(count - filled)
    color: Appearance.colors.primary

    TextMetrics {
        id: cell

        font: root.font
        text: "█"
    }
}
