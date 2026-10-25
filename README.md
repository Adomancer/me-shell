# me-shell

Shell Hyprland buatan sendiri, ditulis pakai [Quickshell](https://quickshell.org).
Terinspirasi dari [Caelestia](https://github.com/caelestia-dots/shell), tapi gayanya retro dan lebih kalem:
font monospace, sudut kotak, dan teks `VOL 45%` sebagai pengganti ikon.

Masih tahap awal dan belum pernah dites di mesin asli, jadi kemungkinan besar masih ada yang rusak.

## Isinya

- bar di atas: workspace, jam, tray, baterai
- control panel bertab yang turun dari jam: dashboard, media player dengan kaset dan equalizer (cava), grafik performa, cuaca, notifikasi
- launcher: cari aplikasi, `=` buat ngitung, `>` buat jalanin perintah, `:` buat ganti wallpaper
- notifikasi, OSD volume/brightness, menu power di tepi kanan
- lockscreen tiga kolom: cuaca, info sistem, media, jam, foto profil, notifikasi, plus efek CRT
- wallpaper + warna yang ikut wallpaper (pakai matugen)

## Pasang

```sh
git clone https://github.com/Adomancer/me-shell ~/me-shell
bash ~/me-shell/scripts/install.sh
```

Script-nya jalan di Arch dan Fedora. Dia install dependency (ditanya dulu) lalu bikin symlink ke `~/.config/quickshell/me-shell`.

Matikan dulu Waybar dan notification daemon lain (swaync, mako, dunst), soalnya shell ini sudah menggantikan semuanya.

Tambahkan ini di `hyprland.conf`:

```ini
exec-once = qs -c me-shell

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

Jangan hapus `allow_session_lock_restore`. Kalau shell crash pas layar terkunci, opsi itu yang bikin lockscreen masih bisa dipulihkan.

## Setting

Bikin `~/.config/me-shell/config.json` kalau mau ganti sesuatu. Semua key opsional, dan perubahannya langsung kebaca tanpa restart. Contoh:

```json
{
  "clockFormat": "hh:mm",
  "workspaces": 5,
  "wallpaperDir": "~/Pictures/Wallpapers",
  "renderWallpaper": true,
  "crtShader": false,
  "weatherLocation": "Jakarta"
}
```

Daftar lengkapnya ada di [`utils/Config.qml`](utils/Config.qml).

Foto profil diambil dari `~/.face`. Cuaca diambil dari wttr.in, jadi butuh internet; kalau `weatherLocation` kosong, lokasinya ditebak dari IP.

Kalau wallpaper sudah diatur swww atau hyprpaper, set `renderWallpaper` ke `false`. Shader CRT di lockscreen perlu di-compile dulu pakai `scripts/build-shaders.sh`, baru `crtShader` bisa dinyalakan.

## Ngoprek

Jalankan langsung dari folder repo pakai `qs -p ~/me-shell`. Setiap file disimpan, tampilannya langsung reload, dan error-nya muncul di terminal.

Semua warna, ukuran, dan kecepatan animasi ada di [`utils/Appearance.qml`](utils/Appearance.qml).
