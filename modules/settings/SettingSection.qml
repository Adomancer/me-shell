import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Judul grup setting
Caption {
    property string title: ""

    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacing.huge
    Layout.bottomMargin: Appearance.spacing.small
    Layout.leftMargin: Appearance.spacing.small
    text: title
}
