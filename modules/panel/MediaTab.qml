import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tab Media tanpa kotak: cover besar, info lagu, visualizer cava dot-matrix, progress bersegmen yang bisa
// digeser, dan kontrol.
Item {
    id: root

    readonly property var player: Media.active
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Appearance.spacing.normal
        spacing: Appearance.spacing.huge + 12

        // Cover
        StyledClippingRect {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 320
            implicitHeight: 320
            radius: Appearance.radius.large
            color: Appearance.colors.surfaceContainerHigh
            scale: Media.playing ? 1 : 0.92

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefault
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(600, 600)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !art.visible
                text: "album"
                font.pixelSize: 120
                color: Appearance.colors.outline
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Tidak ada media"
                font.pixelSize: Appearance.font.size.extraLarge
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || root.player.identity) : "Putar lagu di aplikasi mana saja"
                color: Appearance.colors.primary
                font.pixelSize: Appearance.font.size.larger
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                color: Appearance.colors.textDim
                elide: Text.ElideRight
            }

            // Visualizer cava dot-matrix
            Item {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: 90

                DotColumns {
                    anchors.fill: parent
                    columns: Cava.bars
                    rows: 9
                    values: Media.playing ? Cava.values : []
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: !Cava.available
                    text: "Install cava untuk visualizer"
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                }
            }

            // Progress
            Item {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: 18
                visible: (root.player?.length ?? 0) > 0

                SegmentBar {
                    anchors.fill: parent
                    segments: 56
                    thickness: 3
                    instant: seek.pressed
                    value: seek.pressed ? seek.live : root.progress
                }

                MouseArea {
                    id: seek

                    property real live: 0

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: event => live = Math.max(0, Math.min(1, event.x / width))
                    onPositionChanged: event => {
                        if (pressed)
                            live = Math.max(0, Math.min(1, event.x / width));
                    }
                    onReleased: {
                        if (root.player?.canSeek)
                            root.player.position = live * root.player.length;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: (root.player?.length ?? 0) > 0

                StyledText {
                    text: root.fmt(root.player?.position ?? 0)
                    color: Appearance.colors.textDim
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.fmt(root.player?.length ?? 0)
                    color: Appearance.colors.textDim
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                IconButton {
                    icon: "skip_previous"
                    size: Appearance.font.size.extraLarge
                    disabled: !(root.player?.canGoPrevious ?? false)
                    onClicked: root.player.previous()
                }

                IconButton {
                    icon: Media.playing ? "pause" : "play_arrow"
                    type: "filled"
                    toggled: true
                    size: 36
                    padding: Appearance.padding.normal + 2
                    disabled: !(root.player?.canTogglePlaying ?? false)
                    onClicked: root.player.togglePlaying()
                }

                IconButton {
                    icon: "skip_next"
                    size: Appearance.font.size.extraLarge
                    disabled: !(root.player?.canGoNext ?? false)
                    onClicked: root.player.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                // Player yang terdeteksi
                Repeater {
                    model: Media.players

                    Chip {
                        required property var modelData

                        icon: modelData === root.player ? "graphic_eq" : "music_note"
                        text: modelData.identity
                        color: modelData === root.player ? Appearance.colors.surfaceContainerHigh : "transparent"
                    }
                }
            }
        }
    }
}
