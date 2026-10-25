pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Config user dari ~/.config/me-shell/config.json (opsional, auto-reload).
// Kalau file tidak ada, nilai default di JsonAdapter yang dipakai.
Singleton {
    id: root

    readonly property int barHeight: adapter.barHeight
    readonly property string clockFormat: adapter.clockFormat
    readonly property string dateFormat: adapter.dateFormat
    readonly property bool blinkCursor: adapter.blinkCursor
    readonly property string fontFamily: adapter.fontFamily
    readonly property int workspaces: adapter.workspaces
    readonly property string wallpaperDir: Paths.expand(adapter.wallpaperDir)
    readonly property bool renderWallpaper: adapter.renderWallpaper
    readonly property string colorMode: adapter.colorMode
    readonly property bool crtShader: adapter.crtShader
    readonly property bool pixelArt: adapter.pixelArt
    readonly property int launcherMaxResults: adapter.launcherMaxResults

    FileView {
        path: `${Paths.config}/config.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property int barHeight: 32
            property string clockFormat: "hh:mm"
            property string dateFormat: "ddd, dd MMM"
            property bool blinkCursor: true
            property string fontFamily: "JetBrains Mono"
            property int workspaces: 5
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property bool renderWallpaper: true
            property string colorMode: "dark"
            property bool crtShader: false
            property bool pixelArt: true
            property int launcherMaxResults: 8
        }
    }
}
