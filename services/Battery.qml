pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.services

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
    // Detik; 0 kalau tidak diketahui
    readonly property real timeLeft: charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
    readonly property string timeLeftText: {
        const s = timeLeft;
        if (s <= 0)
            return "";
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        return h > 0 ? `${h} j ${m} mnt` : `${m} mnt`;
    }

    // Power profile (power-profiles-daemon atau tuned-ppd)
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    function setProfile(p: int): void {
        PowerProfiles.profile = p;
    }

    function profileName(p: int): string {
        return p === PowerProfile.PowerSaver ? "Hemat daya" : p === PowerProfile.Performance ? "Performa" : "Seimbang";
    }

    onChargingChanged: {
        if (available)
            Toaster.show(charging ? "power" : "power_off", charging ? "Charger tersambung" : "Charger dilepas", `${Math.round(percentage * 100)}%`, "");
    }

    onProfileChanged: Toaster.show(profile === PowerProfile.PowerSaver ? "energy_savings_leaf" : profile === PowerProfile.Performance ? "bolt" : "balance", "Power profile", profileName(profile), "")
}
