# me-shell

Shell Hyprland buatan sendiri, ditulis pakai [Quickshell](https://quickshell.org).
Terinspirasi dari [Caelestia](https://github.com/caelestia-dots/shell) dan [end_4](https://github.com/end-4/dots-hyprland):
bar dan panel digambar sebagai satu bentuk dengan bingkai layar, panel "tumbuh" dari tepi layar,
gayanya Material 3 dengan ikon Material Symbols, dan angka/jam pakai font monospace.

Sudah dites di Fedora 44 (VM), tapi belum di laptop asli dan belum di Arch, jadi mungkin masih ada yang aneh.

## Isinya

- bar di atas: workspace, judul window, jam, tray, ikon status
- control panel bertab yang turun dari jam: dashboard, media player dengan visualizer (cava), performa, cuaca, notifikasi
- launcher: cari aplikasi, `=` buat ngitung, `>` buat jalanin perintah, `:` buat ganti wallpaper
- notifikasi (bisa di-swipe), OSD volume/brightness, menu power di tepi kanan
- lockscreen tiga kolom: cuaca, info sistem, media, jam, foto profil, notifikasi, plus efek CRT opsional
- wallpaper + warna yang ikut wallpaper (pakai matugen)
- menu settings buat ngatur semuanya, termasuk keybind

## Pasang

Satu baris, jalan di Arch dan Fedora:

```sh
curl -fsSL https://raw.githubusercontent.com/Adomancer/me-shell/main/scripts/install.sh | bash
```

Script-nya nanya sekali sebelum install paket, lalu:

- install Hyprland (kalau belum ada), Quickshell, dan semua dependency lain
- unduh font Material Symbols dan Rubik ke `~/.local/share/fonts/me-shell`
- clone repo ke `~/.local/share/me-shell` dan pasang perintah `me-shell` di `~/.local/bin`
- bikin `~/.config/me-shell/hypr/` dan nambahin satu baris `source` ke `hyprland.conf` (ada backup-nya). Kalau belum punya `hyprland.conf`, dibuatin yang minimal
- nawarin buat matiin Waybar, swaync, mako, atau dunst kalau ketemu di config, soalnya bentrok

Setelah itu tinggal login ke Hyprland. Kalau install dari live USB, jalankan `passwd` dulu, soalnya user live nggak punya password dan lockscreen jadi nggak bisa di-unlock.

Perintah lain:

```
me-shell update      ambil versi terbaru lalu restart
me-shell restart     nyalain ulang shell
me-shell log         jalanin di terminal dan simpan log (buat lapor error)
me-shell uninstall   lepas dari Hyprland dan balikin config yang dimatiin
```

Keybind dipecah ke beberapa file seperti JaKooLit:

```
~/.config/me-shell/hypr/
  me-shell.conf    file utama yang di-source
  keybinds.conf    keybind shell, dibuat dari menu settings
  user.conf        punyamu sendiri, tidak pernah ditimpa
```

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

Tombol volume, mic, media, dan brightness di keyboard juga sudah diurus. Semua kombinasi bisa diganti dari menu settings, halaman Keybind, lalu klik "Terapkan keybind". Kalau sebelumnya pakai JaKooLit, hapus dulu bind lama yang manggil rofi, wlogout, swaync, dan script volume/media-nya supaya nggak dobel. Screenshot, clipboard, dan emoji nggak diurus shell ini, jadi bind-nya biarin aja.

Di `me-shell.conf` ada `allow_session_lock_restore = true`. Jangan dihapus, soalnya kalau shell crash pas layar terkunci, opsi itu yang bikin lockscreen masih bisa dipulihkan.

## Setting

Paling gampang lewat menu settings (`SUPER + I`, atau tombol roda gigi di dashboard). Semua perubahan langsung disimpan ke `~/.config/me-shell/config.json` dan langsung kepakai tanpa restart. File itu juga bisa diedit manual, contohnya:

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

Kalau ngetes di VirtualBox, Qt bisa crash di driver grafisnya. Tambahkan `env = LIBGL_ALWAYS_SOFTWARE,1` dan `env = MESA_LOADER_DRIVER_OVERRIDE,llvmpipe` ke `~/.config/me-shell/hypr/user.conf`. Animasinya jadi lebih patah karena digambar CPU, di mesin asli tidak begitu.

Semua warna, ukuran, dan kecepatan animasi ada di [`utils/Appearance.qml`](utils/Appearance.qml).
