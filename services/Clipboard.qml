pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Riwayat clipboard lewat cliphist. Shell sendiri yang menjalankan `wl-paste --watch cliphist store`,
// jadi tidak perlu exec-once di config Hyprland. setpriv memastikan watcher ikut mati kalau shell mati.
Singleton {
    id: root

    property bool available: false
    // [{ line, id, text, image }]; line = baris asli dari `cliphist list`
    property var entries: []
    readonly property bool watching: Config.clipboardHistory && available

    function refresh(): void {
        if (available)
            listProc.running = true;
    }

    function copy(line: string): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", line]);
    }

    function remove(line: string): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", line]);
        entries = entries.filter(e => e.line !== line);
    }

    function wipe(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    Process {
        command: ["sh", "-c", "command -v cliphist && command -v wl-paste"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", "cliphist", "store"]
        running: root.watching
    }

    Process {
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image", "--watch", "cliphist", "store"]
        running: root.watching
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l.includes("\t")).slice(0, 100).map(l => {
                    const tab = l.indexOf("\t");
                    const body = l.slice(tab + 1);
                    return {
                        line: l,
                        id: l.slice(0, tab),
                        text: body,
                        image: body.startsWith("[[ binary data")
                    };
                })
        }
    }
}
