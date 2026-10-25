#!/usr/bin/env bash
# Install dependency me-shell (Arch / Fedora) lalu pasang sebagai config Quickshell
# di ~/.config/quickshell/me-shell (symlink ke repo ini).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
target="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/me-shell"

ask() {
    read -rp "$1 [y/N] " ok
    [[ $ok == [yY] ]]
}

. /etc/os-release
case "${ID:-} ${ID_LIKE:-}" in
*arch*)
    pkgs=(hyprland brightnessctl networkmanager bluez-utils wl-clipboard curl cava ttf-jetbrains-mono qt6-svg qt6-shadertools)
    aur=(quickshell matugen-bin)
    echo "pacman: ${pkgs[*]}"
    echo "AUR/repo: ${aur[*]}"
    if ask "Install sekarang?"; then
        sudo pacman -S --needed "${pkgs[@]}"
        if command -v paru >/dev/null; then
            paru -S --needed "${aur[@]}"
        elif command -v yay >/dev/null; then
            yay -S --needed "${aur[@]}"
        else
            echo "Tidak ada AUR helper. Install manual: ${aur[*]}"
        fi
    fi
    ;;
*fedora*)
    pkgs=(hyprland quickshell brightnessctl NetworkManager bluez wl-clipboard curl cava jetbrains-mono-fonts qt6-qtsvg qt6-qtshadertools)
    echo "dnf (+ COPR errornointernet/quickshell): ${pkgs[*]}"
    if ask "Install sekarang?"; then
        sudo dnf copr enable -y errornointernet/quickshell
        sudo dnf install -y "${pkgs[@]}"
        command -v matugen >/dev/null || echo "matugen: install lewat 'cargo install matugen'"
    fi
    ;;
*)
    echo "Distro tidak dikenal, install dependency manual (lihat README)."
    ;;
esac

mkdir -p "$(dirname "$target")"
if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "$target sudah ada dan bukan symlink, dilewati."
else
    ln -sfn "$root" "$target"
    echo "Terpasang: $target -> $root"
fi
