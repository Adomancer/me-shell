import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Lagu yang diputar: cover, judul, progress yang bisa diklik, dan kontrol. Klik cover = buka tab Media.
RowLayout {
    id: root

    readonly property var player: Media.active

    readonly property int pageWidth: 380

    spacing: Appearance.spacing.large

    CoverArt {
        implicitWidth: 112
        implicitHeight: 112
        radius: Appearance.radius.normal
        source: root.player?.trackArtUrl ?? ""
        title: root.player?.trackTitle ?? ""
        progress: Media.progress

        StateLayer {
            onClicked: DrawerState.togglePanel("media")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Tidak ada media"
            font.pixelSize: Appearance.font.size.larger
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackArtist || root.player?.identity || ""
            color: Appearance.colors.primary
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            implicitHeight: 6
            visible: (root.player?.length ?? 0) > 0

            StyledRect {
                anchors.fill: parent
                radius: 3
                color: Appearance.colors.secondaryContainer
            }

            StyledRect {
                width: parent.width * Media.progress
                height: parent.height
                radius: 3
                color: Appearance.colors.primary

                Behavior on width {
                    Anim {
                        duration: 1000
                        easing.type: Easing.Linear
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (root.player?.canSeek)
                        root.player.position = Math.max(0, Math.min(1, event.x / width)) * root.player.length;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                visible: (root.player?.length ?? 0) > 0
                text: `${Media.formatTime(Media.position)} / ${Media.formatTime(Media.length)}`
                color: Appearance.colors.textDim
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "skip_previous"
                disabled: !(root.player?.canGoPrevious ?? false)
                onClicked: root.player.previous()
            }

            IconButton {
                icon: Media.playing ? "pause" : "play_arrow"
                type: "filled"
                toggled: true
                disabled: !(root.player?.canTogglePlaying ?? false)
                onClicked: root.player.togglePlaying()
            }

            IconButton {
                icon: "skip_next"
                disabled: !(root.player?.canGoNext ?? false)
                onClicked: root.player.next()
            }
        }
    }
}
