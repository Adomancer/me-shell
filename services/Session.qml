pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Lock & aksi power.
Singleton {
    id: root

    property bool locked: false

    function lock(): void {
        locked = true;
    }

    function logout(): void {
        Hyprland.dispatch("exit");
    }

    function suspend(): void {
        lock();
        // Beri waktu lockscreen muncul sebelum suspend
        suspendTimer.restart();
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Timer {
        id: suspendTimer

        interval: 500
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked;
        }
    }
}
