import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Kartu lagu yang sedang diputar: cover bulat berputar seperti piringan saat lagu jalan.
Card {
    id: root

    readonly property var player: Media.active
    property int artSize: 132

    function fmt(sec: real): string {
        const s = Math.max(0, Math.floor(sec));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // Cover berputar
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.spacing.small
        implicitWidth: root.artSize
        implicitHeight: root.artSize

        StyledClippingRect {
            id: disc

            anchors.fill: parent
            radius: width / 2
            color: Appearance.colors.secondaryContainer

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(root.artSize * 2, root.artSize * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !art.visible
                text: "album"
                font.pixelSize: root.artSize * 0.5
                color: Appearance.colors.secondaryContainerText
            }

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 12000
                loops: Animation.Infinite
                running: true
                // Dijeda, bukan dihentikan, supaya tidak meloncat ke 0
                paused: !Media.playing
            }
        }

        // Lubang tengah piringan
        Rectangle {
            anchors.centerIn: parent
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
        implicitHeight: 6
        visible: (root.player?.length ?? 0) > 0

        StyledRect {
            anchors.fill: parent
            radius: 3
            color: Appearance.colors.secondaryContainer
        }

        StyledRect {
            width: parent.width * (root.player && root.player.length > 0 ? Math.min(1, root.player.position / root.player.length) : 0)
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
