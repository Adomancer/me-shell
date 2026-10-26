import QtQuick
import qs.components
import qs.services
import qs.utils

// Indikator rekam layar: titik merah berdenyut + durasi. Klik untuk berhenti.
StyledRect {
    id: root

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: Appearance.radius.small
    color: Appearance.colors.errorContainer

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
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

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.elapsedText
            color: Appearance.colors.errorContainerText
            font.family: Appearance.font.family.mono
            font.bold: true
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "stop"
            fill: 1
            color: Appearance.colors.errorContainerText
        }
    }

    StateLayer {
        color: Appearance.colors.errorContainerText
        onClicked: Recorder.stop()
    }
}
