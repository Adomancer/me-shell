pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Drawer mana yang terbuka ("panel", "launcher", "session") dan di monitor mana.
Singleton {
    id: root

    property string active: ""
    property string screen: ""

    function open(name: string): void {
        screen = Hyprland.focusedMonitor?.name ?? "";
        active = name;
    }

    function close(): void {
        active = "";
    }

    function toggle(name: string): void {
        if (active === name)
            close();
        else
            open(name);
    }

    IpcHandler {
        target: "drawers"

        function toggle(name: string): void {
            root.toggle(name);
        }

        function open(name: string): void {
            root.open(name);
        }

        function close(): void {
            root.close();
        }
    }
}
