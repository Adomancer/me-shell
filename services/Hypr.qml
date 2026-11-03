pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.utils

// Hyprland 0.55+ memuat ~/.config/hypr/hyprland.lua kalau file itu ada, dan baru memakai hyprland.conf kalau
// tidak ada (dipilih sekali saat Hyprland start). Di mode Lua, "hyprctl dispatch" membaca ekspresi Lua, bukan
// sintaks lama ("workspace 3"), jadi semua dispatch dari shell lewat sini dan dikirim dalam bentuk yang sesuai.
Singleton {
    id: root

    // true = Hyprland sedang memakai config Lua
    readonly property bool lua: luaFile.loaded

    // Kirim satu dispatch; classic = sintaks hyprlang, expr = ekspresi Lua yang sepadan
    function send(classic: string, expr: string): void {
        Hyprland.dispatch(lua ? expr : classic);
    }

    // ws: nomor, atau relatif seperti "r-1" / "r+1"
    function focusWorkspace(ws: var): void {
        send(`workspace ${ws}`, `hl.dsp.focus({ workspace = "${ws}" })`);
    }

    // Pindahkan window ke workspace tanpa ikut pindah (movetoworkspacesilent)
    function moveToWorkspaceSilent(ws: var, address: string): void {
        send(`movetoworkspacesilent ${ws},address:${address}`, `hl.dsp.window.move({ workspace = "${ws}", follow = false, window = "address:${address}" })`);
    }

    function focusWindow(address: string): void {
        send(`focuswindow address:${address}`, `hl.dsp.focus({ window = "address:${address}" })`);
    }

    function toggleFloating(): void {
        send("togglefloating", `hl.dsp.window.float({ action = "toggle" })`);
    }

    // fullscreen 1 = maximize (gap dan bar tetap)
    function toggleMaximize(): void {
        send("fullscreen 1", `hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })`);
    }

    function closeActive(): void {
        send("killactive", "hl.dsp.window.close()");
    }

    function dpms(on: bool): void {
        send(on ? "dpms on" : "dpms off", `hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })`);
    }

    function exit(): void {
        send("exit", "hl.dsp.exit()");
    }

    function submap(name: string): void {
        send(`submap ${name}`, `hl.dsp.submap("${name}")`);
    }

    // Ubah beberapa opsi config sementara (sampai hyprctl reload). Tiap opsi: ["section:key", nilai] untuk
    // hyprlang, dan tabel Lua yang sepadan lewat "hyprctl eval".
    function setOptions(classicPairs: var, luaTable: string): void {
        if (lua)
            Quickshell.execDetached(["hyprctl", "eval", `hl.config(${luaTable})`]);
        else
            Quickshell.execDetached(["hyprctl", "--batch", classicPairs.map(p => `keyword ${p[0]} ${p[1]}`).join(";")]);
    }

    // Dimuat sinkron supaya `lua` sudah benar sebelum dispatch pertama
    FileView {
        id: luaFile

        path: `${Paths.hypr}/hyprland.lua`
        blockLoading: true
        printErrors: false
    }
}
