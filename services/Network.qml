pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// Status jaringan lewat nmcli (NetworkManager).
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool ethernet: false
    property string ssid: ""
    property int signal: 0
    readonly property bool connected: ssid !== ""
    // [{ ssid, signal, secure, active, known }], diisi scan()
    property var networks: []
    property bool scanning: false
    // SSID yang sedang disambungkan, "" kalau tidak ada
    property string connecting: ""
    // SSID yang gagal karena password salah/kosong; UI menampilkan kolom password
    property string needsPassword: ""

    function refresh(): void {
        radioProc.running = true;
        wifiProc.running = true;
        devProc.running = true;
    }

    function setWifi(on: bool): void {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    function scan(): void {
        if (!wifiEnabled || listProc.running)
            return;
        scanning = true;
        listProc.running = true;
    }

    // password kosong = pakai profil tersimpan (atau jaringan terbuka)
    function connect(ssid: string, password: string): void {
        const net = networks.find(n => n.ssid === ssid);
        connecting = ssid;
        needsPassword = "";
        if (password)
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        else if (net?.known)
            connectProc.command = ["nmcli", "con", "up", "id", ssid];
        else
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    function disconnect(ssid: string): void {
        Quickshell.execDetached(["nmcli", "con", "down", "id", ssid]);
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
                    root.ssid = p.slice(1, -1).join(":").replace(/\\:/g, ":");
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

    // SSID di kolom terakhir karena boleh berisi ":" (di-escape "\:" oleh nmcli)
    Process {
        id: listProc

        command: ["sh", "-c", "nmcli -t -f NAME,TYPE connection show | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//'; echo ---; nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [knownPart, listPart] = text.split("---\n");
                const known = (knownPart ?? "").split("\n").filter(l => l);
                const seen = {};
                const out = [];
                for (const line of (listPart ?? "").split("\n")) {
                    const p = line.split(":");
                    if (p.length < 4)
                        continue;
                    const ssid = p.slice(3).join(":").replace(/\\:/g, ":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    out.push({
                        ssid,
                        active: p[0] === "*",
                        signal: parseInt(p[1]) || 0,
                        secure: p[2] !== "" && p[2] !== "--",
                        known: known.includes(ssid)
                    });
                }
                root.networks = out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.scanning = false;
            }
        }
    }

    Process {
        id: connectProc

        stderr: StdioCollector {
            id: connectErr
        }
        onExited: code => {
            const ssid = root.connecting;
            root.connecting = "";
            if (code === 0) {
                Toaster.show("wifi", "Wi-Fi tersambung", ssid, "");
            } else if (/secret|password|802-1x|psk/i.test(connectErr.text)) {
                root.needsPassword = ssid;
            } else {
                Toaster.show("wifi_off", "Gagal menyambung", ssid, "");
            }
            root.scan();
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
