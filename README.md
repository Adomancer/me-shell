# me-shell

Desktop shell untuk [Hyprland](https://hyprland.org), dibuat dengan [Quickshell](https://quickshell.org) (QML murni, tanpa compile).
Gaya: **retro minimalis**, bar di atas, palet dinamis dari wallpaper.

> Status: tahap awal, baru ada bar dasar. Roadmap lengkap ada di [PLAN.md](PLAN.md).

## Dependency

- Hyprland
- Quickshell (versi 0.2 ke atas, untuk `import qs.*`)
- Font: JetBrains Mono (atau Departure Mono, lihat `utils/Appearance.qml`)
- Nanti: matugen (warna dinamis)

### Install Quickshell

```sh
# Arch
sudo pacman -S quickshell        # atau dari AUR: quickshell-git

# Fedora (COPR)
sudo dnf copr enable errornointernet/quickshell
sudo dnf install quickshell
```

Cek nama paket terbaru di dokumentasi Quickshell kalau perintah di atas gagal.

## Menjalankan

```sh
git clone <repo> ~/me-shell
qs -p ~/me-shell
```

Supaya jalan otomatis, tambahkan ke `hyprland.conf`:

```ini
exec-once = qs -p ~/me-shell
```

Untuk autocomplete QML di editor, buat file kosong `.qmlls.ini` di root repo. Quickshell akan mengisinya saat dijalankan (file ini sudah di-gitignore).

## Konfigurasi

Opsional: `~/.config/me-shell/config.json` (otomatis di-reload saat disimpan)

```json
{
  "barHeight": 32,
  "clockFormat": "hh:mm",
  "dateFormat": "ddd, dd MMM"
}
```

## Struktur

| Folder | Isi |
|---|---|
| `shell.qml` | Entry point |
| `utils/` | `Appearance` (design tokens), `Config` (config user) |
| `services/` | Data sistem (waktu, audio, media, dll.) |
| `components/` | Elemen UI reusable |
| `modules/` | Bagian shell: bar, panel, lock, launcher, dll. |
| `daemons/`, `scripts/`, `assets/` | Proses latar, script pendukung, aset |
