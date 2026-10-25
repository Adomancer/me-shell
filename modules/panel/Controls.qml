import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    function toggleText(name: string, on: bool): string {
        return `${on ? "[x]" : "[ ]"} ${name}`;
    }

    spacing: Appearance.spacing.normal

    SegmentSlider {
        Layout.fillWidth: true
        label: "VOL"
        value: Audio.muted ? 0 : Audio.volume
        onMoved: v => Audio.setVolume(v)
    }

    SegmentSlider {
        Layout.fillWidth: true
        visible: Brightness.available
        label: "LCD"
        value: Brightness.value
        onMoved: v => Brightness.set(v)
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        columns: 2
        columnSpacing: Appearance.spacing.normal
        rowSpacing: Appearance.spacing.normal

        RetroButton {
            Layout.fillWidth: true
            text: root.toggleText("WIFI", Network.wifiEnabled)
            active: Network.wifiEnabled
            onClicked: Network.setWifi(!Network.wifiEnabled)
        }

        RetroButton {
            Layout.fillWidth: true
            enabled: BluetoothService.available
            text: root.toggleText("BLUETOOTH", BluetoothService.enabled)
            active: BluetoothService.enabled
            onClicked: BluetoothService.toggle()
        }

        RetroButton {
            Layout.fillWidth: true
            text: root.toggleText("DND", Notifs.dnd)
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        RetroButton {
            Layout.fillWidth: true
            text: root.toggleText("MIC", !Audio.micMuted)
            active: !Audio.micMuted
            onClicked: Audio.toggleMic()
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Network.connected
        text: `> ${Network.ssid}`
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        elide: Text.ElideRight
    }
}
