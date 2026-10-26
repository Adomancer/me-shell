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

    // Perangkat output/input, dan aplikasi yang sedang memutar suara
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    // Semua stream dilacak supaya properties terisi; lalu stream rekaman (Stream/Input/Audio) dibuang.
    // Tracker sengaja tidak memakai `streams` supaya tidak jadi binding loop.
    readonly property var allStreams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    readonly property var streams: allStreams.filter(n => n.properties["media.class"] !== "Stream/Input/Audio")

    function setVolume(value: real): void {
        if (!sink?.ready || !sink.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setNodeVolume(node: PwNode, value: real): void {
        if (!node?.ready || !node.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic(): void {
        if (source?.ready && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Nama yang enak dibaca untuk perangkat atau aplikasi
    function nameOf(node: PwNode): string {
        if (!node)
            return "";
        if (node.isStream)
            return node.properties["application.name"] || node.description || node.name;
        return node.description || node.nickname || node.name;
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.allStreams].filter(n => n)
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
