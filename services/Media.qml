pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import qs.services

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Prioritaskan player yang sedang memutar
    readonly property MprisPlayer active: players.find(p => p.playbackState === MprisPlaybackState.Playing) ?? players[0] ?? null
    readonly property bool playing: active?.playbackState === MprisPlaybackState.Playing
    readonly property real length: active?.length ?? 0
    // Dibatasi durasi: player yang mengulang lagu bisa melaporkan posisi melewati durasi
    readonly property real position: Math.max(0, length > 0 ? Math.min(active?.position ?? 0, length) : active?.position ?? 0)
    readonly property real progress: length > 0 ? position / length : 0

    // 75 -> "1:15", 3725 -> "1:02:05"
    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
    }

    // Ada yang sedang menampilkan posisi lagu (dashboard, popout media, lockscreen)
    readonly property bool watched: DrawerState.active === "panel" || DrawerState.popout === "media" || Session.locked

    // Posisi MPRIS tidak update sendiri, harus dipicu; hanya selama ada yang melihat
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.playing && root.watched
        onTriggered: root.active?.positionChanged()
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            root.active?.togglePlaying();
        }

        function next(): void {
            root.active?.next();
        }

        function previous(): void {
            root.active?.previous();
        }

        function stop(): void {
            root.active?.stop();
        }
    }
}
