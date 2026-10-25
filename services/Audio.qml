pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setVolume(value: real): void {
        if (!sink?.ready || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic(): void {
        if (source?.ready && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    IpcHandler {
        target: "volume"

        function up(): void {
            root.setVolume(root.volume + 0.05);
        }

        function down(): void {
            root.setVolume(root.volume - 0.05);
        }

        function upPrecise(): void {
            root.setVolume(root.volume + 0.01);
        }

        function downPrecise(): void {
            root.setVolume(root.volume - 0.01);
        }

        function mute(): void {
            root.toggleMute();
        }

        function mic(): void {
            root.toggleMic();
        }
    }
}
