pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Config user dari ~/.config/me-shell/config.json (opsional, auto-reload).
// Kalau file tidak ada, nilai default di JsonAdapter yang dipakai.
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/me-shell`

    readonly property int barHeight: adapter.barHeight
    readonly property string clockFormat: adapter.clockFormat
    readonly property string dateFormat: adapter.dateFormat

    FileView {
        path: `${root.dir}/config.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property int barHeight: 32
            property string clockFormat: "hh:mm"
            property string dateFormat: "ddd, dd MMM"
        }
    }
}
