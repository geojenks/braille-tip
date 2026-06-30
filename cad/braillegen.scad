// braillegen.scad — parametric Braille-tip / BraillePen CAD generator
// =====================================================================
// A single parametric source that emits every printable part of a
// Braille-tip sensor, sized from a handful of design variables. It mirrors
// the build "forks" in the hand-off guide (https://geojenks.github.io/braille-tip/):
//
//   * Taxel array      — a centred-hexagonal lattice. n_rings drives the count:
//                        rings 1 -> 7, 2 -> 19, 3 -> 37 ... (3r^2+3r+1).
//   * Membrane         — flat or curved (fingertip-domed) sensing face.
//   * Tube coupling    — printed BARBS (tube slips over) or HEAT-SET inserts
//                        (push-fit coupler screws in). Both need tube ID/OD;
//                        heat-set also needs the insert pilot diameter.
//
// The taxels sit at 2.5 mm pitch but tubes/inserts are far bigger, so the
// rigid base is a FRUSTUM: channels fan down-and-out from the tight taxel grid
// to a coarser coupling grid on the underside. The minimum coupling pitch and
// the base height are derived automatically from the chosen fitting so the
// channels never collide and never leave the body.
//
// Parts emitted (choose with `part`):
//   tip          — soft sensor body for DIRECT SILICONE PRINTING (taxel cavities,
//                  flat/curved membrane, channels, plug spigot).
//   base         — rigid channel base with the chosen couplings (FDM or resin).
//   pin_tool     — pin/extruder tool that forms the taxel cavities (CAST route).
//   mould_floor  — tray floor for the cast route.
//   mould_wall   — dam ring that contains the silicone pour.
//   all          — every part laid out side by side (preview / sanity check).
//
// Headless export (one STL per part), e.g.:
//   openscad -o tip.stl  -D 'part="tip"'  braillegen.scad
//   openscad -o base.stl -D 'part="base"' -D 'coupling="heatset"' braillegen.scad
// A print-readiness report (overall size, thinnest wall/hole, FDM-vs-resin
// verdict) is echoed to the console on every render. See export_all.* / README.
// =====================================================================

/* [Taxel array] */
// taxel rings out from centre (1 -> 7 taxels, 2 -> 19, 3 -> 37 ...)
n_rings     = 2;     // [1:1:5]
// taxel centre-to-centre spacing (mm) — 2.5 matches Braille dot pitch
pitch       = 2.5;
// taxel cavity diameter (mm)
taxel_dia   = 1.0;
// taxel cavity depth into the silicone (mm)
taxel_depth = 1.2;
// silicone/base rim left beyond the outermost taxels (mm)
rim         = 1.2;
// sensing-face / base outline
outline     = "hex"; // [hex, round]

/* [Membrane] */
// flat (reads flat Braille) or curved (fingertip dome)
membrane    = "curved"; // [flat, curved]
// silicone thickness over each taxel (mm)
mem_thick   = 0.8;
// apex rise of the curved face above the rim (mm) — ignored when flat
dome_rise   = 0.8;

/* [Tube coupling] */
// printed barbs (tube slips over) or heat-set threaded inserts (push-fit coupler)
coupling    = "barb"; // [barb, heatset]
// tubing inner diameter (mm)
tube_id     = 1.0;
// tubing outer diameter (mm)
tube_od     = 2.0;
// barb length below the base (mm) — barb route only
barb_len    = 5.0;
// number of barb ridges — barb route only
barb_ridges = 2;     // [1:1:4]
// printed pilot-hole diameter the heat-set insert melts into (mm) — heat-set route only
heatset_dia = 4.0;
// heat-set insert depth (mm) — heat-set route only
heatset_len = 5.0;
// fluid channel diameter through the parts (mm)
channel_dia = 0.8;

/* [Base] */
// requested rigid base height (mm); auto-raised if the fan-out needs more
base_h      = 6.0;
// depth the tip's plug spigot sinks into the base (mm)
plug_h      = 2.0;

/* [Mould (cast route)] */
// dam wall thickness (mm)
mould_wall_t  = 2.0;
// clearance between silicone and dam (mm)
mould_clear   = 0.3;
// mould floor thickness (mm)
mould_floor_h = 2.0;
// dam height (mm); 0 = auto from silicone thickness
mould_wall_h  = 0;

/* [Output] */
part        = "all"; // [all, tip, base, pin_tool, mould_floor, mould_wall]
// preview only: slice the part on the XZ plane to reveal internal channels
cut         = false; // [false, true]
$fn         = 48;

// ---- advisory limits used by the report / resin verdict ----
WALL_MIN_OK = 1.0;   // walls/holes below this -> resin recommended
FEAT_RESIN  = 1.0;   // features below this -> resin strongly recommended
FIT_CLEAR   = 0.15;  // plug<->socket clearance (mm)

