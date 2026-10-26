import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tab Media tanpa kotak: cover besar, info lagu, lirik tersinkron atau visualizer cava dot-matrix, progress
// bersegmen yang bisa digeser, dan kontrol.
Item {
    id: root

    readonly property var player: Media.active
    // Tab sedang tampil; data cava dan lirik hanya diambil saat itu
    property bool live: false
    // Lirik menggantikan visualizer kalau ada; tombol di baris kontrol untuk beralih
    property bool preferLyrics: true
    readonly property bool showLyrics: preferLyrics && Lyrics.available

    onLiveChanged: Lyrics.users += live ? 1 : -1

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Appearance.spacing.normal
        spacing: Appearance.spacing.huge + 12

        // Cover
        CoverArt {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 320
            implicitHeight: 320
            source: root.player?.trackArtUrl ?? ""
            title: root.player?.trackTitle ?? ""
            progress: Media.progress
            scale: Media.playing ? 1 : 0.92

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefault
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
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
                    visible: !root.showLyrics
                    columns: Cava.bars
                    rows: 9
                    values: root.live && Media.playing && !root.showLyrics ? Cava.values : []
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: !Cava.available && !root.showLyrics
                    text: "Install cava untuk visualizer"
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                }

                // Lirik: baris aktif di tengah, lebih besar; daftar bergulir halus mengikuti lagu
                ListView {
                    id: lyrics

                    readonly property int rowHeight: 30

                    anchors.fill: parent
                    visible: root.showLyrics
                    clip: true
                    interactive: false
                    model: Lyrics.lines
                    currentIndex: Math.max(0, Lyrics.index)
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: (height - rowHeight) / 2
                    preferredHighlightEnd: (height + rowHeight) / 2
                    highlightMoveDuration: Appearance.anim.durations.normal

                    delegate: StyledText {
                        required property var modelData
                        required property int index
                        readonly property bool active: index === Lyrics.index

                        width: ListView.view.width
                        height: lyrics.rowHeight
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.text || "♪"
                        color: active ? Appearance.colors.text : Appearance.colors.outline
                        font.pixelSize: active ? Appearance.font.size.large : Appearance.font.size.normal
                        font.weight: active ? Font.Medium : Font.Normal
                        elide: Text.ElideRight

                        Behavior on font.pixelSize {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }
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
                    value: seek.pressed ? seek.live : Media.progress
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
                    text: Media.formatTime(Media.position)
                    color: Appearance.colors.textDim
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Media.formatTime(Media.length)
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

                // Lirik atau visualizer
                IconButton {
                    visible: Lyrics.available
                    icon: "lyrics"
                    toggled: root.preferLyrics
                    onClicked: root.preferLyrics = !root.preferLyrics
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
