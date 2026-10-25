import Quickshell.Hyprland
import QtQuick
import qs.components
import qs.utils

Row {
    id: root

    spacing: Appearance.spacing.small

    Repeater {
        model: Config.workspaces

        StyledRect {
            id: ws

            required property int index
            readonly property int wsId: index + 1
            readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

            implicitWidth: focused ? 30 : 20
            implicitHeight: 18
            color: focused ? Appearance.colors.primary : occupied ? Appearance.colors.surfaceHigh : "transparent"
            border.width: Appearance.border.thin
            border.color: focused ? Appearance.colors.primary : Appearance.colors.outline

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.anim.duration.normal
                    easing.type: Appearance.anim.easing.emphasized
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: ws.wsId
                font.pixelSize: Appearance.font.size.small
                font.bold: ws.focused
                color: ws.focused ? Appearance.colors.primaryText : ws.occupied ? Appearance.colors.text : Appearance.colors.textDim
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${ws.wsId}`)
            }
        }
    }
}
