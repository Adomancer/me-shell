// Helper bersama untuk tes Hyprland (bukan tes sendiri: nama file tidak berakhiran .test.cjs).
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const hyprland = spawnSync('Hyprland', ['--version'], { encoding: 'utf8' });
const haveHyprland = !hyprland.error && hyprland.status === 0;

function tmpdir(prefix = 'me-shell-test-') {
    return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

// Jalankan `Hyprland --verify-config` pada satu file Lua. Mengembalikan teks hasil parsing
// ("config ok" atau daftar error); config user yang asli tidak disentuh karena -c eksplisit.
function verifyLua(file) {
    const rt = tmpdir('me-shell-rt-');
    fs.chmodSync(rt, 0o700);
    const run = spawnSync('Hyprland', ['--verify-config', '-c', file, '--i-am-really-stupid'], {
        encoding: 'utf8',
        env: { ...process.env, XDG_RUNTIME_DIR: rt, HOME: rt },
        timeout: 30000,
    });
    fs.rmSync(rt, { recursive: true, force: true });
    const out = (run.stdout || '') + (run.stderr || '');
    const marker = 'Config parsing result:';
    const at = out.indexOf(marker);
    if (at < 0)
        throw new Error('Output --verify-config tidak dikenali:\n' + out);
    return out.slice(at + marker.length).trim();
}

module.exports = { haveHyprland, hyprlandVersion: haveHyprland ? hyprland.stdout.split('\n')[0] : '', tmpdir, verifyLua };
