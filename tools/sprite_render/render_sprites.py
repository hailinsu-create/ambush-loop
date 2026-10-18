#!/usr/bin/env python3
"""Headless Blender sprite-sheet renderer: 3D animated model -> fixed-pitch 8-direction 2D sprites.

Run inside Blender:
    blender -b --factory-startup -P render_sprites.py -- --input model.glb --actions Idle --out out

Only standard Blender + numpy are used (no PIL). RGBA PNGs are written by a small
built-in encoder so colour management stays under our control.
"""

import argparse
import json
import math
import os
import struct
import sys
import time
import zlib

import bpy
import numpy as np
from mathutils import Vector

# --------------------------------------------------------------------------- #
# constants / helpers
# --------------------------------------------------------------------------- #

DIR8_NAMES = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]
FORWARD_AZIMUTH = {"+X": 0.0, "+Y": 90.0, "-X": 180.0, "-Y": 270.0}
EXCLUDED_COLLECTIONS = {"glTF_not_exported"}


def log(msg):
    print(msg, flush=True)


def fmt_num(v):
    v = float(v)
    if v.is_integer():
        return str(int(v))
    return ("%g" % v)


# --------------------------------------------------------------------------- #
# tiny PNG writer (8-bit RGBA, no interlace)
# --------------------------------------------------------------------------- #

def write_png(path, arr):
    """arr: HxWx4 uint8 with top-left origin."""
    h, w, _ = arr.shape
    arr = np.ascontiguousarray(arr)
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0
        raw += arr[y].tobytes()

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


# --------------------------------------------------------------------------- #
# argument parsing
# --------------------------------------------------------------------------- #

def parse_args(argv):
    ap = argparse.ArgumentParser(prog="render_sprites.py", add_help=True)
    ap.add_argument("--input", required=False)
    ap.add_argument("--actions", default=None, help="comma separated action names (default: all)")
    ap.add_argument("--list-actions", action="store_true")
    ap.add_argument("--frames", type=int, default=8)
    ap.add_argument("--frames-map", default=None, help="e.g. Idle=4,Walking=6")
    ap.add_argument("--pitch", type=float, default=60.0)
    ap.add_argument("--dirs", type=int, default=8)
    ap.add_argument("--size", type=int, default=96)
    ap.add_argument("--ssaa", type=int, default=4)
    ap.add_argument("--engine", default="EEVEE", choices=["EEVEE", "CYCLES", "WORKBENCH"])
    ap.add_argument("--samples", type=int, default=None)
    ap.add_argument("--threads", type=int, default=0)
    ap.add_argument("--light", default="night")
    ap.add_argument("--shadow", dest="shadow", action="store_true", default=False)
    ap.add_argument("--no-shadow", dest="shadow", action="store_false")
    ap.add_argument("--forward", default="-Y", choices=["+X", "-X", "+Y", "-Y"])
    ap.add_argument("--out", default=".")
    ap.add_argument("--name", default=None)
    ap.add_argument("--margin", type=float, default=0.06)
    ap.add_argument("--ortho-scale", type=float, default=None)
    ap.add_argument("--anchor-y", type=float, default=None,
                    help="anchor (world origin) vertical position as canvas fraction; "
                         "default: auto tight framing (anchor computed and written to JSON)")
    ap.add_argument("--anchor-x", type=float, default=0.5)
    ap.add_argument("--lock-root", dest="lock_root", action="store_true", default=True)
    ap.add_argument("--no-lock-root", dest="lock_root", action="store_false")
    ap.add_argument("--oneshot", nargs="?", const="__ALL__", default=None,
                    help="comma list of non-looping actions, or empty for all")
    ap.add_argument("--also-frames", action="store_true")
    ap.add_argument("--no-fallback", action="store_true")
    args = ap.parse_args(argv)
    return args


