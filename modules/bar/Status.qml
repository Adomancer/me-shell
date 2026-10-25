import QtQuick
import qs.components
import qs.services
import qs.utils

// Status gaya terminal: LABEL nilai. Info lain ada di control panel.
Row {
    id: root

    component StatusItem: MouseArea {
        id: it

        property string label
        property string value
        property color valueColor: Appearance.colors.text

        implicitWidth: r.implicitWidth
        implicitHeight: r.implicitHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Row {
            id: r

            spacing: Appearance.spacing.small

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: it.label
                color: it.containsMouse ? Appearance.colors.primary : Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                font.bold: true
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: it.value !== ""
                text: it.value
                color: it.valueColor
            }
        }
    }

    spacing: Appearance.spacing.large

    StatusItem {
        visible: Battery.available
        label: Battery.charging ? "CHG" : "BAT"
        value: `${Math.round(Battery.percentage * 100)}%`
        valueColor: !Battery.charging && Battery.percentage < 0.15 ? Appearance.colors.error : Appearance.colors.text
    }

    StatusItem {
        label: "[PWR]"
        value: ""
        onClicked: DrawerState.toggle("session")
    }
}
