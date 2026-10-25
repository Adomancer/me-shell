import QtQuick
import qs.components
import qs.services
import qs.utils

Reveal {
    id: root

    readonly property bool isVolume: OsdState.kind === "volume"
    readonly property real value: isVolume ? (Audio.muted ? 0 : Audio.volume) : Brightness.value

    edge: "bottom"

    RetroFrame {
        Row {
            spacing: Appearance.spacing.large

            StyledText {
                text: root.isVolume ? "VOL" : "LCD"
                color: Appearance.colors.textDim
                font.bold: true
            }

            BlockBar {
                value: root.value
                segments: 20
            }

            StyledText {
                width: 40
                horizontalAlignment: Text.AlignRight
                text: root.isVolume && Audio.muted ? "MUTE" : `${Math.round(root.value * 100)}%`
            }
        }
    }
}
