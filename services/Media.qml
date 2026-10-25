pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Prioritaskan player yang sedang memutar
    readonly property MprisPlayer active: players.find(p => p.playbackState === MprisPlaybackState.Playing) ?? players[0] ?? null
    readonly property bool playing: active?.playbackState === MprisPlaybackState.Playing

    // Posisi MPRIS tidak update sendiri, harus dipicu
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
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
