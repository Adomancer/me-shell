import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Perangkat Bluetooth: klik untuk menyambung, memutus, atau memasangkan.
ColumnLayout {
    id: root

    readonly property int pageWidth: 320

    spacing: 2

    // Berhenti mencari saat popout ditutup
    Component.onDestruction: BluetoothService.setDiscovering(false)

    PopoutHeader {
        icon: "bluetooth"
        title: "Bluetooth"
        hasSwitch: true
        switchEnabled: BluetoothService.available
        checked: BluetoothService.enabled
        onToggled: BluetoothService.toggle()
    }

    Repeater {
        model: BluetoothService.enabled ? BluetoothService.all.slice(0, 8) : []

        ListRow {
            id: dev

            required property BluetoothDevice modelData
            readonly property bool connecting: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

            icon: BluetoothService.icon(modelData)
            title: modelData.name || modelData.address
            subtitle: {
                if (modelData.pairing)
                    return "Memasangkan...";
                if (modelData.connected)
                    return modelData.batteryAvailable ? `Tersambung · ${Math.round(modelData.battery * 100)}%` : "Tersambung";
                return modelData.paired ? "Dipasangkan" : "Tersedia";
            }
            active: modelData.connected
            busy: connecting || modelData.pairing
            onClicked: BluetoothService.activate(modelData)
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        visible: !BluetoothService.enabled || BluetoothService.all.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: !BluetoothService.available ? "Tidak ada adapter Bluetooth" : !BluetoothService.enabled ? "Bluetooth mati" : "Belum ada perangkat"
        color: Appearance.colors.textDim
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        visible: BluetoothService.enabled

        StyledText {
            Layout.fillWidth: true
            text: BluetoothService.discovering ? "Mencari perangkat..." : `${BluetoothService.devices.length} tersambung`
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }

        TextButton {
            type: "text"
            icon: BluetoothService.discovering ? "stop" : "search"
            text: BluetoothService.discovering ? "Berhenti" : "Cari"
            onClicked: BluetoothService.setDiscovering(!BluetoothService.discovering)
        }
    }
}
