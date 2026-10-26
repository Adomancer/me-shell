import QtQuick
import qs.components
import qs.services
import qs.utils

// Lagu yang diputar di bar, tanpa kotak: batang equalizer kecil + judul. Hover = popout media, klik = putar/jeda.
StyledRect {
    id: root

    readonly property var player: Media.active

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        // Tiga batang yang naik turun selama lagu jalan
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    id: bar

                    required property int index
                    property real level: 0.3

                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 4 + level * 10
                    radius: 2
                    color: Appearance.colors.primary

                    SequentialAnimation on level {
                        running: Media.playing && root.visible
                        loops: Animation.Infinite

                        Anim {
                            to: 1
                            duration: 300 + bar.index * 110
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                        Anim {
                            to: 0.2
                            duration: 260 + bar.index * 90
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            text: root.player?.trackTitle || root.player?.identity || ""
            elide: Text.ElideRight
            color: Media.playing ? Appearance.colors.text : Appearance.colors.textDim
        }
    }

    StateLayer {
        onClicked: root.player?.togglePlaying()
        onWheel: event => event.angleDelta.y > 0 ? root.player?.previous() : root.player?.next()
    }

    PopoutTrigger {
        popout: "media"
    }
}
