const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const { haveHyprland, hyprlandVersion, tmpdir, verifyLua } = require('./hypr-helpers.cjs');

// Jalankan persis JavaScript yang dipakai QML (utils/Keybinds.js), tanpa implementasi tiruan.
const kb = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../utils/Keybinds.js'), 'utf8'), kb);
const plain = value => JSON.parse(JSON.stringify(value));

// defaults dan fixed diambil dari services/Keybinds.qml, jadi tes ikut berubah kalau daftarnya berubah.
const qml = fs.readFileSync(path.join(__dirname, '../services/Keybinds.qml'), 'utf8');
function listFrom(name) {
    const match = qml.match(new RegExp('readonly property var ' + name + ': (\\[[\\s\\S]*?\\n    \\])'));
    assert.ok(match, 'Daftar ' + name + ' tidak ditemukan di Keybinds.qml');
    return plain(vm.runInNewContext('(' + match[1] + ')'));
}
const defaults = listFrom('defaults');
const fixed = listFrom('fixed');

test('mods dan key diubah ke format Lua "A + B + KEY"', () => {
    assert.equal(kb.luaKeys('SUPER SHIFT', 'E'), 'SUPER + SHIFT + E');
    assert.equal(kb.luaKeys('SUPER', 'D'), 'SUPER + D');
    assert.equal(kb.luaKeys('CTRL ALT', 'P'), 'CTRL + ALT + P');
    assert.equal(kb.luaKeys('', 'Print'), 'Print');
    assert.equal(kb.luaKeys(undefined, 'XF86AudioMute'), 'XF86AudioMute');
    assert.equal(kb.luaKeys('  SUPER   SHIFT ', 'TAB'), 'SUPER + SHIFT + TAB');
});

test('karakter tunggal diubah ke nama keysym, karena "+" dan "," tidak valid sebagai tombol', () => {
    assert.equal(kb.luaKeys('SUPER', '-'), 'SUPER + minus');
    assert.equal(kb.luaKeys('SUPER', '+'), 'SUPER + plus');
    assert.equal(kb.luaKeys('SUPER SHIFT', ','), 'SUPER + SHIFT + comma');
    assert.equal(kb.luaKeys('SUPER', '['), 'SUPER + bracketleft');
    assert.equal(kb.luaKeys('SUPER', '\\'), 'SUPER + backslash');
    // yang sudah berupa nama tidak diubah
    assert.equal(kb.luaKeys('SUPER', 'PERIOD'), 'SUPER + PERIOD');
    assert.equal(kb.luaKeys('SUPER', 'toString'), 'SUPER + toString');
});

test('flag hyprlang (bindl/bindel/bindn/bindm) menjadi opsi hl.bind', () => {
    assert.deepEqual(plain(kb.luaFlagNames('bind')), []);
    assert.deepEqual(plain(kb.luaFlagNames('bindl')), ['locked']);
    assert.deepEqual(plain(kb.luaFlagNames('bindel')), ['locked', 'repeating']);
    assert.deepEqual(plain(kb.luaFlagNames('bindle')), ['locked', 'repeating']);
    assert.deepEqual(plain(kb.luaFlagNames('bindn')), ['non_consuming']);
    assert.deepEqual(plain(kb.luaFlagNames('bindm')), ['mouse']);
    assert.throws(() => kb.luaFlagNames('bindz'), /tidak didukung/);
    assert.throws(() => kb.luaFlagNames('exec'), /tidak dikenal/);
});

test('luaBind: exec_cmd untuk perintah, drag/resize untuk bind mouse', () => {
    assert.equal(kb.luaBind('bind', 'SUPER SHIFT', 'E', 'drawers panel dash'), 'hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(meshell .. " drawers panel dash"))');
    assert.equal(kb.luaBind('bindel', '', 'XF86AudioRaiseVolume', 'volume up'), 'hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(meshell .. " volume up"), { locked = true, repeating = true })');
    assert.equal(kb.luaBind('bindm', 'SUPER', 'mouse:272', 'movewindow'), 'hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })');
    assert.equal(kb.luaBind('bindm', 'SUPER', 'mouse:273', 'resizewindow'), 'hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })');
    assert.throws(() => kb.luaBind('bindm', 'SUPER', 'mouse:274', 'sesuatu'), /Aksi mouse/);
});

