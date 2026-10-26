pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Timer fokus ala pomodoro + stopwatch (ide dari pomodoro end-4). Fokus selesai = istirahat otomatis mulai;
// istirahat selesai = berhenti dan menunggu. Waktu dihitung dari jam dinding, jadi tetap tepat walau tick telat.
Singleton {
    id: root

    // "idle", "focus", "break", "stopwatch"
    property string mode: "idle"
    property bool running: false
    // Mundur: kapan selesai (ms epoch) selama jalan, sisa detik selama dijeda
    property real endsAt: 0
    property real remaining: 0
    // Stopwatch: kapan mulai (ms epoch) dan detik yang terkumpul sebelum dijeda
    property real startedAt: 0
    property real banked: 0
    // Sesi fokus yang selesai hari ini
    property int sessions: 0
    property string sessionsDay: ""
    property real now: Date.now()

    readonly property bool countdown: mode === "focus" || mode === "break"
    readonly property int total: (mode === "break" ? Config.breakMinutes : Config.focusMinutes) * 60
    readonly property real left: running ? Math.max(0, (endsAt - now) / 1000) : remaining
    readonly property real elapsed: banked + (running && mode === "stopwatch" ? (now - startedAt) / 1000 : 0)
    // 0..1; stopwatch berputar satu lingkaran per menit
    readonly property real progress: countdown ? (total > 0 ? 1 - left / total : 0) : mode === "stopwatch" ? (elapsed % 60) / 60 : 0
    readonly property string text: format(countdown ? Math.ceil(left) : mode === "stopwatch" ? elapsed : Config.focusMinutes * 60)
    readonly property string label: ({
            idle: "Siap",
            focus: "Fokus",
            break: "Istirahat",
            stopwatch: "Stopwatch"
        })[mode]

    function format(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${String(m).padStart(2, "0")}:${ss}`;
    }

    function startCountdown(m: string): void {
        mode = m;
        now = Date.now();
        endsAt = now + total * 1000;
        running = true;
    }

    function startFocus(): void {
        startCountdown("focus");
    }

    function startBreak(): void {
        startCountdown("break");
    }

    function startStopwatch(): void {
        mode = "stopwatch";
        banked = 0;
        now = Date.now();
        startedAt = now;
        running = true;
    }

    // Jeda/lanjut; dari keadaan diam langsung mulai fokus
    function toggle(): void {
        if (mode === "idle") {
            startFocus();
            return;
        }
        now = Date.now();
        if (running) {
            if (countdown)
                remaining = left;
            else
                banked = elapsed;
            running = false;
        } else {
            if (countdown)
                endsAt = now + remaining * 1000;
            else
                startedAt = now;
            running = true;
        }
    }

    function stop(): void {
        running = false;
        mode = "idle";
        banked = 0;
        remaining = 0;
    }

    function finish(): void {
        if (mode === "focus") {
            const today = new Date().toDateString();
            if (sessionsDay !== today) {
                sessionsDay = today;
                sessions = 0;
            }
            sessions++;
            Quickshell.execDetached(["notify-send", "-a", "me-shell", "-i", "appointment-soon", "Fokus selesai", `Sesi ke-${sessions} hari ini. Istirahat ${Config.breakMinutes} menit dimulai.`]);
            startBreak();
        } else {
            running = false;
            mode = "idle";
            Quickshell.execDetached(["notify-send", "-a", "me-shell", "-i", "appointment-soon", "Istirahat selesai", "Siap untuk sesi berikutnya"]);
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            root.now = Date.now();
            if (root.countdown && root.left <= 0)
                root.finish();
        }
    }

    IpcHandler {
        target: "focus"

        function start(): void {
            root.startFocus();
        }

        function rest(): void {
            root.startBreak();
        }

        function stopwatch(): void {
            root.startStopwatch();
        }

        function toggle(): void {
            root.toggle();
        }

        function stop(): void {
            root.stop();
        }

        function state(): string {
            return `${root.mode} ${root.running ? "jalan" : "jeda"} ${root.text}`;
        }
    }
}
