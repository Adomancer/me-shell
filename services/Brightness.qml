pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// Brightness layar lewat brightnessctl. available = false kalau tidak ada backlight.
Singleton {
    id: root

    property bool available: false
    property real value: 0

    function set(v: real): void {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        value = pct / 100;
        Quickshell.execDetached(["brightnessctl", "-q", "s", `${pct}%`]);
        OsdState.show("brightness");
    }

    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        command: ["brightnessctl", "-m", "-c", "backlight", "i"]
        running: true
        stdout: StdioCollector {
            // Format: device,class,current,percent%,max
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 5) {
                    root.available = true;
                    root.value = parseInt(parts[3]) / 100;
                }
            }
        }
    }

    Connections {
        target: DrawerState

        function onActiveChanged(): void {
            if (DrawerState.active === "panel")
                root.refresh();
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.set(root.value + 0.05);
        }

        function down(): void {
            root.set(root.value - 0.05);
        }
    }
}
