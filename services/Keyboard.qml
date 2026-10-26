pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.services

// Layout keyboard dan status Caps/Num Lock, dengan toast saat berubah (ide dari toast Caelestia).
// Layout datang dari event Hyprland; tombol lock dipicu bindn di keybinds.conf lalu dibaca dari hyprctl.
Singleton {
    id: root

    property string layout: ""
    property bool capsLock: false
    property bool numLock: false
    // Status lock pertama hanya dicatat, tidak di-toast
    property bool known: false

    function refreshLocks(): void {
        locks.running = true;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name !== "activelayout")
                return;
            // "nama-keyboard,nama layout"; setiap keyboard mengirim event, jadi abaikan yang sama
            const name = event.data.split(",").slice(1).join(",");
            if (name && name !== root.layout) {
                if (root.layout !== "")
                    Toaster.show("keyboard", "Layout keyboard", name, "");
                root.layout = name;
            }
        }
    }

    Process {
        id: locks

        // Jeda sebentar: bindn jalan saat tombol ditekan, sebelum status LED berubah
        command: ["sh", "-c", "sleep 0.15; hyprctl devices -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kb;
                try {
                    const list = JSON.parse(text).keyboards ?? [];
                    kb = list.find(k => k.main) ?? list[0];
                } catch (e) {
                    return;
                }
                if (!kb)
                    return;
                if (root.known && kb.capsLock !== root.capsLock)
                    Toaster.show("keyboard_capslock", kb.capsLock ? "Caps Lock nyala" : "Caps Lock mati", "", "");
                if (root.known && kb.numLock !== root.numLock)
                    Toaster.show("dialpad", kb.numLock ? "Num Lock nyala" : "Num Lock mati", "", "");
                root.capsLock = kb.capsLock;
                root.numLock = kb.numLock;
                root.known = true;
                if (!root.layout)
                    root.layout = kb.active_keymap ?? "";
            }
        }
    }

    Component.onCompleted: refreshLocks()

    IpcHandler {
        target: "keyboard"

        function locks(): void {
            root.refreshLocks();
        }
    }
}
