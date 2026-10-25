pragma Singleton

import Quickshell
import QtQuick
import qs.services

// Popup volume/brightness. Muncul otomatis saat volume berubah.
Singleton {
    id: root

    property bool shown: false
    property string kind: "volume"
    // Abaikan perubahan saat startup (Pipewire baru siap)
    property bool ready: false
    // Selama kursor di atas OSD, jangan disembunyikan
    property bool held: false

    function show(k: string): void {
        if (!ready || DrawerState.active === "panel")
            return;
        kind = k;
        shown = true;
        if (!held)
            hideTimer.restart();
    }

    function hold(): void {
        held = true;
        hideTimer.stop();
    }

    function release(): void {
        held = false;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.shown = false
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show("volume");
        }

        function onMutedChanged(): void {
            root.show("volume");
        }
    }
}
