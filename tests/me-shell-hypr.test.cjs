const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const { spawnSync } = require('node:child_process');
const { haveHyprland, tmpdir, verifyLua } = require('./hypr-helpers.cjs');

const script = path.join(__dirname, '../scripts/me-shell');
const kb = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../utils/Keybinds.js'), 'utf8'), kb);

// Rumah palsu per tes. scripts/me-shell di-source (tidak menjalankan perintah apa pun) dan fungsinya
// dipanggil langsung; stop_shell/pkill sengaja tidak pernah dipanggil supaya shell yang sedang jalan aman.
function sandbox(hyprVersion) {
    const home = tmpdir();
    const bin = path.join(home, 'stubbin');
    fs.mkdirSync(bin);
    if (hyprVersion) {
        fs.writeFileSync(path.join(bin, 'Hyprland'), `#!/bin/sh\necho "Hyprland ${hyprVersion} built from branch test"\n`, { mode: 0o755 });
    }
    const conf = path.join(home, '.config');
    fs.mkdirSync(path.join(conf, 'hypr'), { recursive: true });
    const run = (code, extraEnv = {}) => {
        const env = {
            PATH: `${bin}:/usr/bin:/bin`,
            HOME: home,
            XDG_CONFIG_HOME: conf,
            XDG_DATA_HOME: path.join(home, '.local/share'),
            XDG_STATE_HOME: path.join(home, '.local/state'),
            ...extraEnv,
        };
        const result = spawnSync('bash', ['-c', `source "${script}"; YES=1; ${code}`], { encoding: 'utf8', env });
        return { out: result.stdout, err: result.stderr, status: result.status };
    };
    const file = rel => path.join(conf, rel);
    const read = rel => fs.readFileSync(file(rel), 'utf8');
    const write = (rel, text) => {
        fs.mkdirSync(path.dirname(file(rel)), { recursive: true });
        fs.writeFileSync(file(rel), text);
    };
    const exists = rel => fs.existsSync(file(rel));
    const cleanup = () => fs.rmSync(home, { recursive: true, force: true });
    return { home, conf, run, file, read, write, exists, cleanup };
}

const count = (text, needle) => text.split(needle).length - 1;

test('skrip lolos bash -n dan aman di-source', () => {
    const syntax = spawnSync('bash', ['-n', script], { encoding: 'utf8' });
    assert.equal(syntax.status, 0, syntax.stderr);
    const s = sandbox('0.57.0');
    const r = s.run('echo sourced');
    assert.equal(r.out.trim(), 'sourced');
    s.cleanup();
});

test('deteksi mode: Lua untuk >= 0.55 atau hyprland.lua sudah ada; legacy hanya untuk < 0.55', () => {
    for (const [version, mode] of [['0.57.0', 'lua'], ['0.55.0', 'lua'], ['0.55', 'lua'], ['0.56.2', 'lua'], ['1.0.0', 'lua'], ['0.54.9', 'legacy'], ['0.49.0', 'legacy']]) {
        const s = sandbox(version);
        assert.equal(s.run('hypr_mode').out.trim(), mode, version);
        s.cleanup();
    }
    const old = sandbox('0.54.0');
    old.write('hypr/hyprland.lua', '-- punya user\n');
    assert.equal(old.run('hypr_mode').out.trim(), 'lua', 'hyprland.lua yang sudah ada menang atas versi');
    old.cleanup();
    const forced = sandbox('0.57.0');
    assert.equal(forced.run('hypr_mode', { ME_SHELL_HYPR_MODE: 'legacy' }).out.trim(), 'legacy');
    forced.cleanup();
});

test('user baru tanpa ~/.config/hypr: dibuat hyprland.lua + me-shell.lua, tanpa hyprland.conf', () => {
    const s = sandbox('0.57.0');
    fs.rmSync(s.file('hypr'), { recursive: true });
    const r = s.run('write_hypr_files && setup_hyprland');
    assert.equal(r.status, 0, r.err);
    assert.ok(s.exists('hypr/hyprland.lua'));
    assert.ok(!s.exists('hypr/hyprland.conf'), 'hyprland.conf tidak boleh dibuat di mode Lua');
    assert.ok(!s.exists('me-shell/hypr/me-shell.conf') && !s.exists('me-shell/hypr/keybinds.conf'));
    const main = s.read('hypr/hyprland.lua');
    assert.equal(count(main, '-- >>> me-shell'), 1);
    assert.equal(count(main, '-- <<< me-shell'), 1);
    const dir = s.file('me-shell/hypr');
    assert.ok(main.includes(`pcall(require, "${dir}/me-shell")`));
    assert.ok(!s.exists('hypr/hyprland.lua.me-shell.bak'), 'file baru tidak perlu backup');
    for (const name of ['me-shell.lua', 'keybinds.lua', 'user.lua'])
        assert.ok(s.exists(`me-shell/hypr/${name}`), name);
    s.cleanup();
});

