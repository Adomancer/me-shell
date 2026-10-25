pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Info user dan sistem untuk kartu user dan FETCH: nama, avatar (~/.face), distro, kernel, uptime, jumlah paket.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    property string realName: ""
    readonly property string displayName: realName || user
    // UI menampilkan inisial kalau file ini tidak ada
    readonly property string avatar: `${Paths.home}/.face`
    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"
    property string host: ""
    property string distro: ""
    property string kernel: ""
    property string packages: ""
    property int uptimeSeconds: 0
    readonly property string uptime: {
        const s = uptimeSeconds;
        const d = Math.floor(s / 86400);
        const h = Math.floor(s % 86400 / 3600);
        const m = Math.floor(s % 3600 / 60);
        return d > 0 ? `${d}h ${h}j` : h > 0 ? `${h}j ${m}m` : `${m}m`;
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: root.distro = text().match(/^PRETTY_NAME="?([^"\n]*)"?/m)?.[1] ?? ""
    }

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.host = text().trim()
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = Math.floor(Number(text().split(" ")[0]))
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    Process {
        command: ["getent", "passwd", root.user]
        running: root.user !== ""
        stdout: StdioCollector {
            onStreamFinished: root.realName = (text.split(":")[4] ?? "").split(",")[0]
        }
    }

    Process {
        command: ["sh", "-c", "if command -v pacman >/dev/null; then echo \"$(pacman -Qq | wc -l) (pacman)\"; elif command -v rpm >/dev/null; then echo \"$(rpm -qa | wc -l) (rpm)\"; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.packages = text.trim()
        }
    }
}
