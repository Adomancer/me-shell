pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Drawer mana yang terbuka ("panel", "launcher", "session") dan di monitor mana.
Singleton {
    id: root

    property string active: ""
    property string screen: ""
    // Tab control panel yang aktif ("dash", "media", "perf", "weather", "notif")
    property string panelTab: "dash"
    // Teks awal launcher saat dibuka, misalnya ":" untuk mode wallpaper
    property string launcherQuery: ""

    // Buka panel di tab tertentu; tutup kalau tab itu sedang terbuka
    function togglePanel(tab: string): void {
        if (active === "panel" && panelTab === tab) {
            close();
            return;
        }
        panelTab = tab;
        if (active !== "panel")
            open("panel");
    }

    function toggleLauncher(query: string): void {
        if (active === "launcher") {
            close();
            return;
        }
        launcherQuery = query;
        open("launcher");
    }

    function open(name: string): void {
        screen = Hyprland.focusedMonitor?.name ?? "";
        active = name;
    }

    function close(): void {
        active = "";
    }

    function toggle(name: string): void {
        if (active === name)
            close();
        else
            open(name);
    }

    IpcHandler {
        target: "drawers"

        function toggle(name: string): void {
            root.toggle(name);
        }

        function open(name: string): void {
            root.open(name);
        }

        function close(): void {
            root.close();
        }

        function panel(tab: string): void {
            root.togglePanel(tab);
        }

        function launcher(query: string): void {
            root.toggleLauncher(query);
        }
    }
}
