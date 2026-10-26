pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Lampu malam lewat hyprsunset. Prosesnya hidup selama lampu menyala; mati = suhu layar kembali normal.
Singleton {
    id: root

    property bool available: false
    property bool enabled: false

    function toggle(): void {
        if (!available) {
            Toaster.show("error", "hyprsunset tidak ada", "Install hyprsunset untuk lampu malam", "");
            return;
        }
        enabled = !enabled;
        Toaster.show(enabled ? "nightlight" : "light_mode", enabled ? "Lampu malam menyala" : "Lampu malam mati", enabled ? `${Config.nightLightTemp} K` : "", "");
    }

    Process {
        command: ["sh", "-c", "command -v hyprsunset"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc

        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "-t", String(Config.nightLightTemp)]
        running: root.enabled && root.available
    }

    // Suhu diganti saat menyala: jalankan ulang dengan nilai baru
    Connections {
        target: Config

        function onNightLightTempChanged(): void {
            if (proc.running) {
                proc.running = false;
                proc.running = true;
            }
        }
    }

    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggle();
        }
    }
}
