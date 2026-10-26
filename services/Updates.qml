pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Jumlah update paket (ide dari Updates.qml end-4): dnf di Fedora, checkupdates (pacman-contrib) di Arch.
// Dicek semenit setelah start lalu tiap jam; upgrade dijalankan di terminal yang ada.
Singleton {
    id: root

    // "dnf", "pacman", atau "" kalau tidak didukung
    property string manager: ""
    property int count: 0
    property bool checking: false
    readonly property bool available: manager !== ""

    function check(): void {
        if (available && !proc.running) {
            checking = true;
            proc.running = true;
        }
    }

    function upgrade(): void {
        const cmd = manager === "dnf" ? "sudo dnf upgrade" : "sudo pacman -Syu";
        const script = `for t in kitty foot alacritty wezterm ghostty; do command -v "$t" >/dev/null && exec "$t" -e sh -c '${cmd}; echo; read -rp "Enter untuk menutup" _'; done`;
        Quickshell.execDetached(["sh", "-c", script]);
    }

    Process {
        command: ["sh", "-c", "if command -v dnf >/dev/null; then echo dnf; elif command -v checkupdates >/dev/null; then echo pacman; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.manager = text.trim()
        }
    }

    Process {
        id: proc

        // dnf: hanya baris paket "nama.arch versi repo"; header seperti "Upgrades"/"Obsoleting" tidak dihitung
        command: root.manager === "dnf" ? ["sh", "-c", "dnf -q check-update 2>/dev/null | grep -cE '^[^ ]+\\.[^ ]+ +[^ ]+ +[^ ]+ *$' || true"] : ["sh", "-c", "checkupdates 2>/dev/null | grep -c . || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = Number(text.trim()) || 0;
                root.checking = false;
            }
        }
    }

    Timer {
        interval: 60000
        running: Config.updateCheck && root.available
        onTriggered: root.check()
    }

    Timer {
        interval: 3600000
        repeat: true
        running: Config.updateCheck && root.available
        onTriggered: root.check()
    }

    IpcHandler {
        target: "updates"

        function check(): void {
            root.check();
        }

        function count(): int {
            return root.count;
        }
    }
}
