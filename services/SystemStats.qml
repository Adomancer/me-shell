pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// CPU & RAM dari /proc. Hanya polling saat control panel terbuka.
Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property var lastCpu: null

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: DrawerState.active === "panel"
        onTriggered: {
            stat.reload();
            meminfo.reload();
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
            }
            root.lastCpu = {
                total,
                idle
            };
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            root.memory = total ? 1 - avail / total : 0;
        }
    }
}
