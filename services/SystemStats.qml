pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// CPU, RAM, disk, suhu, dan jaringan. Hanya polling saat control panel terbuka atau layar terkunci.
Singleton {
    id: root

    readonly property int historyLength: 40

    property real cpu: 0
    property string cpuName: ""
    property real memory: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real swap: 0
    property real disk: 0
    property real home: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    // °C, 0 kalau sensor tidak terbaca
    property real temp: 0
    // byte per detik
    property real netRx: 0
    property real netTx: 0
    property string netIface: ""
    property int cores: 1
    // [{ name, cpu, mem }] lima proses paling rakus CPU (persen dari seluruh CPU)
    property var topProcs: []

    // Riwayat untuk grafik; netHistory dalam byte/detik (UI menormalkan sendiri)
    property var cpuHistory: []
    property var memHistory: []
    property var netHistory: []

    property var lastCpu: null
    property var lastNet: null

    function push(arr: var, v: real): var {
        const a = arr.concat([v]);
        return a.length > historyLength ? a.slice(-historyLength) : a;
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: DrawerState.active === "panel" || Session.locked
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            diskProc.running = true;
            tempProc.running = true;
            topProc.running = true;
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] ?? 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                root.cpu = dt > 0 ? 1 - (idle - root.lastCpu.idle) / dt : 0;
                root.cpuHistory = root.push(root.cpuHistory, root.cpu);
            }
            root.lastCpu = {
                total,
                idle
            };
        }
    }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: {
            root.cpuName = (text().match(/model name\s*:\s*(.*)/)?.[1] ?? "").replace(/\s+/g, " ").trim();
            root.cores = Math.max(1, (text().match(/^processor\s*:/gm) ?? []).length);
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const kb = key => Number(t.match(new RegExp(`${key}:\\s+(\\d+)`))?.[1] ?? 0);
            const total = kb("MemTotal");
            const avail = kb("MemAvailable");
            const swapTotal = kb("SwapTotal");
            root.memory = total ? 1 - avail / total : 0;
            root.memTotalGiB = total / 1048576;
            root.memUsedGiB = (total - avail) / 1048576;
            root.swap = swapTotal ? 1 - kb("SwapFree") / swapTotal : 0;
            root.memHistory = root.push(root.memHistory, root.memory);
        }
    }

    FileView {
        id: netdev

        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0;
            let tx = 0;
            let best = "";
            let bestRx = -1;
            for (const line of text().split("\n").slice(2)) {
                const [name, rest] = line.split(":");
                if (!rest || name.trim() === "lo")
                    continue;
                const f = rest.trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
                if (f[0] > bestRx) {
                    bestRx = f[0];
                    best = name.trim();
                }
            }
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.time) / 1000;
                root.netRx = dt > 0 ? Math.max(0, (rx - root.lastNet.rx) / dt) : 0;
                root.netTx = dt > 0 ? Math.max(0, (tx - root.lastNet.tx) / dt) : 0;
                root.netHistory = root.push(root.netHistory, root.netRx);
            }
            root.netIface = best;
            root.lastNet = {
                rx,
                tx,
                time: now
            };
        }
    }

    Process {
        id: diskProc

        command: ["df", "-P", "-B1", "/", "/home"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n").slice(1)) {
                    const f = line.trim().split(/\s+/);
                    const used = Number(f[2]);
                    const size = Number(f[1]);
                    const ratio = size ? used / size : 0;
                    if (f[5] === "/") {
                        root.disk = ratio;
                        root.diskUsedGiB = used / 1073741824;
                        root.diskTotalGiB = size / 1073741824;
                        root.home = ratio;
                    } else if (f[5] === "/home") {
                        root.home = ratio;
                    }
                }
            }
        }
    }

    Process {
        id: topProc

        // top, bukan ps: %CPU ps adalah rata-rata sepanjang umur proses. Locale C supaya desimal pakai titik.
        // Kolom: PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
        command: ["top", "-bn1", "-w", "200", "-o", "%CPU"]
        environment: ({
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const head = lines.findIndex(l => l.trim().startsWith("PID"));
                root.topProcs = lines.slice(head + 1).filter(l => l.trim()).slice(0, 5).map(l => {
                    const f = l.trim().split(/\s+/);
                    return {
                        name: f.slice(11).join(" "),
                        // top menghitung per core (bisa >100%)
                        cpu: (Number(f[8]) || 0) / root.cores,
                        mem: Number(f[9]) || 0
                    };
                });
            }
        }
    }

    // Ambil suhu tertinggi dari semua thermal zone
    Process {
        id: tempProc

        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: root.temp = (Number(text.trim()) || 0) / 1000
        }
    }

    function formatSpeed(bytes: real): string {
        if (bytes >= 1048576)
            return `${(bytes / 1048576).toFixed(1)} MB/s`;
        if (bytes >= 1024)
            return `${Math.round(bytes / 1024)} KB/s`;
        return `${Math.round(bytes)} B/s`;
    }
}
