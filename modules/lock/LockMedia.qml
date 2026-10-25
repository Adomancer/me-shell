import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

Card {
    id: root

    readonly property var player: Media.active

    title: "Sedang diputar"
    icon: "music_note"
    note: player?.identity ?? ""
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        StyledClippingRect {
            implicitWidth: 64
            implicitHeight: 64
            radius: Appearance.radius.small
            color: Appearance.colors.secondaryContainer

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(128, 128)
                asynchronous: true
                visible: status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !art.visible
                text: "album"
                font.pixelSize: 32
                color: Appearance.colors.secondaryContainerText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Tidak ada media"
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Appearance.colors.textDim
                elide: Text.ElideRight
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: (root.player?.length ?? 0) > 0
                implicitHeight: 4
                radius: 2
                color: Appearance.colors.secondaryContainer

                StyledRect {
                    width: parent.width * (root.player && root.player.length > 0 ? Math.min(1, root.player.position / root.player.length) : 0)
                    height: parent.height
                    radius: 2
                    color: Appearance.colors.primary

                    Behavior on width {
                        Anim {
                            duration: 1000
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }

        IconButton {
            visible: root.player !== null
            icon: Media.playing ? "pause" : "play_arrow"
            type: "filled"
            toggled: true
            onClicked: root.player.togglePlaying()
        }
    }
}
