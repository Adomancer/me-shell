import QtQuick
import qs.components
import qs.services
import qs.utils

// Indikator rekam layar ala Nothing: titik merah berdenyut + "REC" + durasi, tanpa kotak. Klik untuk berhenti.
StyledRect {
    id: root

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Appearance.colors.error

            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite

                Anim {
                    to: 0.3
                    duration: Appearance.anim.durations.large
                }
                Anim {
                    to: 1
                    duration: Appearance.anim.durations.large
                }
            }
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: "REC"
            color: Appearance.colors.error
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.elapsedText
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.smaller
        }
    }

    StateLayer {
        color: Appearance.colors.error
        onClicked: Recorder.stop()
    }
}
