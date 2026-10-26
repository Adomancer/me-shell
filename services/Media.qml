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
