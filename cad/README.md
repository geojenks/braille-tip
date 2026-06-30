# braillegen — parametric Braille-tip CAD generator

A single OpenSCAD source (`braillegen.scad`) that generates every printable part of a
Braille-tip / BraillePen sensor from a handful of design variables, so you can re-size the
array or swap the tube coupling without re-CADing anything by hand. It mirrors the build
forks in the [hand-off guide](https://geojenks.github.io/braille-tip/).

## What it makes

| `part=` | Part | Print in | Role |
|---|---|---|---|
| `tip` | soft sensor body | **silicone** (direct print) | taxel cavities + flat/curved membrane + channels + plug spigot |
| `base` | rigid channel base | FDM or resin | fans the channels out to the tube couplings (barb / heat-set) |
| `pin_tool` | pin/extruder tool | FDM or resin | forms the taxel cavities for the **cast** route |
| `mould_floor` | mould tray floor | FDM or resin | cast route |
| `mould_wall` | dam ring | FDM or resin | contains the silicone pour |
| `all` | every part, laid out | — | preview / sanity check (default) |

The taxels sit on a tight 2.5 mm grid but tubes and inserts are far bigger, so the **base is a
frustum**: channels fan *down-and-out* from the taxel grid to a coarser coupling grid on the
underside. The minimum coupling pitch and the base height are derived automatically from the
fitting you choose, so channels never collide and never leave the body.

## Requirements

[OpenSCAD](https://openscad.org) (tested on 2021.01). Either install it, or drop the portable
ZIP anywhere and point the exporter at `openscad.com`.

## Quick start

**GUI** — open `braillegen.scad` in OpenSCAD, `Window ▸ Customizer`, tweak the sliders, `F5` to
preview (set `cut = true` to see the internal channels), `F6` to render, then `File ▸ Export ▸ STL`.

**Headless, all parts + report** — from this folder:

```powershell
# Windows PowerShell
.\export_all.ps1 -Rings 2 -Coupling barb -Membrane curved
.\export_all.ps1 -Rings 1 -Coupling heatset -Membrane flat -OpenSCAD "C:\path\to\openscad.com"
```

```bash
# bash / git-bash / Linux / macOS
./export_all.sh
RINGS=1 COUPLING=heatset MEMBRANE=flat ./export_all.sh
FN=48 ./export_all.sh -D tube_id=1.2 -D tube_od=2.4   # any extra -D passes through
```

Both write the five STLs and a `report.txt` (overall size, thinnest wall/hole, FDM-vs-resin
verdict) into `out/`. To export one part by hand:

```bash
openscad -o base.stl -D 'part="base"' -D 'coupling="heatset"' braillegen.scad
```

## Parameters (the forks)

Grouped exactly as the OpenSCAD Customizer shows them. Everything is overridable on the CLI with `-D`.

**Taxel array** — `n_rings` (1→7, 2→19, 3→37 taxels), `pitch` (2.5 mm), `taxel_dia`,
`taxel_depth`, `rim`, `outline` (`hex`/`round`).

**Membrane** — `membrane` (`flat`/`curved`), `mem_thick`, `dome_rise` (curved apex).

**Tube coupling** — `coupling` (`barb`/`heatset`), `tube_id`, `tube_od`, `channel_dia`;
barb-only: `barb_len`, `barb_ridges`; heat-set-only: `heatset_dia` (printed insert pilot Ø),
`heatset_len`.

**Base** — `base_h` (auto-raised if the fan-out needs more), `plug_h`.

**Mould** — `mould_wall_t`, `mould_clear`, `mould_floor_h`, `mould_wall_h` (0 = auto).

**Output** — `part`, `cut` (slice for previewing channels), `$fn`.

## Printing notes

- The console/`report.txt` **resin verdict** keys off the smallest feature. With 1 mm taxels,
  ~0.8 mm membrane and ~0.8 mm channels you are below ~1 mm everywhere — **print the `tip` and
  `base` in resin/SLA** (Form 3 etc.). FDM is fine for the mould and pin tool.
- Resin that contacts platinum-cure silicone must be **fully UV-cured + IPA-washed** first, or it
  inhibits the cure. (See the guide.)
- **Barb caveat:** a barb has to fit *inside* the tube, so its bore can't approach the tube ID. If
  `channel_dia` ≳ `tube_id − 0.5` the report shows a near-zero barb wall — drop `channel_dia`, or
  use the `heatset` coupling instead (it isn't size-limited that way). Default `tube_id=1.0` +
  `channel_dia=0.8` deliberately trips this so the warning is visible.
- `$fn` drives both quality and render time: the `base` CSG is the slow part (~5 s at `$fn=28`,
  ~1 min at 48). Export at 36–48; preview lower.

## Roadmap

- Arbitrary face outline: lay taxels on the same lattice, then crop the hex packing to any 2-D
  shape (`outline` already abstracts hex vs round — a polygon mask slots in here).
- A web sub-page on the guide exposing `cavity Ø`, `pitch`, etc. as live controls.
