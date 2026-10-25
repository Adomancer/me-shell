import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    readonly property var player: Media.active

    implicitHeight: content.implicitHeight + Appearance.spacing.large * 2
    color: Appearance.colors.background
    border.width: Appearance.border.thin
    border.color: Appearance.colors.outline

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.spacing.large
        spacing: Appearance.spacing.large

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 72
            implicitHeight: 72
            color: Appearance.colors.surfaceHigh
            border.width: Appearance.border.thin
            border.color: Appearance.colors.outline

            // pixelArt: cover dirender kecil lalu diperbesar tanpa smoothing
            Image {
                id: art

                anchors.fill: parent
                anchors.margins: Appearance.border.thin
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                smooth: !Config.pixelArt
                sourceSize: Config.pixelArt ? Qt.size(32, 32) : Qt.size(144, 144)
                asynchronous: true
                visible: status === Image.Ready
            }

            StyledText {
                anchors.centerIn: parent
                visible: !art.visible
                text: "♪"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.huge / 2
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "TIDAK ADA MEDIA"
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Appearance.colors.textDim
                elide: Text.ElideRight
            }

            SegmentSlider {
                Layout.fillWidth: true
                visible: root.player !== null && root.player.length > 0
                implicitHeight: 6
                segments: 24
                showValue: false
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                onMoved: v => {
                    if (root.player?.canSeek)
                        root.player.position = v * root.player.length;
                }
            }

            Row {
                visible: root.player !== null
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
}
