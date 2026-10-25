import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

Card {
    component Label: StyledText {
        Layout.preferredWidth: 40
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    component Pct: StyledText {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        font.pixelSize: Appearance.font.size.small
    }

    title: "resources"

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Appearance.spacing.normal
        rowSpacing: 4

        Label {
            text: "CPU"
        }
        BlockBar {
            Layout.fillWidth: true
            value: SystemStats.cpu
        }
        Pct {
            text: `${Math.round(SystemStats.cpu * 100)}%`
        }

        Label {
            text: "RAM"
        }
        BlockBar {
            Layout.fillWidth: true
            value: SystemStats.memory
        }
        Pct {
            text: `${Math.round(SystemStats.memory * 100)}%`
        }

        Label {
            text: "DISK"
        }
        BlockBar {
            Layout.fillWidth: true
            value: SystemStats.disk
        }
        Pct {
            text: `${Math.round(SystemStats.disk * 100)}%`
        }

        Label {
            visible: SystemStats.temp > 0
            text: "TEMP"
        }
        BlockBar {
            Layout.fillWidth: true
            visible: SystemStats.temp > 0
            // Skala 0-100°C
            value: SystemStats.temp / 100
            color: SystemStats.temp >= 80 ? Appearance.colors.error : Appearance.colors.primary
        }
        Pct {
            visible: SystemStats.temp > 0
            text: `${Math.round(SystemStats.temp)}°`
        }
    }
}
