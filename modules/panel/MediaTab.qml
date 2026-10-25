import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Kaset besar, judul berjalan, dan equalizer dari cava.
RowLayout {
    id: root

    readonly property var player: Media.active

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    spacing: Appearance.spacing.huge

    Cassette {
        Layout.alignment: Qt.AlignTop
        big: true
        label: root.player ? `side a · ${root.player.trackTitle}` : "no tape"
        playing: Media.playing
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: Appearance.spacing.normal

        Marquee {
            Layout.fillWidth: true
            text: root.player ? [root.player.trackTitle, root.player.trackArtist, root.player.trackAlbum].filter(s => s).join("  ///  ").toUpperCase() : "-- TIDAK ADA MEDIA --"
        }

        // Equalizer, tinggi batang dibulatkan ke 12 langkah
        Item {
            Layout.fillWidth: true
            implicitHeight: 96

            Row {
                anchors.fill: parent
                spacing: 3

                Repeater {
                    model: Cava.bars

                    Item {
                        id: eqBar

                        required property int index
                        readonly property real level: Math.round((Cava.values[index] ?? 0) * 12) / 12

                        width: (parent.width - 3 * (Cava.bars - 1)) / Cava.bars
                        height: parent.height

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, eqBar.level * eqBar.height)
                            color: eqBar.index % 3 === 2 ? Appearance.colors.textDim : Appearance.colors.primary
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: !Cava.available
                text: "install cava untuk visualizer"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.player !== null
            spacing: Appearance.spacing.normal

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                color: Appearance.colors.surfaceHigh
                border.width: Appearance.border.thin
                border.color: Appearance.colors.outline

                Image {
                    anchors.fill: parent
                    anchors.margins: Appearance.border.thin
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: !Config.pixelArt
                    sourceSize: Config.pixelArt ? Qt.size(24, 24) : Qt.size(80, 80)
                    asynchronous: true
                }
            }

            SegmentSlider {
                Layout.fillWidth: true
                implicitHeight: 8
                segments: 32
                showValue: false
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                onMoved: v => {
                    if (root.player?.canSeek)
                        root.player.position = v * root.player.length;
                }
            }

            StyledText {
                text: `${root.fmt(root.player?.position ?? 0)} / ${root.fmt(root.player?.length ?? 0)}`
                font.pixelSize: Appearance.font.size.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
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

            Item {
                Layout.fillWidth: true
            }

            // Player yang terdeteksi
            Repeater {
                model: Media.players

                StyledRect {
                    required property var modelData
                    readonly property bool isActive: modelData === root.player

                    implicitWidth: chip.implicitWidth + Appearance.spacing.normal * 2
                    implicitHeight: chip.implicitHeight + 4
                    border.width: Appearance.border.thin
                    border.color: isActive ? Appearance.colors.primary : Appearance.colors.outline

                    StyledText {
                        id: chip

                        anchors.centerIn: parent
                        text: parent.modelData.identity.toLowerCase()
                        color: parent.isActive ? Appearance.colors.primary : Appearance.colors.text
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }
        }
    }
}
