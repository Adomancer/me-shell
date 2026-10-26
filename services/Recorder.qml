pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.utils

// Rekam layar lewat wf-recorder. Berhenti = SIGINT supaya file video ditutup dengan benar.
Singleton {
    id: root

    property bool available: false
    readonly property bool recording: proc.running
    property int elapsed: 0
    readonly property string elapsedText: `${Math.floor(elapsed / 60)}:${String(elapsed % 60).padStart(2, "0")}`

    function toggle(): void {
        if (recording)
            stop();
        else
            screen();
    }

    // Seluruh monitor yang sedang fokus
    function screen(): void {
        start(["-o", Hyprland.focusedMonitor?.name ?? ""]);
    }

    function region(x: real, y: real, w: real, h: real): void {
        start(["-g", `${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`]);
    }

    function start(args: var): void {
        if (recording)
            return;
        if (!available) {
            Toaster.show("error", "wf-recorder tidak ada", "Install wf-recorder untuk merekam layar", "");
            return;
        }
        DrawerState.close();
        const file = `${Config.recordingDir}/Recording_${Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")}.mp4`;
        proc.file = file;
        proc.command = ["setpriv", "--pdeathsig", "TERM", "sh", "-c", 'f="$1"; shift; mkdir -p "$(dirname "$f")" && exec wf-recorder -f "$f" "$@"', "sh", file, ...args, ...(Config.recordAudio ? ["-a"] : [])];
        proc.running = true;
    }

    function stop(): void {
        if (recording)
            proc.signal(2);
    }

    Process {
        command: ["sh", "-c", "command -v wf-recorder"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc

        property string file

        onRunningChanged: {
            if (running) {
                root.elapsed = 0;
                Toaster.show("screen_record", "Merekam layar", "Klik indikator di bar untuk berhenti", "");
            }
        }
        onExited: code => {
            if (root.elapsed > 0)
                Toaster.show("video_file", "Rekaman disimpan", file.split("/").pop(), "");
            else
                Toaster.show("error", "Rekaman gagal", `wf-recorder keluar dengan kode ${code}`, "");
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed++
    }

    IpcHandler {
        target: "recorder"

        function toggle(): void {
            root.toggle();
        }

        function region(): void {
            Screenshot.openPicker("record");
        }

        function isRecording(): bool {
            return root.recording;
        }
    }
}
