pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// Brightness layar lewat brightnessctl (backlight laptop), atau ddcutil untuk monitor eksternal yang mendukung
// DDC/CI (ide dari Caelestia). available = false kalau keduanya tidak ada.
Singleton {
    id: root

    // "backlight", "ddc", atau "" kalau belum/tidak ada
    property string backend: ""
    readonly property bool available: backend !== ""
    property real value: 0
    // Nilai maksimum VCP 10 dari monitor (tidak selalu 100)
    property int ddcMax: 100

    function set(v: real): void {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        value = pct / 100;
        if (backend === "backlight")
            Quickshell.execDetached(["brightnessctl", "-q", "s", `${pct}%`]);
        else
            ddcWrite.restart();
        OsdState.show("brightness");
    }

    function refresh(): void {
        if (backend === "ddc")
            ddcRead.running = true;
        else
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
                    root.backend = "backlight";
                    root.value = parseInt(parts[3]) / 100;
                } else if (root.backend === "") {
                    // Tidak ada backlight: coba monitor eksternal lewat DDC/CI
                    ddcRead.running = true;
                }
            }
        }
    }

    // "VCP 10 C <sekarang> <maks>"; gagal/tidak ada ddcutil = tetap tidak tersedia
    Process {
        id: ddcRead

        command: ["sh", "-c", "command -v ddcutil >/dev/null && ddcutil getvcp 10 --brief 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/VCP 10 C (\d+) (\d+)/);
                if (m && Number(m[2]) > 0) {
                    root.backend = "ddc";
                    root.ddcMax = Number(m[2]);
                    root.value = Number(m[1]) / root.ddcMax;
                }
            }
        }
    }

    // ddcutil lambat (ratusan ms per perintah); saat slider digeser hanya nilai terakhir yang dikirim
    Timer {
        id: ddcWrite

        interval: 250
        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", String(Math.round(root.value * root.ddcMax)), "--noverify"])
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
