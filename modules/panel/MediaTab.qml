import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tab Media: cover besar dengan latar buram dari cover itu sendiri, info lagu, visualizer cava,
// progress yang bisa digeser, dan kontrol.
StyledClippingRect {
    id: root

    readonly property var player: Media.active
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    radius: Appearance.radius.normal
    color: Appearance.colors.surfaceContainer

    // Latar: cover yang diburamkan dan digelapkan
    Image {
        id: backdrop

        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(128, 128)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdrop
        visible: backdrop.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: 0.2
        opacity: 0.35
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.3)
            }
            GradientStop {
                position: 0.6
                color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.9)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.huge + 8

        // Cover
        StyledClippingRect {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 300
            implicitHeight: 300
            radius: Appearance.radius.large
            color: Appearance.colors.secondaryContainer
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
                text: "music_note"
                font.pixelSize: 120
                color: Appearance.colors.secondaryContainerText
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
                implicitHeight: 16
                visible: (root.player?.length ?? 0) > 0

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Appearance.colors.secondaryContainer
                }

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    width: seek.pressed ? seek.live * parent.width : root.progress * parent.width
                    height: 6
                    radius: 3
                    color: Appearance.colors.primary

                    Behavior on width {
                        enabled: !seek.pressed

                        Anim {
                            duration: 1000
                            easing.type: Easing.Linear
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: (seek.pressed ? seek.live : root.progress) * parent.width - width / 2
                    width: seek.containsMouse || seek.pressed ? 16 : 12
                    height: width
                    radius: 1
                    color: Appearance.colors.primary

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
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
                        color: modelData === root.player ? Appearance.colors.secondaryContainer : Appearance.colors.surfaceContainerHigh
                    }
                }
            }
        }
    }
}
