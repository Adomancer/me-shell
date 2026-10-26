import QtQuick
import qs.components
import qs.services
import qs.utils

// Lagu yang diputar: sampul, judul, visualizer titik, dan kontrol.
Tile {
    id: root

    readonly property var player: Media.active

    Component.onCompleted: Cava.users++
    Component.onDestruction: Cava.users--

    Caption {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.player?.identity ?? "Media"
        elide: Text.ElideRight
    }

    // Tanpa pemutar
    Column {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "music_off"
            font.pixelSize: 36
            color: Appearance.colors.outline
        }

        Caption {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Tidak ada media"
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 26
        visible: root.player !== null

        Row {
            id: info

            width: parent.width
            spacing: Appearance.spacing.normal

            StyledClippingRect {
                id: cover

                width: 52
                height: 52
                radius: Appearance.radius.normal
                color: Appearance.colors.surfaceContainerHigh

                Image {
                    id: art

                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(104, 104)
                    asynchronous: true
                    visible: status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "album"
                    font.pixelSize: 28
                    color: Appearance.colors.textDim
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - cover.width - parent.spacing

                StyledText {
                    width: parent.width
                    text: root.player?.trackTitle || "Tanpa judul"
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    visible: text !== ""
                    text: root.player?.trackArtist ?? ""
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }
        }

        DotColumns {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: info.bottom
            anchors.topMargin: Appearance.spacing.normal
            anchors.bottom: controls.top
            anchors.bottomMargin: Appearance.spacing.small
            columns: 24
            rows: Math.max(3, Math.floor(height / 9))
            values: Media.playing ? Cava.values : []
        }

        Row {
            id: controls

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
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
}
