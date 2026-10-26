#!/usr/bin/env sh
# Generate palet warna dari wallpaper dengan matugen.
# Pemakaian: gen-colors.sh <gambar> [dark|light]
set -eu

img="$1"
mode="${2:-dark}"
root="$(cd "$(dirname "$0")/.." && pwd)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/me-shell"
cfg="$state/matugen.toml"

command -v matugen >/dev/null 2>&1 || {
    echo "matugen tidak ditemukan, warna tidak diubah" >&2
    exit 1
}

mkdir -p "$state"
cat >"$cfg" <<EOF
[config]

# Warna ANSI terminal, diselaraskan matugen dengan wallpaper
[config.custom_colors]
red = "#e5484d"
green = "#46a758"
yellow = "#e2a336"
blue = "#3e8ed0"
magenta = "#a86fd8"
cyan = "#2fb5b5"

[templates.meshell]
input_path = "$root/assets/matugen/colors.template.json"
output_path = "$state/colors.json"

[templates.kitty]
input_path = "$root/assets/matugen/kitty.template.conf"
output_path = "$state/kitty-colors.conf"

[templates.starship]
input_path = "$root/assets/matugen/starship.template.toml"
output_path = "$state/starship.toml"
EOF

matugen image "$img" --config "$cfg" --mode "$mode"

# kitty yang sedang terbuka membaca ulang config (termasuk warna baru)
pkill -USR1 -x kitty 2>/dev/null || true
