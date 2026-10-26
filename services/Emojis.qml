pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// [[emoji, nama]] dari assets/emoji.txt. Dimuat sekali saat pertama dipakai, dibagi semua monitor.
Singleton {
    id: root

    property var list: []

    FileView {
        path: `${Paths.shell}/assets/emoji.txt`
        onLoaded: root.list = text().split("\n").filter(l => l.includes("\t")).map(l => l.split("\t"))
    }
}