test('luaString meng-escape kutip, backslash, dan karakter kontrol', () => {
    assert.equal(kb.luaString("drawers launcher ';'"), '"drawers launcher \';\'"');
    assert.equal(kb.luaString('a"b\\c\nd'), '"a\\"b\\\\c\\nd"');
    assert.equal(kb.luaString('x\u0001y'), '"x\\001y"');
});

test('keybinds.lua dibuat dari seluruh default dan fixed Keybinds.qml', () => {
    const text = kb.luaKeybinds(defaults, fixed, 'qs -c me-shell ipc call');
    const binds = text.split('\n').filter(line => line.startsWith('hl.bind('));
    assert.equal(binds.length, defaults.length + fixed.length);
    assert.ok(text.includes('local meshell = "qs -c me-shell ipc call"'));
    assert.ok(text.includes('hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(meshell .. " drawers panel dash"))'));
    assert.ok(text.includes('hl.bind("Print", hl.dsp.exec_cmd(meshell .. " picker screen"))'));
    assert.ok(text.includes('hl.bind("XF86AudioMute", hl.dsp.exec_cmd(meshell .. " volume mute"), { locked = true })'));
    assert.ok(text.includes('hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(meshell .. " volume upPrecise"), { locked = true, repeating = true })'));
    assert.ok(text.includes('hl.bind("Caps_Lock", hl.dsp.exec_cmd(meshell .. " keyboard locks"), { non_consuming = true })'));
    // format hyprlang lama ("SUPER SHIFT", "E") tidak boleh tersisa
    for (const line of binds)
        assert.match(line, /^hl\.bind\("(?:[A-Za-z0-9_:]+ \+ )*[A-Za-z0-9_:]+", /);
});

test('perubahan dari settings (override) ikut tertulis', () => {
    const changed = defaults.map(d => d.id === 'launcher' ? { ...d, mods: 'CTRL ALT', key: '-' } : d);
    const text = kb.luaKeybinds(changed, [], 'qs -c me-shell ipc call');
    assert.ok(text.includes('hl.bind("CTRL + ALT + minus", hl.dsp.exec_cmd(meshell .. " drawers toggle launcher"))'));
});

test('Keybinds.qml memakai helper dan menulis kedua format sesuai mode', () => {
    assert.ok(qml.includes('import "../utils/Keybinds.js" as KB'));
    assert.ok(qml.includes('hl.dsp.submap("me-shell-capture")'), 'mode Lua harus memakai hl.dsp.submap untuk merekam');
    assert.ok(qml.includes('"keybinds.lua"') && qml.includes('"keybinds.conf"'));
});

test('semua nama keysym di tabel konversi diterima Hyprland', { skip: !haveHyprland && 'Hyprland tidak terpasang' }, () => {
    const dir = tmpdir();
    const entry = path.join(dir, 'hyprland.lua');
    const chars = Object.keys(plain(vm.runInContext('LUA_KEYSYMS', kb)));
    fs.writeFileSync(entry, chars.map(c => `hl.bind(${kb.luaString(kb.luaKeys('SUPER', c))}, hl.dsp.exec_cmd("true"))`).join('\n') + '\n');
    assert.equal(verifyLua(entry), 'config ok');
    fs.rmSync(dir, { recursive: true, force: true });
});

test('keybinds.lua hasil generate lolos Hyprland --verify-config', { skip: !haveHyprland && 'Hyprland tidak terpasang' }, () => {
    const dir = tmpdir();
    const file = path.join(dir, 'keybinds.lua');
    const entry = path.join(dir, 'hyprland.lua');
    fs.writeFileSync(file, kb.luaKeybinds(defaults, fixed, 'qs -c me-shell ipc call'));
    fs.writeFileSync(entry, `require(${JSON.stringify(path.join(dir, 'keybinds'))})\n`);
    assert.equal(verifyLua(entry), 'config ok', hyprlandVersion);
    fs.rmSync(dir, { recursive: true, force: true });
});

test('kontrol negatif: verifikator memang menolak format lama "SUPER SHIFT E"', { skip: !haveHyprland && 'Hyprland tidak terpasang' }, () => {
    const dir = tmpdir();
    const entry = path.join(dir, 'hyprland.lua');
    fs.writeFileSync(entry, 'hl.bind("SUPER SHIFT E", hl.dsp.exec_cmd("true"))\nhl.bind("SUPER + -", hl.dsp.exec_cmd("true"))\n');
    const result = verifyLua(entry);
    assert.match(result, /Unknown key: SUPER SHIFT E/);
    assert.match(result, /Unknown key: -/);
    fs.rmSync(dir, { recursive: true, force: true });
});
