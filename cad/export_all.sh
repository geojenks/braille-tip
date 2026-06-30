#!/usr/bin/env bash
# export_all.sh — render every braillegen.scad part to STL + a print-readiness report.
#
# Usage (from this folder):
#   ./export_all.sh
#   RINGS=1 COUPLING=heatset MEMBRANE=flat ./export_all.sh
#   FN=48 OUTDIR=out ./export_all.sh -D tube_id=1.2 -D tube_od=2.4
#
# Extra "-D name=value" overrides are passed straight through to OpenSCAD.
# Finds OpenSCAD from $OPENSCAD or PATH (openscad / openscad.com).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scad="$here/braillegen.scad"

RINGS="${RINGS:-2}"; COUPLING="${COUPLING:-barb}"; MEMBRANE="${MEMBRANE:-curved}"
FN="${FN:-36}"; OUTDIR="${OUTDIR:-$here/out}"

OSCAD="${OPENSCAD:-}"
[ -z "$OSCAD" ] && OSCAD="$(command -v openscad.com || command -v openscad || true)"
[ -z "$OSCAD" ] && { echo "OpenSCAD not found. Set OPENSCAD=/path/to/openscad" >&2; exit 1; }

mkdir -p "$OUTDIR"
common=(-D "n_rings=$RINGS" -D "coupling=\"$COUPLING\"" -D "membrane=\"$MEMBRANE\"" -D "\$fn=$FN" "$@")
echo "OpenSCAD : $OSCAD"
echo "Config   : rings=$RINGS coupling=$COUPLING membrane=$MEMBRANE fn=$FN"
echo "Out      : $OUTDIR"; echo

for p in tip base pin_tool mould_floor mould_wall; do
  printf -- "-> %s.stl ..." "$p"
  t0=$(date +%s)
  "$OSCAD" -o "$OUTDIR/$p.stl" -D "part=\"$p\"" "${common[@]}" "$scad" >/dev/null 2>&1 || { echo " FAILED"; continue; }
  echo " ok ($(( $(date +%s)-t0 ))s, $(( $(stat -c%s "$OUTDIR/$p.stl")/1024 )) KB)"
done

# report: capture the ECHO block from one lightweight render
report="$OUTDIR/report.txt"
{
  echo "braillegen print-readiness report  ($(date -Is))"
  echo "config: rings=$RINGS  coupling=$COUPLING  membrane=$MEMBRANE"; echo
  "$OSCAD" -o "$OUTDIR/_r.stl" -D 'part="tip"' -D '$fn=8' "${common[@]}" "$scad" 2>&1 1>/dev/null \
    | sed -n 's/^ECHO: "\{0,1\}//; s/"$//; p' | grep -E ':' || true
} > "$report"
rm -f "$OUTDIR/_r.stl"
echo; echo "--- report.txt ---"; cat "$report"
echo; echo "Done. STLs + report in $OUTDIR"
