import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Volume, pilihan perangkat output/input, dan mixer per aplikasi.
ColumnLayout {
    id: root

    component SectionLabel: Caption {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        Layout.bottomMargin: 2
    }

    readonly property int pageWidth: 340

    spacing: 2

    PopoutHeader {
        icon: Audio.muted ? "volume_off" : "volume_up"
        title: "Suara"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.muted ? "volume_off" : "volume_up"
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        StyledText {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(Audio.volume * 100)
            font.family: Appearance.font.family.mono
            color: Appearance.colors.textDim
        }

        IconButton {
            icon: Audio.micMuted ? "mic_off" : "mic"
            type: "tonal"
            toggled: !Audio.micMuted
            onClicked: Audio.toggleMic()
        }
    }

    SectionLabel {
        text: "Output"
    }

    Repeater {
        model: Audio.sinks

        ListRow {
            required property PwNode modelData

            icon: modelData === Audio.sink ? "radio_button_checked" : "radio_button_unchecked"
            title: Audio.nameOf(modelData)
            active: modelData === Audio.sink
            onClicked: Audio.setSink(modelData)
        }
    }

    SectionLabel {
        visible: Audio.sources.length > 0
        text: "Input"
    }

    Repeater {
        model: Audio.sources

        ListRow {
            required property PwNode modelData

            icon: modelData === Audio.source ? "radio_button_checked" : "radio_button_unchecked"
            title: Audio.nameOf(modelData)
            active: modelData === Audio.source
            onClicked: Audio.setSource(modelData)
        }
    }

    SectionLabel {
        visible: Audio.streams.length > 0
        text: "Aplikasi"
    }

    Repeater {
        model: Audio.streams

        RowLayout {
            id: stream

            required property PwNode modelData

            Layout.fillWidth: true
            Layout.leftMargin: Appearance.padding.small
            spacing: Appearance.spacing.normal

            IconImage {
                implicitSize: 24
                source: Quickshell.iconPath(stream.modelData.properties["application.icon-name"] || "audio-x-generic", "audio-x-generic")
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: Audio.nameOf(stream.modelData)
                    font.pixelSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }

                StyledSlider {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    value: stream.modelData.audio?.muted ? 0 : (stream.modelData.audio?.volume ?? 0)
                    onMoved: v => Audio.setNodeVolume(stream.modelData, v)
                }
            }
        }
    }
}
