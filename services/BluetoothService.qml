pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Bluetooth lewat BlueZ (D-Bus, modul Quickshell.Bluetooth). Tidak ada polling.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    // Semua perangkat: terhubung dulu, lalu yang sudah dipasangkan, lalu sisanya
    readonly property var all: [...(adapter?.devices?.values ?? [])].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var devices: all.filter(d => d.connected)

    function toggle(): void {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function setDiscovering(on: bool): void {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }

    // Klik perangkat: putuskan kalau terhubung, sambungkan kalau sudah dipasangkan, pasangkan kalau belum
    function activate(device: BluetoothDevice): void {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    function icon(device: BluetoothDevice): string {
        const i = device?.icon ?? "";
        if (i.includes("headset") || i.includes("headphone"))
            return "headphones";
        if (i.includes("audio"))
            return "speaker";
        if (i.includes("keyboard"))
            return "keyboard";
        if (i.includes("mouse"))
            return "mouse";
        if (i.includes("phone"))
            return "smartphone";
        if (i.includes("game"))
            return "sports_esports";
        return "bluetooth";
    }
}