# --------------------------------------------------------------------------- #
# scene setup / import
# --------------------------------------------------------------------------- #

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_model(path):
    ext = os.path.splitext(path)[1].lower()
    before = set(bpy.data.objects)
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        raise RuntimeError("unsupported input extension: %s" % ext)
    after = set(bpy.data.objects)
    return [o for o in after if o not in before]


def cleanup_objects():
    """Delete every object that is not part of the freshly imported model.

    The Blender 5.x glTF importer injects an unrelated 'Icosphere' helper into a
    collection named 'glTF_not_exported'; such objects must never be rendered.
    """
    doomed = set()
    for coll in bpy.data.collections:
        if coll.name in EXCLUDED_COLLECTIONS:
            for o in coll.objects:
                doomed.add(o)
    for o in list(bpy.data.objects):
        if o in doomed:
            bpy.data.objects.remove(o, do_unlink=True)
    # also nuke the helper collection if now empty
    for coll in list(bpy.data.collections):
        if coll.name in EXCLUDED_COLLECTIONS:
            bpy.data.collections.remove(coll)


def find_armature(objs):
    for o in objs:
        if o.type == "ARMATURE":
            return o
    for o in bpy.data.objects:
        if o.type == "ARMATURE":
            return o
    return None


def root_bone_name(arm):
    if arm is None:
        return None
    for b in arm.data.bones:
        if b.parent is None:
            return b.name
    return None


def make_turntable(roots):
    tt = bpy.data.objects.new("Turntable", None)
    tt.empty_display_size = 0.5
    bpy.context.scene.collection.objects.link(tt)
    for o in roots:
        o.parent = tt
        o.matrix_parent_inverse = tt.matrix_world.inverted()
    return tt


# --------------------------------------------------------------------------- #
# camera
# --------------------------------------------------------------------------- #

def camera_basis(pitch_deg):
    p = math.radians(pitch_deg)
    right = Vector((1.0, 0.0, 0.0))
    up = Vector((0.0, math.sin(p), math.cos(p)))
    fwd = Vector((0.0, math.cos(p), -math.sin(p)))
    return right, up, fwd


