#!/usr/bin/env bash
# Install me-shell dalam satu baris (Arch / Fedora):
#   curl -fsSL https://raw.githubusercontent.com/Adomancer/me-shell/main/scripts/install.sh | bash
# Dari repo yang sudah di-clone: bash scripts/install.sh
# Semua langkahnya ada di scripts/me-shell (perintah "install").
set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/me-shell"

# Dijalankan dari dalam repo: langsung pakai repo itu
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$here" ] && [ -f "$here/me-shell" ] && [ -f "$here/../shell.qml" ]; then
    exec bash "$here/me-shell" install "$@"
fi

# Lewat curl: clone dulu (butuh git)
if ! command -v git >/dev/null; then
    echo ">> git belum ada, meng-install..."
    if command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm git
    elif command -v dnf >/dev/null; then
        sudo dnf install -y git
    else
        echo "Install git dulu, lalu jalankan ulang." >&2
        exit 1
    fi
fi

if [ -d "$DATA/.git" ]; then
    git -C "$DATA" pull --ff-only
else
    git clone --depth 1 https://github.com/Adomancer/me-shell "$DATA"
fi

exec bash "$DATA/scripts/me-shell" install "$@"
