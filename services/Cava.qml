pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Visualizer audio dari cava (output raw ASCII, config di assets/cava/config).
// Hanya jalan saat ada yang memakai (users > 0) dan lagu sedang diputar.
Singleton {
    id: root

    // Harus sama dengan "bars" di assets/cava/config
    readonly property int bars: 32
    // UI menambah/mengurangi ini, misalnya saat tab MEDIA terbuka
    property int users: 0
    property bool available: false
    // Nilai 0..1 per batang; kosong saat tidak jalan
    property var values: []

    Process {
        command: ["sh", "-c", "command -v cava"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc

        command: ["cava", "-p", `${Paths.shell}/assets/cava/config`]
        running: root.available && root.users > 0 && Media.playing
        onRunningChanged: {
            if (!running)
                root.values = [];
        }
        stdout: SplitParser {
            onRead: data => root.values = data.split(";").filter(s => s !== "").map(v => Number(v) / 100)
        }
    }
}
