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

# Keybind mengikuti JaKooLit
$qs = qs -c me-shell ipc call
bind = SUPER, D, exec, $qs drawers toggle launcher
bind = SUPER, W, exec, $qs drawers launcher :
bind = SUPER SHIFT, E, exec, $qs drawers panel dash
bind = SUPER SHIFT, N, exec, $qs drawers panel notif
bind = CTRL ALT, L, exec, $qs lock lock
bind = CTRL ALT, P, exec, $qs drawers toggle session
bindel = , XF86AudioRaiseVolume, exec, $qs volume up
bindel = , XF86AudioLowerVolume, exec, $qs volume down
bindel = ALT, XF86AudioRaiseVolume, exec, $qs volume upPrecise
bindel = ALT, XF86AudioLowerVolume, exec, $qs volume downPrecise
bindl = , XF86AudioMute, exec, $qs volume mute
bindl = , XF86AudioMicMute, exec, $qs volume mic
bindl = , XF86AudioPlayPause, exec, $qs media playPause
bindl = , XF86AudioPause, exec, $qs media playPause
bindl = , XF86AudioPlay, exec, $qs media playPause
bindl = , XF86AudioNext, exec, $qs media next
bindl = , XF86AudioPrev, exec, $qs media previous
bindl = , XF86AudioStop, exec, $qs media stop
bindel = , XF86MonBrightnessUp, exec, $qs brightness up
bindel = , XF86MonBrightnessDown, exec, $qs brightness down
```

Keybind di atas sama dengan JaKooLit, jadi hapus dulu bind lama yang memanggil rofi, wlogout, swaync, dan script volume/media JaKooLit supaya tidak dobel. Screenshot, clipboard, dan emoji tidak diurus shell ini, jadi bind-nya biarkan saja.

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
