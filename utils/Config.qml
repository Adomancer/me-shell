pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Config user dari ~/.config/me-shell/config.json (opsional, auto-reload).
// Kalau file tidak ada, nilai default di JsonAdapter yang dipakai. Menu settings menulis lewat set().
Singleton {
    id: root

    readonly property int barHeight: adapter.barHeight
    readonly property bool barShowTitle: adapter.barShowTitle
    readonly property bool barShowTray: adapter.barShowTray
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
    readonly property string animSpeed: adapter.animSpeed
    readonly property int launcherMaxResults: adapter.launcherMaxResults
    readonly property string weatherLocation: adapter.weatherLocation
    readonly property int notifTimeout: adapter.notifTimeout
    readonly property bool cavaEnabled: adapter.cavaEnabled

    // Ubah satu setting lalu simpan ke config.json
    function set(key: string, value: var): void {
        adapter[key] = value;
        file.writeAdapter();
    }

    // Nilai apa adanya (misalnya wallpaperDir sebelum "~" di-expand), untuk ditampilkan di settings
    function raw(key: string): var {
        return adapter[key];
    }

    FileView {
        id: file

        path: `${Paths.config}/config.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property int barHeight: 32
            property bool barShowTitle: true
            property bool barShowTray: true
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
            // "cepat", "normal", "lambat"
            property string animSpeed: "normal"
            property int launcherMaxResults: 8
            // Kosong = otomatis dari IP. Contoh: "Jakarta"
            property string weatherLocation: ""
            // Detik sebelum popup notifikasi hilang
            property int notifTimeout: 5
            property bool cavaEnabled: true
        }
    }
}
