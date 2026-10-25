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
- menu settings buat ngatur semuanya, termasuk keybind

## Pasang

```sh
git clone https://github.com/Adomancer/me-shell ~/me-shell
bash ~/me-shell/scripts/install.sh
```

Script-nya jalan di Arch dan Fedora. Dia install dependency (ditanya dulu) lalu bikin symlink ke `~/.config/quickshell/me-shell`.

Matikan dulu Waybar dan notification daemon lain (swaync, mako, dunst), soalnya shell ini sudah menggantikan semuanya.

Waktu jalan pertama kali, shell bikin folder `~/.config/me-shell/hypr/`. Polanya sama seperti JaKooLit, keybind dipecah ke beberapa file:

```
~/.config/me-shell/hypr/
  me-shell.conf    file utama, ini yang di-source
  keybinds.conf    keybind shell, dibuat dari menu settings
  user.conf        punyamu sendiri, tidak pernah ditimpa
```

Di `hyprland.conf` cukup tambah satu baris:

```ini
source = ~/.config/me-shell/hypr/me-shell.conf
```

File itu sudah berisi `exec-once = qs -c me-shell` dan `allow_session_lock_restore`, jadi jangan ditulis dua kali. Kalau shell belum pernah jalan, jalankan `qs -c me-shell` sekali dulu supaya file-filenya dibuat.

Keybind bawaannya mengikuti JaKooLit:

| Tombol | Buka |
|---|---|
| `SUPER + D` | launcher |
| `SUPER + W` | launcher mode wallpaper |
| `SUPER + SHIFT + E` | control panel |
| `SUPER + SHIFT + N` | control panel tab notifikasi |
| `SUPER + I` | settings |
| `CTRL + ALT + P` | menu power |
| `CTRL + ALT + L` | lockscreen |

Tombol volume, mic, media, dan brightness di keyboard juga sudah diurus. Semua kombinasi bisa diganti dari menu settings, tab KEYBIND, lalu klik TERAPKAN. Hapus dulu bind lama yang memanggil rofi, wlogout, swaync, dan script volume/media JaKooLit supaya tidak dobel. Screenshot, clipboard, dan emoji tidak diurus shell ini, jadi bind-nya biarkan saja.

Jangan hapus `allow_session_lock_restore`. Kalau shell crash pas layar terkunci, opsi itu yang bikin lockscreen masih bisa dipulihkan.

## Setting

Paling gampang lewat menu settings (`SUPER + I`, atau tombol `[CFG]` di control panel). Semua perubahan langsung disimpan ke `~/.config/me-shell/config.json` dan langsung kepakai tanpa restart. File itu juga bisa diedit manual, contohnya:

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