test('me-shell.lua dari skrip identik dengan luaMain() di utils/Keybinds.js dan memuat semua yang diminta', () => {
    const s = sandbox('0.57.0');
    s.run('write_hypr_files');
    const text = s.read('me-shell/hypr/me-shell.lua');
    assert.equal(text, kb.luaMain(s.file('me-shell/hypr')));
    const start = text.indexOf('hl.on("hyprland.start"');
    assert.ok(start >= 0);
    const dbus = text.indexOf('dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP');
    const qs = text.indexOf('qs -c me-shell');
    assert.ok(dbus > start && qs > dbus, 'dbus-update-activation-environment harus sebelum qs');
    assert.ok(text.includes('hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")'));
    assert.ok(text.includes('allow_session_lock_restore = true'));
    assert.ok(text.includes('/keybinds")') && text.includes('/user")'));
    s.cleanup();
});

test('hyprland.lua yang sudah ada: ditambah blok sekali (idempoten) dan dibackup', () => {
    const s = sandbox('0.57.0');
    const original = 'hl.config({ autogenerated = true })\nhl.bind("SUPER + Q", hl.dsp.window.close())\n';
    s.write('hypr/hyprland.lua', original);
    assert.equal(s.run('write_hypr_files && setup_hyprland').status, 0);
    const first = s.read('hypr/hyprland.lua');
    assert.ok(first.startsWith(original));
    assert.equal(s.read('hypr/hyprland.lua.me-shell.bak'), original);
    assert.equal(s.run('write_hypr_files && setup_hyprland').status, 0);
    assert.equal(s.read('hypr/hyprland.lua'), first, 'dijalankan dua kali tidak boleh mengubah file');
    assert.equal(count(s.read('hypr/hyprland.lua'), '-- >>> me-shell'), 1);
    assert.equal(s.read('hypr/hyprland.lua.me-shell.bak'), original, 'backup tidak ditimpa');
    s.cleanup();
});

test('hyprland.conf lama tidak disentuh di mode Lua; hyprland.lua minimal dibuat', () => {
    const s = sandbox('0.57.0');
    const conf = '# conf lama\nsource = /x/me-shell.conf\n';
    s.write('hypr/hyprland.conf', conf);
    assert.equal(s.run('write_hypr_files && setup_hyprland').status, 0);
    assert.equal(s.read('hypr/hyprland.conf'), conf);
    assert.ok(s.read('hypr/hyprland.lua').includes('-- >>> me-shell'));
    s.cleanup();
});

test('uninstall (unhook_hyprland) mengembalikan hyprland.lua persis seperti semula', () => {
    const s = sandbox('0.57.0');
    const original = 'hl.config({ autogenerated = true })\nhl.bind("SUPER + Q", hl.dsp.window.close())\n';
    s.write('hypr/hyprland.lua', original);
    s.run('write_hypr_files && setup_hyprland');
    assert.notEqual(s.read('hypr/hyprland.lua'), original);
    assert.equal(s.run('unhook_hyprland').status, 0);
    assert.equal(s.read('hypr/hyprland.lua'), original);
    assert.equal(s.run('unhook_hyprland').status, 0, 'uninstall dua kali tidak error');
    assert.equal(s.read('hypr/hyprland.lua'), original);
    s.cleanup();
});

test('uninstall tidak menghapus hyprland.lua buatan me-shell tanpa persetujuan (-y = tidak)', () => {
    const s = sandbox('0.57.0');
    s.run('write_hypr_files && setup_hyprland');
    s.run('unhook_hyprland');
    assert.ok(s.exists('hypr/hyprland.lua'));
    assert.ok(!s.read('hypr/hyprland.lua').includes('-- >>> me-shell'), 'blok require sudah dilepas');
    s.cleanup();
});

test('pengecekan bentrok memindai hyprland.lua (hl.exec_cmd) dan *.conf, mengabaikan komentar', () => {
    const s = sandbox('0.57.0');
    s.write('hypr/hyprland.lua', [
        'hl.on("hyprland.start", function()',
        '    hl.exec_cmd("waybar")',
        '    -- hl.exec_cmd("mako")',
        '    hl.exec_cmd("kitty")',
        'end)',
        'hl.on("hyprland.start", function() hl.exec_cmd("dunst") end)',
        '',
    ].join('\n'));
    s.write('hypr/extra.conf', 'exec-once = swaync\n# exec-once = hypridle\n');
    const hits = s.run('clash_hits').out;
    assert.match(hits, /hyprland\.lua:2:.*waybar/);
    assert.match(hits, /hyprland\.lua:6:.*dunst/);
    assert.match(hits, /extra\.conf:1:.*swaync/);
    assert.ok(!/mako|hypridle|kitty/.test(hits), hits);
    s.cleanup();
});

