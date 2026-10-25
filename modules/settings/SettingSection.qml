import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

ColumnLayout {
    id: root

    property string title: ""

    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacing.huge
    spacing: Appearance.spacing.small

    StyledText {
        text: root.title.toUpperCase()
        color: Appearance.colors.primary
        font.pixelSize: Appearance.font.size.small
        font.bold: true
        font.letterSpacing: 2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Appearance.border.thin
        color: Appearance.colors.outline
    }
}
