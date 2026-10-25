import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

Card {
    title: "Resource"
    icon: "monitoring"
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
            implicitHeight: 84

            CircularProgress {
                anchors.centerIn: parent
                size: 84
                thickness: 7
                value: SystemStats.cpu
                label: "CPU"
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 84

            CircularProgress {
                anchors.centerIn: parent
                size: 84
                thickness: 7
                value: SystemStats.memory
                label: "RAM"
                color: Appearance.colors.secondary
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 84

            CircularProgress {
                anchors.centerIn: parent
                size: 84
                thickness: 7
                value: SystemStats.disk
                label: "DISK"
                color: Appearance.colors.tertiary
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 84
            visible: SystemStats.temp > 0

            CircularProgress {
                anchors.centerIn: parent
                size: 84
                thickness: 7
                // Skala 0-100°C
                value: SystemStats.temp / 100
                label: "SUHU"
                color: SystemStats.temp >= 80 ? Appearance.colors.error : Appearance.colors.primary
            }
        }
    }
}