test('bentrok dimatikan dengan komentar Lua yang valid, dan dikembalikan oleh uninstall', () => {
    const s = sandbox('0.57.0');
    const lua = 'hl.on("hyprland.start", function()\n    hl.exec_cmd("waybar & hyprpaper")\n    hl.exec_cmd("kitty")\nend)\n';
    s.write('hypr/hyprland.lua', lua);
    s.write('hypr/extra.conf', 'exec-once = swaync\n');
    const r = s.run('write_hypr_files && setup_hyprland');
    assert.equal(r.status, 0, r.err);
    const after = s.read('hypr/hyprland.lua');
    assert.match(after, /^--#me-shell-off# {5}hl\.exec_cmd\("waybar & hyprpaper"\)$/m);
    assert.match(s.read('hypr/extra.conf'), /^#me-shell-off# exec-once = swaync$/m);
    assert.equal(s.run('clash_hits').out.trim(), '', 'yang sudah dimatikan tidak dilaporkan lagi');
    s.run('unhook_hyprland');
    assert.equal(s.read('hypr/hyprland.lua'), lua);
    assert.equal(s.read('hypr/extra.conf'), 'exec-once = swaync\n');
    s.cleanup();
});

test('baris bentrok yang tidak di awal baris dilaporkan, bukan dirusak', () => {
    const s = sandbox('0.57.0');
    const lua = 'hl.on("hyprland.start", function() hl.exec_cmd("dunst") end)\n';
    s.write('hypr/hyprland.lua', lua);
    const r = s.run('write_hypr_files && setup_hyprland');
    assert.match(r.out, /tidak bisa dimatikan otomatis/);
    assert.ok(s.read('hypr/hyprland.lua').startsWith(lua), 'baris asli tidak diubah');
    s.cleanup();
});

test('mode legacy (Hyprland < 0.55) tetap memakai hyprland.conf dan bisa dilepas', () => {
    const s = sandbox('0.54.2');
    fs.rmSync(s.file('hypr'), { recursive: true });
    assert.equal(s.run('write_hypr_files && setup_hyprland').status, 0);
    assert.ok(!s.exists('hypr/hyprland.lua'), 'mode legacy tidak membuat hyprland.lua');
    assert.ok(s.exists('me-shell/hypr/me-shell.conf'));
    assert.ok(s.read('hypr/hyprland.conf').includes(`source = ${s.file('me-shell/hypr')}/me-shell.conf`));
    assert.ok(!s.exists('me-shell/hypr/me-shell.lua'));
    s.run('unhook_hyprland');
    assert.ok(!s.read('hypr/hyprland.conf').includes('me-shell.conf'));
    s.cleanup();
});

test('instalasi lama (source di hyprland.conf) tetap bisa dilepas setelah Hyprland jadi mode Lua', () => {
    const s = sandbox('0.57.0');
    s.write('hypr/hyprland.conf', `monitor = , preferred, auto, 1\n\n# me-shell\nsource = ${s.file('me-shell/hypr')}/me-shell.conf\n`);
    s.run('unhook_hyprland');
    assert.equal(s.read('hypr/hyprland.conf'), 'monitor = , preferred, auto, 1\n\n');
    s.cleanup();
});

test('paket portal ikut di daftar dependency Fedora dan Arch', () => {
    const text = fs.readFileSync(script, 'utf8');
    const lists = text.match(/local pkgs=\(hyprland[^)]*\)/g);
    assert.equal(lists.length, 2);
    for (const list of lists) {
        assert.match(list, /\bxdg-desktop-portal\b/);
        assert.match(list, /\bxdg-desktop-portal-hyprland\b/);
    }
});

test('hyprland.lua hasil install lolos Hyprland --verify-config (user baru, dan user dengan config sendiri)', { skip: !haveHyprland && 'Hyprland tidak terpasang' }, () => {
    const fresh = sandbox('0.57.0');
    fs.rmSync(fresh.file('hypr'), { recursive: true });
    fresh.run('write_hypr_files && setup_hyprland');
    // keybinds.lua asli ditulis QML saat shell start; di sini pakai keluaran generator yang sama
    const qml = fs.readFileSync(path.join(__dirname, '../services/Keybinds.qml'), 'utf8');
    const list = name => vm.runInNewContext('(' + qml.match(new RegExp('readonly property var ' + name + ': (\\[[\\s\\S]*?\\n    \\])'))[1] + ')');
    fresh.write('me-shell/hypr/keybinds.lua', kb.luaKeybinds(list('defaults'), list('fixed'), 'qs -c me-shell ipc call'));
    assert.equal(verifyLua(fresh.file('hypr/hyprland.lua')), 'config ok');
    fresh.cleanup();

    const custom = sandbox('0.57.0');
    custom.write('hypr/hyprland.lua', fs.existsSync('/usr/share/hypr/hyprland.lua') ? fs.readFileSync('/usr/share/hypr/hyprland.lua', 'utf8') : 'hl.env("A", "b")\n');
    custom.run('write_hypr_files && setup_hyprland');
    assert.equal(verifyLua(custom.file('hypr/hyprland.lua')), 'config ok');
    custom.cleanup();
});
