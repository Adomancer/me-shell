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
    readonly property string fontFamily: adapter.fontFamily
    readonly property string fontSans: adapter.fontSans
    readonly property string fontDisplay: adapter.fontDisplay
    readonly property bool frameEnabled: adapter.frameEnabled
    readonly property int frameThickness: adapter.frameThickness
    readonly property int workspaces: adapter.workspaces
    readonly property string wallpaperDir: Paths.expand(adapter.wallpaperDir)
    readonly property bool renderWallpaper: adapter.renderWallpaper
    readonly property string colorMode: adapter.colorMode
    readonly property bool crtShader: adapter.crtShader
    readonly property string animSpeed: adapter.animSpeed
    readonly property int launcherMaxResults: adapter.launcherMaxResults
    readonly property bool monoIcons: adapter.monoIcons
    readonly property string weatherLocation: adapter.weatherLocation
    readonly property int notifTimeout: adapter.notifTimeout
    readonly property bool cavaEnabled: adapter.cavaEnabled
    readonly property bool barShowMedia: adapter.barShowMedia
    readonly property bool barPopouts: adapter.barPopouts
    readonly property bool barWorkspaceIcons: adapter.barWorkspaceIcons
    readonly property bool hoverOpen: adapter.hoverOpen
    readonly property int idleLockMinutes: adapter.idleLockMinutes
    readonly property int idleScreenOffMinutes: adapter.idleScreenOffMinutes
    readonly property int idleSuspendMinutes: adapter.idleSuspendMinutes
    readonly property int nightLightTemp: adapter.nightLightTemp
    readonly property string screenshotDir: Paths.expand(adapter.screenshotDir)
    readonly property string recordingDir: Paths.expand(adapter.recordingDir)
    readonly property bool recordAudio: adapter.recordAudio
    readonly property bool clipboardHistory: adapter.clipboardHistory
    readonly property bool desktopClock: adapter.desktopClock
    readonly property string desktopClockPosition: adapter.desktopClockPosition
    readonly property bool desktopVisualizer: adapter.desktopVisualizer

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

            property int barHeight: 40
            property bool barShowTitle: true
            property bool barShowTray: true
            property string clockFormat: "hh:mm"
            property string dateFormat: "ddd, dd MMM"
            // Font mono untuk label dan angka kecil; sans untuk teks lain; display (dot-matrix) untuk angka besar
            property string fontFamily: "Space Mono"
            property string fontSans: "Space Grotesk"
            property string fontDisplay: "Doto"
            // Bingkai di sekeliling layar tempat drawer menempel
            property bool frameEnabled: true
            property int frameThickness: 8
            property int workspaces: 5
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property bool renderWallpaper: true
            property string colorMode: "dark"
            property bool crtShader: false
            // "cepat", "normal", "lambat"
            property string animSpeed: "normal"
            property int launcherMaxResults: 8
            // Ikon aplikasi abu-abu di semua tempat, berwarna saat dipilih/aktif
            property bool monoIcons: true
            // Kosong = otomatis dari IP. Contoh: "Jakarta"
            property string weatherLocation: ""
            // Detik sebelum popup notifikasi hilang
            property int notifTimeout: 5
            property bool cavaEnabled: true
            // Lagu yang diputar di bar (kiri jam)
            property bool barShowMedia: true
            // Popout saat kursor di atas ikon bar
            property bool barPopouts: true
            // Ikon aplikasi menggantikan nomor di workspace yang berisi window
            property bool barWorkspaceIcons: false
            // Buka drawer dengan menyentuh tepi/pojok layar
            property bool hoverOpen: true
            // Menit diam sebelum aksi idle; 0 = mati
            property int idleLockMinutes: 10
            property int idleScreenOffMinutes: 15
            property int idleSuspendMinutes: 0
            // Kelvin untuk lampu malam (hyprsunset)
            property int nightLightTemp: 4000
            property string screenshotDir: "~/Pictures/Screenshots"
            property string recordingDir: "~/Videos/Recordings"
            property bool recordAudio: false
            // Riwayat clipboard lewat cliphist
            property bool clipboardHistory: true
            // Widget di atas wallpaper
            property bool desktopClock: true
            // "kiri bawah", "kanan bawah", "kiri atas", "tengah"
            property string desktopClockPosition: "kiri bawah"
            property bool desktopVisualizer: true
        }
    }
}
