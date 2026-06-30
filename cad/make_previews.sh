#!/usr/bin/env bash
# make_previews.sh — render the STL grid that preview.html switches between.
# 9 tips (rings x pitch) + 18 bases (rings x pitch x coupling) = 27 files.
# Then serve this folder and open preview.html, e.g.:  python -m http.server
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scad="$here/braillegen.scad"; out="$here/preview_stl"; FN="${FN:-24}"
OSCAD="${OPENSCAD:-}"; [ -z "$OSCAD" ] && OSCAD="$(command -v openscad.com || command -v openscad || true)"
[ -z "$OSCAD" ] && { echo "OpenSCAD not found. Set OPENSCAD=/path/to/openscad" >&2; exit 1; }
mkdir -p "$out"
for r in 1 2 3; do for p in 2.0 2.5 3.0; do
  pp="${p/./}"
  echo "tip r$r p$p"
  "$OSCAD" -o "$out/tip_r${r}_p${pp}.stl" -D 'part="tip"' -D "n_rings=$r" -D "pitch=$p" -D "\$fn=$FN" "$scad" >/dev/null 2>&1
  for c in barb heatset; do
    echo "base r$r p$p $c"
    "$OSCAD" -o "$out/base_r${r}_p${pp}_${c}.stl" -D 'part="base"' -D "n_rings=$r" -D "pitch=$p" -D "coupling=\"$c\"" -D "\$fn=$FN" "$scad" >/dev/null 2>&1
  done
done; done
echo "done -> $out ($(ls -1 "$out" | wc -l) files)"
