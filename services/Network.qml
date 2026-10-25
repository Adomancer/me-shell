pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Status jaringan lewat nmcli (NetworkManager).
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool ethernet: false
    property string ssid: ""
    property int signal: 0
    readonly property bool connected: ssid !== ""

    function refresh(): void {
        radioProc.running = true;
        wifiProc.running = true;
        devProc.running = true;
    }

    function setWifi(on: bool): void {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    Process {
        id: radioProc

        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiProc

        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("yes:"));
                if (line) {
                    const p = line.split(":");
                    root.ssid = p.slice(1, -1).join(":");
                    root.signal = parseInt(p[p.length - 1]) || 0;
                } else {
                    root.ssid = "";
                    root.signal = 0;
                }
            }
        }
    }

    Process {
        id: devProc

        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: root.ethernet = text.split("\n").some(l => l === "ethernet:connected")
        }
    }

    // Refresh setiap kali NetworkManager melaporkan perubahan
    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce

        interval: 500
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
