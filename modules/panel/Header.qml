import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

RowLayout {
    spacing: Appearance.spacing.large

    StyledText {
        text: Time.time
        color: Appearance.colors.primary
        font.pixelSize: Appearance.font.size.huge
        font.bold: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: Time.dateText.toUpperCase()
            font.bold: true
        }

        StyledText {
            text: `${Quickshell.env("USER")}@me-shell`
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }
    }
}
