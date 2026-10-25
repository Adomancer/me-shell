import QtQuick
import qs.components
import qs.services
import qs.utils

// Status gaya terminal: LABEL nilai
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
        visible: Notifs.dnd || Notifs.list.length > 0
        label: Notifs.dnd ? "DND" : "MSG"
        value: Notifs.dnd ? "" : Notifs.list.length
        onClicked: DrawerState.toggle("panel")
    }

    StatusItem {
        label: "NET"
        value: Network.ethernet ? "ETH" : Network.connected ? `${Network.signal}%` : Network.wifiEnabled ? "--" : "OFF"
        valueColor: Network.ethernet || Network.connected ? Appearance.colors.text : Appearance.colors.textDim
        onClicked: DrawerState.toggle("panel")
    }

    StatusItem {
        visible: BluetoothService.available && BluetoothService.enabled
        label: "BT"
        value: BluetoothService.devices.length > 0 ? BluetoothService.devices.length : "ON"
        onClicked: DrawerState.toggle("panel")
    }

    StatusItem {
        label: "VOL"
        value: Audio.muted ? "MUTE" : `${Math.round(Audio.volume * 100)}%`
        valueColor: Audio.muted ? Appearance.colors.textDim : Appearance.colors.text
        onClicked: Audio.toggleMute()
        onWheel: wheel => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
    }

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
