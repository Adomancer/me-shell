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

    // Sudah diperingatkan di level ini; direset saat charger dicolok
    property bool warnedLow: false
    property bool warnedCritical: false

    function setProfile(p: int): void {
        PowerProfiles.profile = p;
    }

    function profileName(p: int): string {
        return p === PowerProfile.PowerSaver ? "Hemat daya" : p === PowerProfile.Performance ? "Performa" : "Seimbang";
    }

    // Peringatan lewat notifikasi sungguhan supaya ikut riwayat; 5% = kritis (tidak hilang sendiri)
    onPercentageChanged: {
        if (!available || charging)
            return;
        if (percentage <= 0.05 && !warnedCritical) {
            warnedCritical = true;
            warnedLow = true;
            Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "me-shell", "-i", "battery-caution", "Baterai hampir habis", `${Math.round(percentage * 100)}% tersisa. Colokkan charger sekarang.`]);
        } else if (percentage <= 0.15 && !warnedLow) {
            warnedLow = true;
            Quickshell.execDetached(["notify-send", "-a", "me-shell", "-i", "battery-low", "Baterai lemah", `${Math.round(percentage * 100)}% tersisa`]);
        }
    }

    onChargingChanged: {
        if (charging) {
            warnedLow = false;
            warnedCritical = false;
        }
        if (available)
            Toaster.show(charging ? "power" : "power_off", charging ? "Charger tersambung" : "Charger dilepas", `${Math.round(percentage * 100)}%`, "");
    }

    onProfileChanged: Toaster.show(profile === PowerProfile.PowerSaver ? "energy_savings_leaf" : profile === PowerProfile.Performance ? "bolt" : "balance", "Power profile", profileName(profile), "")
}
