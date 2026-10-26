import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Kartu lagu yang sedang diputar: cover bulat berputar seperti piringan saat lagu jalan. Tanpa cover:
// cincin titik progres lagu.
Card {
    id: root

    readonly property var player: Media.active
    property int artSize: 132

    // Cover berputar
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.spacing.small
        implicitWidth: root.artSize
        implicitHeight: root.artSize

        CoverArt {
            id: disc

            anchors.fill: parent
            radius: width / 2
            source: root.player?.trackArtUrl ?? ""
            title: root.player?.trackTitle ?? ""
            progress: Media.progress

            // Hanya cover yang berputar, selama lagu jalan dan panel tampil; mulai lagi dari sudut terakhir,
            // jadi tidak meloncat
            RotationAnimator on rotation {
                from: disc.rotation % 360
                to: disc.rotation % 360 + 360
                duration: 12000
                loops: Animation.Infinite
                running: Media.playing && root.visible && disc.hasArt
            }
        }

        // Lubang tengah piringan
        Rectangle {
            anchors.centerIn: parent
            visible: disc.hasArt
            width: 18
            height: 18
            radius: 9
            color: Appearance.colors.surfaceContainer
            border.width: 3
            border.color: Appearance.alpha(Appearance.colors.text, 0.15)
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        horizontalAlignment: Text.AlignHCenter
        text: root.player?.trackTitle || "Tidak ada media"
        font.pixelSize: Appearance.font.size.larger
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.player?.trackArtist || root.player?.identity || "Putar sesuatu untuk mulai"
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        elide: Text.ElideRight
    }

    // Progress
    Item {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        implicitHeight: 8
        visible: (root.player?.length ?? 0) > 0

        SegmentBar {
            anchors.fill: parent
            segments: 32
            value: Media.progress
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

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.normal

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_previous"
            disabled: !(root.player?.canGoPrevious ?? false)
            onClicked: root.player.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: Media.playing ? "pause" : "play_arrow"
            type: "filled"
            toggled: true
            size: Appearance.font.size.extraLarge
            padding: Appearance.padding.normal
            disabled: !(root.player?.canTogglePlaying ?? false)
            onClicked: root.player.togglePlaying()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_next"
            disabled: !(root.player?.canGoNext ?? false)
            onClicked: root.player.next()
        }
    }
}
