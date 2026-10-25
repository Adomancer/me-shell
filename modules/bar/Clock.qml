import QtQuick
import qs.components
import qs.services
import qs.utils

// Jam di tengah bar (angka mono). Klik untuk membuka dashboard.
StyledRect {
    id: root

    readonly property bool active: DrawerState.active === "panel"

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2
    color: active ? Appearance.colors.primaryContainer : Appearance.colors.surfaceContainer

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.time
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.larger
            font.bold: true
            color: root.active ? Appearance.colors.primaryContainerText : Appearance.colors.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateText
            color: root.active ? Appearance.colors.primaryContainerText : Appearance.colors.textDim
        }
    }

    StateLayer {
        color: root.active ? Appearance.colors.primaryContainerText : Appearance.colors.text
        onClicked: DrawerState.togglePanel("dash")
    }
}
