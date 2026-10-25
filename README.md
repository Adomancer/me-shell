# me-shell

Desktop shell untuk [Hyprland](https://hyprland.org), dibuat dengan [Quickshell](https://quickshell.org).
Gaya **retro minimalis**: bar di atas, font monospace, sudut tajam, bayangan keras, dan palet dinamis dari wallpaper.

> ⚠️ Status: semua fitur sudah ditulis tapi **belum pernah dites** di Linux.

## Fitur

- **Bar**: workspace, judul window aktif, jam (klik = control panel), tray, NET/BT/VOL/BAT, tombol power
- **Control panel**: media player, slider volume/brightness, toggle Wi-Fi/Bluetooth/DND/mic, CPU/RAM, kalender, riwayat notifikasi
- **Launcher**: aplikasi (fuzzy search), `=` kalkulator, `>` perintah shell, `:` pemilih wallpaper
- **Notifikasi**: popup + riwayat, DND
- **OSD**: volume & brightness
- **Session menu**: lock, logout, sleep, reboot, shutdown (dengan konfirmasi)
- **Lockscreen**: PAM, efek CRT menyala, scanline, shader CRT opsional
- **Wallpaper**: dirender shell dengan crossfade, warna otomatis via matugen

## Bahasa

| Bahasa | Dipakai untuk |
|---|---|
| QML | Semua UI dan services |
| JavaScript | Logika (`utils/Fuzzy.js`, `utils/Calc.js`) |
| Bash | Script install, generate warna, compile shader |
| GLSL | Shader CRT lockscreen (`assets/shaders/crt.frag`) |

## Install

```sh
git clone <repo> ~/me-shell
bash ~/me-shell/scripts/install.sh
```

Script ini menginstall dependency (Arch/Fedora) dan membuat symlink `~/.config/quickshell/me-shell`.

Dependency: `hyprland`, `quickshell` (0.2+), `brightnessctl`, `NetworkManager`, `bluez`, `wl-clipboard`, font JetBrains Mono, `matugen`, dan `qt6-shadertools` (opsional, untuk shader).

> Matikan notification daemon lain (swaync/mako/dunst) dan Waybar, karena me-shell menggantikan keduanya.

## Hyprland

```ini
exec-once = qs -c me-shell

# Wajib: supaya lockscreen bisa pulih kalau shell crash
misc {
    allow_session_lock_restore = true
}

$qs = qs -c me-shell ipc call
bind = SUPER, Space, exec, $qs drawers toggle launcher
bind = SUPER, A, exec, $qs drawers toggle panel
bind = SUPER, Escape, exec, $qs drawers toggle session
bind = SUPER, L, exec, $qs lock lock
bindel = , XF86AudioRaiseVolume, exec, $qs volume up
bindel = , XF86AudioLowerVolume, exec, $qs volume down
bindl = , XF86AudioMute, exec, $qs volume mute
bindel = , XF86MonBrightnessUp, exec, $qs brightness up
bindel = , XF86MonBrightnessDown, exec, $qs brightness down
```

Untuk hypridle: `lock_cmd = qs -c me-shell ipc call lock lock`

### Perintah IPC

| Target | Fungsi |
|---|---|
| `drawers` | `toggle <panel\|launcher\|session>`, `open <nama>`, `close` |
| `lock` | `lock`, `isLocked` |
| `volume` | `up`, `down`, `mute`, `mic` |
| `brightness` | `up`, `down` |
| `notifs` | `dnd`, `clear` |
| `wallpaper` | `set <path>`, `get` |

## Konfigurasi

Opsional: `~/.config/me-shell/config.json` (otomatis di-reload). Semua key opsional:

```json
{
  "barHeight": 32,
  "clockFormat": "hh:mm",
  "dateFormat": "ddd, dd MMM",
  "blinkCursor": true,
  "fontFamily": "JetBrains Mono",
  "workspaces": 5,
  "wallpaperDir": "~/Pictures/Wallpapers",
  "renderWallpaper": true,
  "colorMode": "dark",
  "crtShader": false,
  "pixelArt": true,
  "launcherMaxResults": 8
}
```

- `renderWallpaper: false` kalau mau pakai swww/hyprpaper
- `crtShader: true` setelah menjalankan `scripts/build-shaders.sh`
- `pixelArt`: cover album dirender ala pixel art

## Development

- Jalankan langsung dari repo: `qs -p ~/me-shell` (hot reload saat file disimpan)
- Autocomplete QML: buat file kosong `.qmlls.ini` di root repo, nanti Quickshell yang mengisinya

## Struktur

| Folder | Isi |
|---|---|
| `shell.qml` | Entry point |
| `utils/` | `Appearance` (design tokens), `Config`, `Paths`, helper JS |
| `services/` | Data sistem & state (audio, jaringan, notifikasi, drawer, dll.) |
| `components/` | Elemen UI reusable (`RetroFrame`, `RetroButton`, `Reveal`, ...) |
| `modules/` | `drawers` (window per monitor), `bar`, `panel`, `launcher`, `notifs`, `osd`, `session`, `lock`, `background` |
| `assets/` | PAM config, template matugen, shader, scanline |
| `scripts/` | Install, generate warna, compile shader |
