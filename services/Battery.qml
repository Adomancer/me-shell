pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: device?.isLaptopBattery ?? false
    // Dinormalisasi ke 0..1
    readonly property real percentage: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
}