def build_camera(pitch_deg):
    cam_data = bpy.data.cameras.new("SpriteCam")
    cam_data.type = "ORTHO"
    cam_data.clip_start = 0.01
    cam_data.clip_end = 1000.0
    cam = bpy.data.objects.new("SpriteCam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.rotation_euler = (math.radians(90.0 - pitch_deg), 0.0, 0.0)
    bpy.context.scene.camera = cam
    return cam


def place_camera(cam, ortho_scale, anchor_x, anchor_y, pitch_deg):
    right, up, fwd = camera_basis(pitch_deg)
    c_h = (anchor_x - 0.5) * ortho_scale
    c_v = (anchor_y - 0.5) * ortho_scale
    cam.data.ortho_scale = ortho_scale
    cam.location = right * c_h + up * c_v - fwd * 50.0


def fit_scale(hmin, hmax, vmin, vmax, axr, ayr, margin):
    """Ortho scale so all projected content stays inside the canvas margins."""
    # px = (axr + h/S)*size , py = (ayr - v/S)*size
    req = 0.0
    constraints = [
        (hmax, (1.0 - margin) - axr),   # right edge
        (-hmin, axr - margin),          # left edge
        (vmax, ayr - margin),           # top edge (v up -> py small)
        (-vmin, (1.0 - margin) - ayr),  # bottom edge
    ]
    for extent, avail in constraints:
        if extent <= 0.0:
            continue
        if avail <= 1e-6:
            raise RuntimeError("margin leaves no room on one side; reduce --margin")
        req = max(req, extent / avail)
    if req <= 0.0:
        req = 1.0
    return req


# --------------------------------------------------------------------------- #
# lighting preset
# --------------------------------------------------------------------------- #

LIGHT_PRESETS = {
    "night": {
        "world_color": (0.02, 0.03, 0.06),
        "world_strength": 0.6,
        "key": {
            "type": "SUN",
            "color": (0.75, 0.82, 1.00),
            "strength": 3.0,
            # light travels from upper-left-front (screen left, toward camera side)
            "dir": (0.455, 0.455, -0.766),
            "angle_deg": 3.0,
        },
        "fill": {
            "type": "SUN",
            "color": (1.00, 0.80, 0.55),
            "strength": 0.45,  # ~15% of key
            "dir": (-0.55, -0.55, -0.63),  # from right-rear, above
        },
        "rim": {
            "type": "SUN",
            "color": (0.65, 0.78, 1.00),
            "strength": 0.5,
            "dir": (0.0, -0.72, -0.70),  # from behind-above (north, top)
        },
    }
}


def apply_world(preset):
    world = bpy.data.worlds.new("SpriteWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        col = preset["world_color"]
        bg.inputs[0].default_value = (col[0], col[1], col[2], 1.0)
        bg.inputs[1].default_value = preset["world_strength"]
    world.color = preset["world_color"]


def add_sun(name, spec):
    d = Vector(spec["dir"]).normalized()
    ld = bpy.data.lights.new(name, type="SUN")
    ld.color = spec["color"]
    ld.energy = spec["strength"]
    if "angle_deg" in spec:
        ld.angle = math.radians(spec["angle_deg"])
    obj = bpy.data.objects.new(name, ld)
    obj.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(obj)
    return obj


def apply_lights(preset):
    lights = []
    for key in ("key", "fill", "rim"):
        if key in preset:
            lights.append(add_sun("L_" + key, preset[key]))
    return lights


# --------------------------------------------------------------------------- #
# render configuration
# --------------------------------------------------------------------------- #

ENGINE_IDS = {
    "EEVEE": "BLENDER_EEVEE",
    "CYCLES": "CYCLES",
    "WORKBENCH": "BLENDER_WORKBENCH",
}


def configure_render(args, size_px):
    sc = bpy.context.scene
    sc.render.resolution_x = size_px
    sc.render.resolution_y = size_px
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    sc.render.image_settings.compression = 15
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.0
    sc.view_settings.gamma = 1.0
    if args.threads and args.threads > 0:
        sc.render.threads_mode = "FIXED"
        sc.render.threads = args.threads
    else:
        sc.render.threads_mode = "AUTO"


def set_engine(engine):
    sc = bpy.context.scene
    eid = ENGINE_IDS[engine]
    sc.render.engine = eid
    if engine == "CYCLES":
        sc.cycles.use_denoising = True
        try:
            sc.cycles.denoiser = "OPENIMAGEDENOISE"
        except Exception:
            pass
        samples = 32
        if ARGS.samples:
            samples = ARGS.samples
        sc.cycles.samples = samples
        sc.cycles.use_adaptive_sampling = True
    elif engine == "EEVEE":
        samples = 16
        if ARGS.samples:
            samples = ARGS.samples
        if hasattr(sc, "eevee") and hasattr(sc.eevee, "taa_render_samples"):
            sc.eevee.taa_render_samples = samples
    elif engine == "WORKBENCH":
        disp = sc.display
        disp.shading.light = "STUDIO"
        disp.shading.color_type = "MATERIAL"
        disp.shading.show_shadows = True
        disp.shading.show_cavity = True
        disp.shading.cavity_type = "WORLD"
        try:
            disp.render_aa = "8"
        except Exception:
            pass
    return eid


# --------------------------------------------------------------------------- #
# geometry evaluation
# --------------------------------------------------------------------------- #

def gather_world_verts():
    dg = bpy.context.evaluated_depsgraph_get()
    arrs = []
    for o in bpy.data.objects:
        if o.type != "MESH" or o.hide_render:
            continue
        oe = o.evaluated_get(dg)
        try:
            me = oe.to_mesh()
        except Exception:
            continue
        n = len(me.vertices)
        if n == 0:
            oe.to_mesh_clear()
            continue
        co = np.empty(n * 3, dtype=np.float64)
        me.vertices.foreach_get("co", co)
        co = co.reshape(n, 3)
        mw = np.array(oe.matrix_world)
        world = co @ mw[:3, :3].T + mw[:3, 3]
        arrs.append(world)
        oe.to_mesh_clear()
    if not arrs:
        return np.zeros((0, 3))
    return np.concatenate(arrs, axis=0)


def project(world, pitch_deg):
    p = math.radians(pitch_deg)
    h = world[:, 0]
    v = world[:, 1] * math.sin(p) + world[:, 2] * math.cos(p)
    return h, v


# --------------------------------------------------------------------------- #
# pose configuration
# --------------------------------------------------------------------------- #

class Rig:
    def __init__(self, tt, arm, root_bone, args):
        self.tt = tt
        self.arm = arm
        self.root_bone = root_bone
        self.args = args

    def set_pose(self, action, phi_deg, frame):
        sc = bpy.context.scene
        if action is not None and self.arm is not None:
            if self.arm.animation_data is None:
                self.arm.animation_data_create()
            self.arm.animation_data.action = action
            self._pick_slot(action)
        if frame is not None:
            fi = int(math.floor(frame))
            sc.frame_set(fi, subframe=frame - fi)
        self.tt.rotation_euler = (0.0, 0.0, math.radians(phi_deg))
        self.tt.location = (0.0, 0.0, 0.0)
        bpy.context.view_layer.update()
        if self.args.lock_root and self.arm is not None and self.root_bone:
            pb = self.arm.pose.bones[self.root_bone]
            rw = self.arm.matrix_world @ pb.head
            self.tt.location = (-rw.x, -rw.y, 0.0)
            bpy.context.view_layer.update()

    def _pick_slot(self, action):
        try:
            slots = getattr(action, "slots", None)
            if slots:
                want = None
                for s in slots:
                    nm = getattr(s, "name_display", "") or getattr(s, "name", "")
                    if self.arm and self.arm.name in str(nm):
                        want = s
                        break
                if want is None:
                    want = slots[0]
                self.arm.animation_data.action_slot = want
        except Exception:
            pass


# --------------------------------------------------------------------------- #
# render + downsample
# --------------------------------------------------------------------------- #

def render_highres(tmp_path):
    sc = bpy.context.scene
    sc.render.filepath = tmp_path
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(tmp_path)
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    arr = px.reshape(h, w, 4)[::-1]  # to top-left origin
    return arr


def downsample_premult(arr, factor):
    if factor <= 1:
        out = arr
    else:
        h, w, _ = arr.shape
        hh, ww = h // factor, w // factor
        a = arr[..., 3:4]
        prem = np.concatenate([arr[..., :3] * a, a], axis=2)
        prem = prem[: hh * factor, : ww * factor]
        blocks = prem.reshape(hh, factor, ww, factor, 4).mean(axis=(1, 3))
        a2 = blocks[..., 3:4]
        rgb = blocks[..., :3] / np.maximum(a2, 1e-6)
        out = np.concatenate([rgb, a2], axis=2)
    out = np.clip(out, 0.0, 1.0)
    return (out * 255.0 + 0.5).astype(np.uint8)


def analyze_alpha(arr):
    a = arr[..., 3]
    n = int((a > 0.02).sum())
    if n == 0:
        return n, 0.0
    vis = arr[..., :3][a > 0.02]
    return n, float(vis.max())


# --------------------------------------------------------------------------- #
# timing accumulator
# --------------------------------------------------------------------------- #

class Timer:
    def __init__(self):
        self.total = 0.0
        self.frames = 0
        self.per_action = {}

    def add(self, action_name, dt):
        self.total += dt
        self.frames += 1
        self.per_action.setdefault(action_name, []).append(dt)


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #

ARGS = None


def select_actions(all_actions, names):
    if not names:
        return list(all_actions)
    by_name = {a.name: a for a in all_actions}
    out = []
    for n in names:
        n = n.strip()
        if not n:
            continue
        if n not in by_name:
            raise RuntimeError("action not found: %r (available: %s)"
                               % (n, ", ".join(by_name)))
        out.append(by_name[n])
    return out


def is_loop(action, oneshot_set):
    name = action.name.lower()
    if "__ALL__" in oneshot_set:
        return False
    if action.name in oneshot_set:
        return False
    if any(k in name for k in ("death", "die", "hit")):
        return False
    return True


def sample_frames(start, end, count, loop):
    count = max(1, int(count))
    if end <= start:
        return [start]
    if count == 1:
        return [start]
    if loop:
        return [start + (end - start) * i / count for i in range(count)]
    return [start + (end - start) * i / (count - 1) for i in range(count)]


def dir_name_order(dirs):
    if dirs == 8:
        return list(DIR8_NAMES)
    return ["D%d" % k for k in range(dirs)]


def main():
    global ARGS
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    ARGS = parse_args(argv)

    if not ARGS.input:
        raise SystemExit("--input is required")
    inp = os.path.abspath(ARGS.input)
    if not os.path.isfile(inp):
        raise SystemExit("input not found: %s" % inp)

    name = ARGS.name or os.path.splitext(os.path.basename(inp))[0]
    out_dir = os.path.abspath(ARGS.out)
    os.makedirs(out_dir, exist_ok=True)

    # --- import ---
    reset_scene()
    import_model(inp)
    cleanup_objects()

    all_actions = list(bpy.data.actions)
    if ARGS.list_actions:
        for a in all_actions:
            fr = a.frame_range
            loop = is_loop(a, set())
            log("ACTION %s %.4f %.4f %s" % (a.name, fr[0], fr[1], "loop" if loop else "oneshot"))
        return

    oneshot_set = set()
    if ARGS.oneshot is not None:
        if ARGS.oneshot == "__ALL__":
            oneshot_set = {"__ALL__"}
        else:
            oneshot_set = {s.strip() for s in ARGS.oneshot.split(",") if s.strip()}

    frames_map = {}
    if ARGS.frames_map:
        for part in ARGS.frames_map.split(","):
            if "=" in part:
                k, v = part.split("=", 1)
                frames_map[k.strip()] = int(v)

    req_names = ARGS.actions.split(",") if ARGS.actions else None
    actions = select_actions(all_actions, req_names)
    if not actions:
        raise SystemExit("no actions to render")

    # --- turntable ---
    roots = [o for o in bpy.data.objects if o.parent is None and o.type != "CAMERA" and o.type != "LIGHT"]
    tt = make_turntable(roots)
    arm = find_armature(list(bpy.data.objects))
    root_bone = root_bone_name(arm)

    # --- camera + lights ---
    cam = build_camera(ARGS.pitch)
    preset = LIGHT_PRESETS.get(ARGS.light)
    if preset:
        apply_world(preset)
        apply_lights(preset)

    size = int(ARGS.size)
    ssaa = max(1, int(ARGS.ssaa))
    render_px = size * ssaa
    configure_render(ARGS, render_px)

    rig = Rig(tt, arm, root_bone, ARGS)

    fwd_az = FORWARD_AZIMUTH[ARGS.forward]
    dir_names = dir_name_order(ARGS.dirs)
    dir_angles = [k * 360.0 / ARGS.dirs for k in range(ARGS.dirs)]
    phis = [(dir_angles[k] - fwd_az) % 360.0 for k in range(ARGS.dirs)]

    # per-action sample plan
    plan = []
    for a in actions:
        fr = a.frame_range
        n = frames_map.get(a.name, ARGS.frames)
        loop = is_loop(a, oneshot_set)
        samples = sample_frames(fr[0], fr[1], n, loop)
        plan.append((a, loop, samples))

    # --- framing pass ---
    t_frame0 = time.perf_counter()
    hmin = vmin = math.inf
    hmax = vmax = -math.inf
    for (a, loop, samples) in plan:
        for frame in samples:
            for k in range(ARGS.dirs):
                rig.set_pose(a, phis[k], frame)
                wv = gather_world_verts()
                if len(wv) == 0:
                    continue
                h, v = project(wv, ARGS.pitch)
                hmin = min(hmin, float(h.min()))
                hmax = max(hmax, float(h.max()))
                vmin = min(vmin, float(v.min()))
                vmax = max(vmax, float(v.max()))
    if not math.isfinite(hmin):
        hmin = hmax = vmin = vmax = 0.0

    if ARGS.ortho_scale:
        ortho = float(ARGS.ortho_scale)
        if ARGS.anchor_y is None:
            ARGS.anchor_y = 0.85
    elif ARGS.anchor_y is not None:
        ortho = fit_scale(hmin, hmax, vmin, vmax, ARGS.anchor_x, ARGS.anchor_y, ARGS.margin)
    else:
        # auto tight framing: keep the anchor horizontally at anchor_x (symmetric
        # extent so the pivot is stable across directions), centre the vertical
        # extent, and derive anchor_y from the union bbox of every frame/direction.
        half_h = max(abs(hmin), abs(hmax))
        span = max(2.0 * half_h, vmax - vmin)
        ortho = span / max(1e-6, 1.0 - 2.0 * ARGS.margin)
        vc = 0.5 * (vmin + vmax)
        ARGS.anchor_y = 0.5 + vc / ortho
    place_camera(cam, ortho, ARGS.anchor_x, ARGS.anchor_y, ARGS.pitch)
    bpy.context.view_layer.update()
    log("FRAMING h[%.4f,%.4f] v[%.4f,%.4f] ortho_scale=%.6f" % (hmin, hmax, vmin, vmax, ortho))
    log("FRAMING pass seconds=%.2f" % (time.perf_counter() - t_frame0))

    # --- resolve engine ---
    requested = ARGS.engine
    actual = requested
    first_action, first_loop, first_samples = plan[0]
    tmp_render = os.path.join(out_dir, ".sprite_tmp_render.png")
    shadow_enabled = False

    def probe(engine):
        set_engine(engine)
        rig.set_pose(first_action, phis[0], first_samples[0])
        a = render_highres(tmp_render)
        n, mx = analyze_alpha(a)
        return n, mx

    if requested == "EEVEE" and not ARGS.no_fallback:
        n, mx = probe("EEVEE")
        if n == 0 or mx < 0.02:
            log("WARNING EEVEE produced empty/dark output (px=%d max=%.4f); falling back to CYCLES" % (n, mx))
            actual = "CYCLES"
            n, mx = probe("CYCLES")
            if n == 0 or mx < 0.02:
                log("WARNING CYCLES produced empty/dark output (px=%d max=%.4f); falling back to WORKBENCH" % (n, mx))
                actual = "WORKBENCH"
                n, mx = probe("WORKBENCH")
        log("ENGINE resolved=%s (px=%d max=%.4f)" % (actual, n, mx))
    else:
        set_engine(requested)

    # shadow catcher only makes sense with Cycles
    if ARGS.shadow and actual == "CYCLES":
        sc = bpy.context.scene
        bpy.ops.mesh.primitive_plane_add(size=100.0, location=(0.0, 0.0, 0.0))
        plane = bpy.context.object
        plane.name = "ShadowCatcher"
        plane.is_shadow_catcher = True
        shadow_enabled = True
    elif ARGS.shadow:
        log("NOTE shadow requested but engine=%s cannot do transparent shadow catcher; shadow=false" % actual)

    # --- render pass ---
    timer = Timer()
    sheet_paths = {}
    actions_meta = {}

    for (a, loop, samples) in plan:
        cols = len(samples)
        rows = ARGS.dirs
        sheet = np.zeros((rows * size, cols * size, 4), dtype=np.uint8)
        frames_meta = []
        action_t0 = time.perf_counter()
        for k in range(rows):
            for i, frame in enumerate(samples):
                t0 = time.perf_counter()
                rig.set_pose(a, phis[k], frame)
                scheme = render_highres(tmp_render)
                tile = downsample_premult(scheme, ssaa)
                dt = time.perf_counter() - t0
                timer.add(a.name, dt)
                sheet[k * size:(k + 1) * size, i * size:(i + 1) * size] = tile
                if ARGS.also_frames:
                    fdir = os.path.join(out_dir, "frames", a.name)
                    os.makedirs(fdir, exist_ok=True)
                    write_png(os.path.join(fdir, "%s_%d.png" % (dir_names[k], i)), tile)
                x, y = i * size, k * size
                frames_meta.append({
                    "dir": k,
                    "dir_name": dir_names[k],
                    "col": i,
                    "source_frame": float(frame),
                    "rect": [x, y, size, size],
                })
                log("FRAME %s %d %d %.4f" % (a.name, k, i, dt))
        sheet_name = "%s_p%s_%s.png" % (name, fmt_num(ARGS.pitch), a.name)
        write_png(os.path.join(out_dir, sheet_name), sheet)
        sheet_paths[a.name] = sheet_name

        scene_fps = bpy.context.scene.render.fps / max(1e-6, bpy.context.scene.render.fps_base)
        fps = scene_fps
        span = float(a.frame_range[1]) - float(a.frame_range[0])
        if span > 0:
            dur = span / scene_fps
            if loop:
                fps = len(samples) / dur
            else:
                fps = (len(samples) - 1) / dur if len(samples) > 1 else scene_fps
        if len(samples) < 2:
            fps = scene_fps
        actions_meta[a.name] = {
            "sheet": sheet_name,
            "rows": rows,
            "cols": cols,
            "loop": loop,
            "fps": round(float(fps), 4),
            "frames": frames_meta,
        }
        action_dt = time.perf_counter() - action_t0
        log("ACTION_DONE %s %.2fs" % (a.name, action_dt))

    # cleanup temp
    try:
        if os.path.isfile(tmp_render):
            os.remove(tmp_render)
    except Exception:
        pass

    anchor_px = [round(ARGS.anchor_x * size, 3), round(ARGS.anchor_y * size, 3)]
    per_action_avg = {k: round(sum(v) / len(v), 4) for k, v in timer.per_action.items() if v}

    meta = {
        "source": os.path.basename(inp),
        "pitch_deg": ARGS.pitch,
        "engine": actual,
        "engine_id": ENGINE_IDS[actual],
        "engine_requested": requested,
        "samples": (ARGS.samples if ARGS.samples else (32 if actual == "CYCLES" else 16)),
        "ssaa": ssaa,
        "frame_size": [size, size],
        "anchor_px": anchor_px,
        "ortho_scale": round(float(ortho), 6),
        "light_preset": ARGS.light,
        "shadow": bool(shadow_enabled),
        "forward_axis": ARGS.forward,
        "lock_root": bool(ARGS.lock_root),
        "dir_order": dir_names,
        "dir_angle_deg": dir_angles,
        "actions": actions_meta,
        "timing": {
            "total_render_s": round(timer.total, 4),
            "frames_rendered": timer.frames,
            "avg_s_per_frame": round(timer.total / timer.frames, 4) if timer.frames else 0.0,
            "per_action_avg_s": per_action_avg,
        },
        "blender_version": bpy.app.version_string,
    }
    meta_path = os.path.join(out_dir, "%s_p%s.json" % (name, fmt_num(ARGS.pitch)))
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

    log("SUMMARY total=%.2fs frames=%d avg=%.4fs ortho=%.6f engine=%s" %
        (timer.total, timer.frames, meta["timing"]["avg_s_per_frame"], ortho, actual))
    log("SUMMARY wrote %s" % meta_path)


if __name__ == "__main__":
    main()
