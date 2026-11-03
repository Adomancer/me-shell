pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils
import "../utils/Keybinds.js" as KB

// Keybind shell, dipecah ala JaKooLit di ~/.config/me-shell/hypr/. Dua mode, ditentukan dari config Hyprland yang aktif:
//   Lua (Hyprland >= 0.55):
//     me-shell.lua   di-require dari hyprland.lua (ditulis ulang setiap start)
//     keybinds.lua   dibuat dari daftar di bawah + perubahan dari menu settings
//     user.lua       milik user, hanya dibuat kalau belum ada
//   Legacy (hyprlang, < 0.55): me-shell.conf, keybinds.conf, user.conf dengan peran yang sama
// Perubahan dari settings disimpan di ~/.config/me-shell/keybinds.json.
Singleton {
    id: root

    readonly property string dir: `${Paths.config}/hypr`
    readonly property string ipc: "qs -c me-shell ipc call"
    // "" = belum dicek, "lua" atau "legacy"
    property string mode: ""
    readonly property bool lua: mode === "lua"

    // Bisa diubah dari menu settings. Default mengikuti JaKooLit.
    readonly property var defaults: [
        {
            id: "launcher",
            label: "Launcher",
            mods: "SUPER",
            key: "D",
            cmd: "drawers toggle launcher"
        },
        {
            id: "wallpaper",
            label: "Launcher mode wallpaper",
            mods: "SUPER",
            key: "W",
            cmd: "drawers launcher :"
        },
        {
            id: "panel",
            label: "Control panel (DASH)",
            mods: "SUPER SHIFT",
            key: "E",
            cmd: "drawers panel dash"
        },
        {
            id: "notifs",
            label: "Control panel (NOTIF)",
            mods: "SUPER SHIFT",
            key: "N",
            cmd: "drawers panel notif"
        },
        {
            id: "settings",
            label: "Settings",
            mods: "SUPER",
            key: "I",
            cmd: "drawers toggle settings"
        },
        {
            id: "overview",
            label: "Overview workspace",
            mods: "SUPER",
            key: "TAB",
            cmd: "drawers toggle overview"
        },
        {
            id: "utilities",
            label: "Utilitas",
            mods: "SUPER",
            key: "A",
            cmd: "drawers toggle utilities"
        },
        {
            id: "clipboard",
            label: "Riwayat clipboard",
            mods: "SUPER",
            key: "V",
            cmd: "drawers launcher ';'"
        },
        {
            id: "emoji",
            label: "Pemilih emoji",
            mods: "SUPER",
            key: "PERIOD",
            cmd: "drawers launcher ."
        },
        {
            id: "screenshot",
            label: "Screenshot area / window",
            mods: "SUPER SHIFT",
            key: "S",
            cmd: "picker open"
        },
        {
            id: "screenshotFull",
            label: "Screenshot layar penuh",
            mods: "",
            key: "Print",
            cmd: "picker screen"
        },
        {
            id: "record",
            label: "Rekam layar (mulai/berhenti)",
            mods: "SUPER SHIFT",
            key: "R",
            cmd: "recorder region"
        },
        {
            id: "colorPicker",
            label: "Ambil warna dari layar",
            mods: "SUPER SHIFT",
            key: "C",
            cmd: "picker color"
        },
        {
            id: "ocr",
            label: "Salin teks dari layar (OCR)",
            mods: "SUPER SHIFT",
            key: "T",
            cmd: "picker ocr"
        },
        {
            id: "cheatsheet",
            label: "Daftar keybind",
            mods: "SUPER",
            key: "SLASH",
            cmd: "drawers toggle cheatsheet"
        },
        {
            id: "session",
            label: "Session menu",
            mods: "CTRL ALT",
            key: "P",
            cmd: "drawers toggle session"
        },
        {
            id: "lock",
            label: "Lockscreen",
            mods: "CTRL ALT",
            key: "L",
            cmd: "lock lock"
        }
    ]

    // Tombol khusus keyboard, tidak diubah dari settings: [jenis bind, mods, key, perintah]
    readonly property var fixed: [
        ["bindel", "", "XF86AudioRaiseVolume", "volume up"],
        ["bindel", "", "XF86AudioLowerVolume", "volume down"],
        ["bindel", "ALT", "XF86AudioRaiseVolume", "volume upPrecise"],
        ["bindel", "ALT", "XF86AudioLowerVolume", "volume downPrecise"],
        ["bindl", "", "XF86AudioMute", "volume mute"],
        ["bindl", "", "XF86AudioMicMute", "volume mic"],

        ["bindl", "", "XF86AudioPause", "media playPause"],
        ["bindl", "", "XF86AudioPlay", "media playPause"],
        ["bindl", "", "XF86AudioNext", "media next"],
        ["bindl", "", "XF86AudioPrev", "media previous"],
        ["bindl", "", "XF86AudioStop", "media stop"],
        ["bindel", "", "XF86MonBrightnessUp", "brightness up"],
        ["bindel", "", "XF86MonBrightnessDown", "brightness down"],
        // bindn: tombol tetap sampai ke aplikasi, shell hanya ikut membaca status lock untuk toast
        ["bindn", "", "Caps_Lock", "keyboard locks"],
        ["bindn", "", "Num_Lock", "keyboard locks"]
    ]

    // Daftar yang sedang dipakai: default + perubahan dari keybinds.json
    readonly property var binds: defaults.map(d => Object.assign({}, d, adapter.overrides[d.id] ?? {}))
    // true = ada perubahan yang belum ditulis ke keybinds.lua / keybinds.conf
    property bool dirty: false

    function setBind(id: string, mods: string, key: string): void {
        const o = Object.assign({}, adapter.overrides);
        o[id] = {
            mods,
            key
        };
        adapter.overrides = o;
        store.writeAdapter();
        dirty = true;
    }

    function resetAll(): void {
        adapter.overrides = {};
        store.writeAdapter();
        dirty = true;
    }

    function generate(): string {
        const lines = ["# Dibuat otomatis oleh me-shell dari menu settings. Jangan diedit, pakai user.conf.", `$meshell = ${ipc}`, ""];
        for (const b of binds)
            lines.push(`bind = ${b.mods}, ${b.key}, exec, $meshell ${b.cmd}`);
        lines.push("");
        for (const f of fixed)
            lines.push(`${f[0]} = ${f[1]}, ${f[2]}, exec, $meshell ${f[3]}`);
        return lines.join("\n") + "\n";
    }

    function generateLua(): string {
        return KB.luaKeybinds(binds, fixed, ipc);
    }

    function mainLua(): string {
        return KB.luaMain(dir);
    }

    function mainConf(): string {
        return [
            "# Dibuat oleh me-shell, ditulis ulang setiap shell start. Tambahkan di hyprland.conf:",
            `#   source = ${dir}/me-shell.conf`,
            "",
            "exec-once = qs -c me-shell",
            "",
            "# Aplikasi Electron/Chromium (VS Code, Discord, Brave) jalan native di Wayland, tidak buram lewat XWayland",
            "env = ELECTRON_OZONE_PLATFORM_HINT,auto",
            "",
            "misc {",
            "    allow_session_lock_restore = true",
            "}",
            "",
            `source = ${dir}/keybinds.conf`,
            `source = ${dir}/user.conf`,
            "",
            "# Submap kosong: dipakai menu settings saat merekam kombinasi tombol baru",
            "submap = me-shell-capture",
            "bindn = , escape, submap, reset",
            "submap = reset",
            ""
        ].join("\n");
    }

    // Tulis keybinds.lua (atau keybinds.conf di mode legacy) lalu reload Hyprland
    function apply(): void {
        if (lua)
            writer.write([["w", "keybinds.lua", generateLua()]], true);
        else
            writer.write([["w", "keybinds.conf", generate()]], true);
        dirty = false;
    }

    // Selama merekam, matikan keybind lain supaya tombolnya sampai ke shell.
    // Mode Lua: `hyprctl dispatch` mengeksekusi kode Lua, bukan lagi "submap nama".
    function startCapture(): void {
        Quickshell.execDetached(lua ? ["hyprctl", "dispatch", 'hl.dsp.submap("me-shell-capture")'] : ["hyprctl", "dispatch", "submap", "me-shell-capture"]);
    }

    function endCapture(): void {
        Quickshell.execDetached(lua ? ["hyprctl", "dispatch", 'hl.dsp.submap("reset")'] : ["hyprctl", "dispatch", "submap", "reset"]);
    }

    // Ubah event keyboard Qt jadi kombinasi Hyprland; null kalau cuma tombol modifier
    function comboOf(event: var): var {
        const k = event.key;
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].includes(k))
            return null;
        const mods = [];
        if (event.modifiers & Qt.MetaModifier)
            mods.push("SUPER");
        if (event.modifiers & Qt.ControlModifier)
            mods.push("CTRL");
        if (event.modifiers & Qt.AltModifier)
            mods.push("ALT");
        if (event.modifiers & Qt.ShiftModifier)
            mods.push("SHIFT");
        let key = "";
        if ((k >= Qt.Key_A && k <= Qt.Key_Z) || (k >= Qt.Key_0 && k <= Qt.Key_9))
            key = String.fromCharCode(k);
        else if (k >= Qt.Key_F1 && k <= Qt.Key_F12)
            key = `F${k - Qt.Key_F1 + 1}`;
        else
            key = ({
                    [Qt.Key_Space]: "SPACE",
                    [Qt.Key_Return]: "RETURN",
                    [Qt.Key_Tab]: "TAB",
                    [Qt.Key_Backspace]: "BACKSPACE",
                    [Qt.Key_Delete]: "DELETE",
                    [Qt.Key_Print]: "Print",
                    [Qt.Key_Left]: "LEFT",
                    [Qt.Key_Right]: "RIGHT",
                    [Qt.Key_Up]: "UP",
                    [Qt.Key_Down]: "DOWN",
                    [Qt.Key_Period]: "PERIOD",
                    [Qt.Key_Comma]: "COMMA",
                    [Qt.Key_Slash]: "SLASH"
                })[k] ?? event.text.toUpperCase();
        return key ? {
            mods: mods.join(" "),
            key
        } : null;
    }

    FileView {
        id: store

        path: `${Paths.config}/keybinds.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // { "<id>": { "mods": "SUPER", "key": "D" } }
            property var overrides: ({})
        }
    }

    // Menulis file di folder hypr/ (mkdir dulu), semuanya dalam satu proses supaya reload
    // selalu terjadi setelah semua file siap. files: [["w" (timpa) | "n" (hanya kalau belum ada), nama, isi]]
    QtObject {
        id: writer

        function write(files: var, reload: bool): void {
            const script = 'd="$1"; shift; mkdir -p "$d" || exit 1; while [ $# -ge 3 ]; do if [ "$1" = w ] || [ ! -e "$d/$2" ]; then printf "%s" "$3" > "$d/$2"; fi; shift 3; done' + (reload ? "; hyprctl reload" : "");
            Quickshell.execDetached(["sh", "-c", script, "sh", root.dir].concat(files.flat()));
        }
    }

    // Config Hyprland yang aktif: Lua (>= 0.55) atau hyprlang. Kalau hyprctl tidak menjawab
    // (bukan sesi Hyprland), ikuti keberadaan hyprland.lua.
    Process {
        id: detect

        command: ["sh", "-c", 'p="$(hyprctl systeminfo 2>/dev/null | grep -i configProvider)"; case "$p" in *lua*) echo lua ;; "") [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua" ] && echo lua || echo legacy ;; *) echo legacy ;; esac']
        stdout: StdioCollector {
            onStreamFinished: {
                root.mode = text.trim() === "lua" ? "lua" : "legacy";
                root.writeFiles();
            }
        }
    }

    function writeFiles(): void {
        // reload supaya keybind langsung aktif pada start pertama
        if (lua)
            writer.write([["w", "me-shell.lua", mainLua()], ["n", "user.lua", KB.LUA_USER_STUB], ["w", "keybinds.lua", generateLua()]], true);
        else
            writer.write([["w", "me-shell.conf", mainConf()], ["n", "user.conf", "# Keybind dan setting Hyprland milikmu sendiri. me-shell tidak pernah menimpa file ini.\n"], ["w", "keybinds.conf", generate()]], true);
    }

    // Dipanggil dari shell.qml saat start supaya file-file hypr/ selalu ada
    function ensureFiles(): void {
        detect.running = true;
    }
}
