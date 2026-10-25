import QtQuick
import qs.utils

// Bar teks: █████░░░░░
StyledText {
    property real value: 0
    property int segments: 16
    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * segments)

    text: "█".repeat(filled) + "░".repeat(segments - filled)
    color: Appearance.colors.primary
}
