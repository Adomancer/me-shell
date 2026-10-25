import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Judul grup setting
StyledText {
    property string title: ""

    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacing.huge
    Layout.bottomMargin: Appearance.spacing.small
    Layout.leftMargin: Appearance.spacing.small
    text: title
    color: Appearance.colors.primary
    font.weight: Font.Medium
}
