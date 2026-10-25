pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Status Bluetooth lewat bluetoothctl (BlueZ).
Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property var devices: []

    function refresh(): void {
        showProc.running = true;
        devProc.running = true;
    }

    function toggle(): void {
        Quickshell.execDetached(["bluetoothctl", "power", enabled ? "off" : "on"]);
        enabled = !enabled;
        later.restart();
    }

    Process {
        id: showProc

        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.includes("Controller");
                root.enabled = /Powered:\s*yes/.test(text);
            }
        }
    }

    Process {
        id: devProc

        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: root.devices = text.split("\n").filter(l => l.startsWith("Device ")).map(l => l.split(" ").slice(2).join(" "))
        }
    }

    Timer {
        id: later

        interval: 1500
        onTriggered: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
