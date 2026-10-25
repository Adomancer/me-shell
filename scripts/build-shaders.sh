#!/usr/bin/env sh
# Compile shader GLSL di assets/shaders menjadi .qsb (format shader Qt 6).
# Butuh qsb dari qt6-shadertools (Arch) / qt6-qtshadertools (Fedora).
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"

qsb_bin=""
for c in qsb qsb-qt6 /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb; do
    if command -v "$c" >/dev/null 2>&1; then
        qsb_bin="$c"
        break
    fi
done
[ -n "$qsb_bin" ] || {
    echo "qsb tidak ditemukan. Install qt6-shadertools dulu." >&2
    exit 1
}

for f in "$root"/assets/shaders/*.frag; do
    "$qsb_bin" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$f.qsb" "$f"
    echo "ok: $f.qsb"
done
