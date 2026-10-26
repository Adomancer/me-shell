pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.utils

// Pengganti hypridle: kunci layar, matikan layar, lalu suspend setelah sekian menit diam.
// "Kafein" (inhibited) menahan semuanya; window Drawers juga memasang IdleInhibitor dari nilai ini.
Singleton {
    id: root

    property bool inhibited: false
    // Ada lagu/video yang diputar dan setting-nya aktif
    readonly property bool mediaHolds: Config.idleInhibitMedia && Media.playing
    // Kafein atau media: idle ditahan (juga dipakai IdleInhibitor di Drawers untuk hypridle)
    readonly property bool holding: inhibited || mediaHolds

    function toggleInhibit(): void {
        inhibited = !inhibited;
        Toaster.show(inhibited ? "coffee" : "coffee_maker", inhibited ? "Kafein aktif" : "Kafein mati", inhibited ? "Layar tidak akan terkunci sendiri" : "Idle kembali normal", "");
    }

    IdleMonitor {
        enabled: !root.holding && Config.idleLockMinutes > 0
        timeout: Config.idleLockMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    IdleMonitor {
        enabled: !root.holding && Config.idleScreenOffMinutes > 0
        timeout: Config.idleScreenOffMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: Hyprland.dispatch(isIdle ? "dpms off" : "dpms on")
    }

    IdleMonitor {
        enabled: !root.holding && Config.idleSuspendMinutes > 0
        timeout: Config.idleSuspendMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Session.suspend();
        }
    }

    IpcHandler {
        target: "idle"

        function inhibit(): void {
            root.toggleInhibit();
        }

        function isInhibited(): bool {
            return root.inhibited;
        }
    }
}