// =====================================================================
//  Geometry helpers
// =====================================================================
assert(n_rings >= 1, "n_rings must be >= 1 (at least 7 taxels)");

// centred-hexagonal lattice in axial coords, deterministic order
function axial_pts(R) = [ for (q=[-R:R]) for (r=[-R:R]) if (abs(q+r) <= R) [q,r] ];
function ax2xy(a, p)  = [ p*(a[0] + a[1]/2), p*(sqrt(3)/2)*a[1] ];
function lattice(R,p) = [ for (a=axial_pts(R)) ax2xy(a,p) ];
function max_r(pts)   = max([ for (p=pts) norm(p) ]);

taxels   = lattice(n_rings, pitch);
nt       = len(taxels);

// sensing-face / tip footprint radius (circumradius for hex outline)
face_r   = max_r(taxels) + taxel_dia/2 + rim;

// minimum coupling pitch so neighbouring fittings + walls fit
coupl_w     = (coupling == "barb") ? tube_od : heatset_dia;     // fitting footprint
min_cpitch  = coupl_w + 2*WALL_MIN_OK;
cpitch      = max(pitch, min_cpitch);
couplings   = lattice(n_rings, cpitch);                          // index-matched to taxels
coupl_r     = max_r(couplings) + coupl_w/2 + rim;               // base underside radius

// auto base height: keep fan-out angle <= ~45 deg and clear the socket floor
max_horiz   = max_r(taxels) * (cpitch/pitch - 1);
base_h_min  = plug_h + max_horiz + 1.0;
base_h_eff  = max(base_h, base_h_min);

// tip vertical bookkeeping (z=0 at tip bottom / plug base)
base_pad    = 0.8;                                  // silicone below the cavities
core_h      = base_pad + taxel_depth + mem_thick;   // silicone thickness (plug top -> flat face)
z_cav_floor = plug_h + base_pad;
z_face_flat = plug_h + core_h;
plug_r      = max(face_r - 1.2, face_r*0.6);

// dome sphere for the curved face: meets z_face_flat at r=face_r, rises dome_rise at centre
dome_R      = (face_r*face_r + dome_rise*dome_rise) / (2*dome_rise);

// =====================================================================
//  Primitive modules
// =====================================================================
// hex (circumradius r) or round slab, h tall, sitting on its own z=0
module slab(r, h) {
    if (outline == "hex") cylinder(h=h, r=r, $fn=6);
    else                  cylinder(h=h, r=r);
}

// align +z to vector v, then draw children
module orient(v) {
    L  = norm(v);
    vn = v / max(L, 1e-9);
    ax = cross([0,0,1], vn);
    la = norm(ax);
    if (la < 1e-9) { if (vn[2] < 0) rotate([180,0,0]) children(); else children(); }
    else rotate(acos(vn[2]), ax) children();
}

// solid cylinder from p1 to p2
module seg(p1, p2, d) {
    translate(p1) orient(p2 - p1) cylinder(h=norm(p2-p1), d=d, $fn=24);
}

// =====================================================================
//  TIP — soft body for direct silicone printing (or the cast result shape)
// =====================================================================
module tip_outer() {                       // body above the plug, starts at its own z=0
    if (membrane == "flat") {
        slab(face_r, core_h);
    } else {
        union() {
            slab(face_r, core_h);
            translate([0,0,core_h]) intersection() {
                translate([0,0,dome_rise - dome_R]) sphere(r=dome_R, $fn=max($fn,96));
                slab(face_r, dome_rise + 0.01);
            }
        }
    }
}

module part_tip() {
    difference() {
        union() {
            slab(plug_r, plug_h);                       // plug spigot
            translate([0,0,plug_h]) tip_outer();        // sensing body (+dome)
        }
        // sealed taxel cavities (mem_thick of silicone left above each)
        for (t = taxels)
            translate([t[0], t[1], z_cav_floor]) cylinder(h=taxel_depth, d=taxel_dia);
        // channels: cavity floor down through the plug bottom
        for (t = taxels)
            translate([t[0], t[1], -0.1]) cylinder(h=z_cav_floor + 0.2, d=channel_dia);
    }
}

// =====================================================================
//  BASE — rigid channel frustum with the chosen couplings
// =====================================================================
module base_body() {                       // frustum: tip footprint on top, coupling footprint on bottom
    hull() {
        translate([0,0,base_h_eff - 0.01]) slab(face_r,  0.01);
        slab(coupl_r, 0.01);
    }
}

module coupling_solid() {                  // sits at a coupling xy, grows downward from z=0
    if (coupling == "barb") {
        cylinder(h=plug_h, d=tube_id + 1.6);                       // small collar into the body
        for (k = [0:barb_ridges-1]) {
            seg_h = barb_len / barb_ridges;
            zt = -k * seg_h;
            translate([0,0,zt - seg_h])
                cylinder(h=seg_h, d1=tube_id - 0.3, d2=tube_id + 0.4); // wide toward base = retention
        }
        translate([0,0,-barb_len]) cylinder(h=barb_len, d=tube_id - 0.2); // stem core
    } else {
        translate([0,0,-heatset_len]) cylinder(h=heatset_len + plug_h, d=heatset_dia + 2.4); // boss
    }
}

