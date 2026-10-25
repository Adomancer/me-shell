import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

GridLayout {
    columns: 3
    columnSpacing: Appearance.spacing.normal
    rowSpacing: 2

    StyledText {
        text: "CPU"
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    BlockBar {
        Layout.fillWidth: true
        value: SystemStats.cpu
        segments: 20
    }

    StyledText {
        text: `${Math.round(SystemStats.cpu * 100)}%`
    }

    StyledText {
        text: "RAM"
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    BlockBar {
        Layout.fillWidth: true
        value: SystemStats.memory
        segments: 20
    }

    StyledText {
        text: `${Math.round(SystemStats.memory * 100)}%`
    }
}
