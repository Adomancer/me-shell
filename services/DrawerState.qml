pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Drawer mana yang terbuka ("panel", "launcher", "session", "utilities", "settings", "cheatsheet", "overview",
// "popout") dan di monitor mana.
Singleton {
    id: root

    property string active: ""
    property string screen: ""
    // Tab control panel yang aktif ("dash", "media", "perf", "weather", "notif")
    property string panelTab: "dash"
    // Teks awal launcher saat dibuka, misalnya ":" untuk mode wallpaper
    property string launcherQuery: ""
    // true = drawer dibuka dengan hover tepi layar; tertutup lagi saat kursor pergi
    property bool hoverOpened: false

    // Popout bar: nama isi ("network", "audio", ...), titik tengah pemicu, dan monitornya.
    // Muncul saat hover; klik pemicu menyematkannya (active = "popout") supaya bisa diketik.
    property string popout: ""
    property real popoutX: 0
    property string popoutScreen: ""
    readonly property bool popoutPinned: active === "popout"

    // Buka panel di tab tertentu; tutup kalau tab itu sedang terbuka
    function togglePanel(tab: string): void {
        // Panel yang terbuka karena hover: klik = sematkan, bukan tutup
        if (active === "panel" && hoverOpened) {
            hoverOpened = false;
            panelTab = tab;
            return;
        }
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
        hoverOpened = false;
        popout = "";
    }

    function close(): void {
        active = "";
        hoverOpened = false;
        popout = "";
    }

    function toggle(name: string): void {
        if (active === name)
            close();
        else
            open(name);
    }

    // Dibuka dari hover tepi layar; tidak menimpa drawer yang dibuka dengan sengaja
    function hoverOpen(name: string, screenName: string): void {
        if (active !== "" && !hoverOpened)
            return;
        screen = screenName;
        active = name;
        popout = "";
        hoverOpened = true;
        hoverClose.stop();
    }

    function hoverLeave(): void {
        if (hoverOpened)
            hoverClose.restart();
    }

    function hoverHold(): void {
        hoverClose.stop();
    }

    function showPopout(name: string, x: real, screenName: string): void {
        // Drawer lain yang dibuka sengaja menang; popout yang disematkan tidak diganti hover
        if ((active !== "" && active !== "popout" && !hoverOpened) || (popoutPinned && popout !== name))
            return;
        if (hoverOpened)
            close();
        popout = name;
        popoutX = x;
        popoutScreen = screenName;
        popoutClose.stop();
    }

    // name = popout yang ditinggalkan; abaikan kalau popout lain sudah keburu muncul (pindah ikon)
    function leavePopout(name: string): void {
        if (!popoutPinned && popout === name)
            popoutClose.restart();
    }

    function holdPopout(): void {
        popoutClose.stop();
    }

    // Klik pemicu: sematkan (fokus keyboard + klik di luar menutup); klik lagi = tutup
    function pinPopout(name: string, x: real, screenName: string): void {
        if (popoutPinned && popout === name) {
            close();
            return;
        }
        popout = name;
        popoutX = x;
        popoutScreen = screenName;
        screen = screenName;
        active = "popout";
        hoverOpened = false;
        popoutClose.stop();
    }

    Timer {
        id: popoutClose

        interval: 300
        onTriggered: {
            if (!root.popoutPinned)
                root.popout = "";
        }
    }

    Timer {
        id: hoverClose

        interval: 400
        onTriggered: {
            if (root.hoverOpened)
                root.close();
        }
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

        // Untuk skrip dan debug
        function state(): string {
            return JSON.stringify({
                active: root.active,
                screen: root.screen,
                popout: root.popout,
                pinned: root.popoutPinned,
                hoverOpened: root.hoverOpened
            });
        }
    }
}