module coupling_bore() {                   // through-bore for a coupling at its xy
    if (coupling == "barb") {
        translate([0,0,-barb_len - 0.2]) cylinder(h=barb_len + 0.4, d=channel_dia);
    } else {
        translate([0,0,-heatset_len - 0.2]) cylinder(h=heatset_len + 0.4, d=heatset_dia); // insert pilot
    }
}

module part_base() {
    difference() {
        union() {
            base_body();
            for (c = couplings) translate([c[0], c[1], 0]) coupling_solid();
        }
        // plug socket recessed into the top
        translate([0,0,base_h_eff - plug_h]) slab(plug_r + FIT_CLEAR, plug_h + 0.1);
        // fan-out channels: coupling (bottom) -> taxel inlet at the socket floor
        for (i = [0:nt-1])
            seg([couplings[i][0], couplings[i][1], -0.1],
                [taxels[i][0],   taxels[i][1],   base_h_eff - plug_h + 0.1], channel_dia);
        // coupling through-bores
        for (c = couplings) translate([c[0], c[1], 0]) coupling_bore();
    }
}

// =====================================================================
//  CAST-ROUTE tooling
// =====================================================================
module part_pin_tool() {                   // plate + pins that emboss the taxel cavities
    plate_r = face_r + 2;
    union() {
        slab(plate_r, 2);
        for (t = taxels)
            translate([t[0], t[1], -taxel_depth]) cylinder(h=taxel_depth, d=taxel_dia);
    }
}

sil_th = core_h + plug_h;                  // silicone thickness for the dam height
wall_h_eff = (mould_wall_h > 0) ? mould_wall_h : sil_th + 1.0;

module part_mould_floor() {
    slab(face_r + mould_clear + mould_wall_t, mould_floor_h);
}

module part_mould_wall() {
    difference() {
        slab(face_r + mould_clear + mould_wall_t, wall_h_eff);
        translate([0,0,-0.1]) slab(face_r + mould_clear, wall_h_eff + 0.2);
    }
}

// =====================================================================
//  Print-readiness report
// =====================================================================
barb_stem_wall = (coupling == "barb") ? (tube_id - 0.2 - channel_dia)/2 : 99;
min_wall = min(mem_thick, base_pad, rim, barb_stem_wall);
min_hole = channel_dia;
min_feat = min(taxel_dia, channel_dia, mem_thick);
resin_verdict =
    (min_feat < FEAT_RESIN) ? "RESIN/SLA strongly recommended (sub-1mm features)" :
    (min_feat < 1.5)        ? "Resin recommended; FDM marginal" :
                              "FDM OK (resin still finer)";

echo(str("================ braillegen report ================"));
echo(str("taxels             : ", nt, "  (", n_rings, " ring(s))"));
echo(str("sensing face        : ", outline, ", ", 2*face_r, " mm across, membrane=", membrane,
         (membrane=="curved") ? str(" rise ", dome_rise, " mm") : ""));
echo(str("coupling            : ", coupling, "  (tube ", tube_id, "/", tube_od, " mm",
         (coupling=="heatset") ? str(", insert pilot ", heatset_dia, " mm") : "", ")"));
echo(str("coupling pitch       : ", cpitch, " mm  -> base underside ", 2*coupl_r, " mm across"));
echo(str("base height          : ", base_h_eff, " mm",
         (base_h_eff > base_h) ? str("  (auto-raised from ", base_h, " for fan-out)") : ""));
echo(str("tip height           : ", z_face_flat + ((membrane=="curved")?dome_rise:0), " mm"));
echo(str("thinnest wall        : ", min_wall, " mm   thinnest hole: ", min_hole, " mm"));
echo(str("PRINT VERDICT        : ", resin_verdict));
echo(str("==================================================="));

// =====================================================================
//  Dispatch
// =====================================================================
module layout_all() {
    s = 2*coupl_r + 8;
    translate([-1.5*s,0,0]) part_tip();
    translate([-0.5*s,0,0]) part_base();
    translate([ 0.5*s,0,0]) part_pin_tool();
    translate([ 1.5*s,0,0]) part_mould_floor();
    translate([ 2.5*s,0,0]) part_mould_wall();
}

module dispatch() {
    if      (part == "tip")         part_tip();
    else if (part == "base")        part_base();
    else if (part == "pin_tool")    part_pin_tool();
    else if (part == "mould_floor") part_mould_floor();
    else if (part == "mould_wall")  part_mould_wall();
    else                            layout_all();
}

if (cut) {
    R = 4*coupl_r;
    difference() { dispatch(); translate([-R, 0, -R]) cube([2*R, R, 2*R]); }
} else dispatch();
