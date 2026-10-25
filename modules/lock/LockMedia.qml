import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

Card {
    id: root

    readonly property var player: Media.active

    title: "now playing"
    note: player?.identity ?? ""

    RowLayout {
        Layout.fillWidth: true
        visible: root.player !== null
        spacing: Appearance.spacing.large

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 64
            implicitHeight: 64
            color: Appearance.colors.surfaceHigh
            border.width: Appearance.border.thin
            border.color: Appearance.colors.outline

            Image {
                anchors.fill: parent
                anchors.margins: Appearance.border.thin
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                smooth: !Config.pixelArt
                sourceSize: Config.pixelArt ? Qt.size(32, 32) : Qt.size(128, 128)
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                color: Appearance.colors.textDim
                elide: Text.ElideRight
            }

            SegmentSlider {
                Layout.fillWidth: true
                visible: (root.player?.length ?? 0) > 0
                implicitHeight: 6
                segments: 24
                showValue: false
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            }

            Row {
                spacing: Appearance.spacing.small

                RetroButton {
                    text: "|<"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                RetroButton {
                    text: Media.playing ? "||" : ">"
                    active: true
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                RetroButton {
                    text: ">|"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }
        }
    }

    StyledText {
        visible: root.player === null
        text: "-- TIDAK ADA MEDIA --"
        color: Appearance.colors.textDim
    }
}
