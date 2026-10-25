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

[templates.meshell]
input_path = "$root/assets/matugen/colors.template.json"
output_path = "$state/colors.json"
EOF

matugen image "$img" --config "$cfg" --mode "$mode"
