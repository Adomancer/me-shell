// Konversi keybind me-shell ke Lua Hyprland (>= 0.55), dipakai services/Keybinds.qml dan tes Node.
// Sintaks: hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("..."), { locked = true }).
// Nama tombol harus nama keysym xkb; karakter tunggal seperti "-" atau "," ditolak Hyprland.

// Karakter tunggal -> nama keysym xkb (Hyprland Lua tidak menerima karakter mentah)
var LUA_KEYSYMS = {
    "-": "minus",
    "+": "plus",
    "=": "equal",
    ",": "comma",
    ".": "period",
    "/": "slash",
    ";": "semicolon",
    "'": "apostrophe",
    "`": "grave",
    "[": "bracketleft",
    "]": "bracketright",
    "\\": "backslash",
    "!": "exclam",
    "@": "at",
    "#": "numbersign",
    "$": "dollar",
    "%": "percent",
    "^": "asciicircum",
    "&": "ampersand",
    "*": "asterisk",
    "(": "parenleft",
    ")": "parenright",
    "_": "underscore",
    "{": "braceleft",
    "}": "braceright",
    "|": "bar",
    ":": "colon",
    "\"": "quotedbl",
    "<": "less",
    ">": "greater",
    "?": "question",
    "~": "asciitilde"
};

// Huruf flag Hyprlang (bindl, bindel, ...) -> opsi hl.bind, dalam urutan tetap
var LUA_FLAGS = [["l", "locked"], ["e", "repeating"], ["n", "non_consuming"], ["r", "release"], ["t", "transparent"], ["m", "mouse"]];

function luaString(text) {
    var out = "";
    for (var i = 0; i < text.length; i++) {
        var c = text[i];
        var code = text.charCodeAt(i);
        if (c === "\\")
            out += "\\\\";
        else if (c === "\"")
            out += "\\\"";
        else if (c === "\n")
            out += "\\n";
        else if (c === "\r")
            out += "\\r";
        else if (c === "\t")
            out += "\\t";
        else if (code < 32 || code === 127)
            out += "\\" + ("00" + code).slice(-3);
        else
            out += c;
    }
    return "\"" + out + "\"";
}

function luaKeyName(key) {
    return Object.prototype.hasOwnProperty.call(LUA_KEYSYMS, key) ? LUA_KEYSYMS[key] : key;
}

// ("SUPER SHIFT", "E") -> "SUPER + SHIFT + E"; mods boleh kosong
function luaKeys(mods, key) {
    var parts = String(mods || "").split(/\s+/).filter(function (m) {
        return m;
    });
    parts.push(luaKeyName(key));
    return parts.join(" + ");
}

// "bindel" -> ["locked", "repeating"]; jenis bind yang tidak dikenal dianggap salah, bukan diabaikan
function luaFlagNames(kind) {
    var m = /^bind([a-z]*)$/.exec(kind);
    if (!m)
        throw new Error("Jenis bind tidak dikenal: " + kind);
    var letters = m[1];
    var names = [];
    LUA_FLAGS.forEach(function (f) {
        if (letters.indexOf(f[0]) >= 0)
            names.push(f[1]);
    });
    if (names.length !== letters.length)
        throw new Error("Flag bind tidak didukung: " + kind);
    return names;
}

function luaBind(kind, mods, key, cmd) {
    var flags = luaFlagNames(kind);
    var action;
    if (flags.indexOf("mouse") >= 0) {
        if (cmd === "movewindow")
            action = "hl.dsp.window.drag()";
        else if (cmd === "resizewindow")
            action = "hl.dsp.window.resize()";
        else
            throw new Error("Aksi mouse tidak dikenal: " + cmd);
    } else {
        action = "hl.dsp.exec_cmd(meshell .. " + luaString(" " + cmd) + ")";
    }
    var opts = flags.length ? ", { " + flags.map(function (f) {
        return f + " = true";
    }).join(", ") + " }" : "";
    return "hl.bind(" + luaString(luaKeys(mods, key)) + ", " + action + opts + ")";
}

// binds: [{ mods, key, cmd }] (bind biasa); fixed: [[jenis, mods, key, cmd]]
function luaKeybinds(binds, fixed, ipc) {
    var lines = ["-- Dibuat otomatis oleh me-shell dari menu settings. Jangan diedit, pakai user.lua.", "local meshell = " + luaString(ipc), ""];
    binds.forEach(function (b) {
        lines.push(luaBind("bind", b.mods, b.key, b.cmd));
    });
    lines.push("");
    fixed.forEach(function (f) {
        lines.push(luaBind(f[0], f[1], f[2], f[3]));
    });
    return lines.join("\n") + "\n";
}

// File yang di-require dari hyprland.lua. Harus sama persis dengan yang ditulis scripts/me-shell (dicek di tes).
function luaMain(dir) {
    return [
        "-- Dibuat oleh me-shell, ditulis ulang setiap shell start. Jangan diedit; pakai user.lua.",
        "-- hyprland.lua memuatnya lewat blok bertanda \"me-shell\" (pcall(require, ...)).",
        "",
        "-- Urutan penting: environment dibagikan ke D-Bus dulu supaya xdg-desktop-portal bisa start, baru shell jalan",
        "hl.on(\"hyprland.start\", function()",
        "    hl.exec_cmd(\"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP; exec qs -c me-shell\")",
        "end)",
        "",
        "-- Aplikasi Electron/Chromium (VS Code, Discord, Brave) jalan native di Wayland, tidak buram lewat XWayland",
        "hl.env(\"ELECTRON_OZONE_PLATFORM_HINT\", \"auto\")",
        "",
        "-- Kalau shell crash saat layar terkunci, opsi ini yang membuat lockscreen bisa kembali",
        "hl.config({",
        "    misc = {",
        "        allow_session_lock_restore = true,",
        "    },",
        "})",
        "",
        "require(" + luaString(dir + "/keybinds") + ")",
        "require(" + luaString(dir + "/user") + ")",
        "",
        "-- Submap kosong: dipakai menu settings saat merekam kombinasi tombol baru",
        "hl.define_submap(\"me-shell-capture\", function()",
        "    hl.bind(\"escape\", hl.dsp.submap(\"reset\"), { non_consuming = true })",
        "end)",
        ""
    ].join("\n");
}

var LUA_USER_STUB = "-- Keybind dan setting Hyprland milikmu sendiri. me-shell tidak pernah menimpa file ini.\n";
var LUA_KEYBINDS_STUB = "-- Diisi otomatis oleh me-shell saat start\n";
