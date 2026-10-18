#!/usr/bin/env python3
"""Post-processing for sprite sheets produced by render_sprites.py.

Runs under system python3 (Pillow + numpy), never inside Blender.

Subcommands:
    webp   <sheet.png...> --quality 80 [--method 6] [--alpha-quality 100] [--report r.json]
    strip  <meta.json> --action Idle --col 0 --out strip.png [--scale 2] [--label] [--anchor-cross]
    compare <meta1.json> <meta2.json> <meta3.json> --action Idle --out compare.png
    phone  <meta.json> --action Idle --display-px 48 --out phone.png
    phone-compare <meta1.json> <meta2.json> <meta3.json> --out phone_compare.png [--action Idle] [--display-px 48]
"""

import argparse
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

GROUND = (34, 40, 36)
GRID = (48, 56, 50)
INK = (205, 214, 205)
ANCHOR_COLOR = (230, 80, 200)

PHONE_W = 844
PHONE_H = 390


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #

def load_meta(path):
    with open(path, "r", encoding="utf-8") as f:
        meta = json.load(f)
    return meta, os.path.dirname(os.path.abspath(path))


def frame_index(meta, action):
    """(dir, col) -> rect mapping for an action."""
    act = meta["actions"][action]
    idx = {}
    for fr in act["frames"]:
        idx[(fr["dir"], fr["col"])] = fr
    return idx, act


def load_sheet(meta, base, action):
    sheet = Image.open(os.path.join(base, meta["actions"][action]["sheet"])).convert("RGBA")
    return sheet


def get_frame(meta, base, action, sheet, d, col):
    idx, act = frame_index(meta, action)
    fr = idx[(d, col)]
    x, y, w, h = fr["rect"]
    return sheet.crop((x, y, x + w, y + h))


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def draw_text(img, xy, text, size=14, fill=INK):
    d = ImageDraw.Draw(img)
    d.text(xy, text, font=font(size), fill=fill)


# --------------------------------------------------------------------------- #
# webp
# --------------------------------------------------------------------------- #

def cmd_webp(args):
    report = []
    for path in args.files:
        im = Image.open(path)
        n_pixels = im.width * im.height
        png_bytes = os.path.getsize(path)
        out = os.path.splitext(path)[0] + ".webp"
        save_kwargs = dict(format="WEBP", quality=args.quality, method=args.method)
        if args.alpha_quality is not None:
            save_kwargs["alpha_quality"] = args.alpha_quality
        if args.lossless:
            save_kwargs["lossless"] = True
            save_kwargs.pop("quality", None)
        im.convert("RGBA").save(out, **save_kwargs)
        webp_bytes = os.path.getsize(out)
        kpix = n_pixels / 1000.0
        kb = webp_bytes / 1024.0
        entry = {
            "png": path,
            "webp": out,
            "png_bytes": png_bytes,
            "webp_bytes": webp_bytes,
            "pixels": n_pixels,
            "pixels_k": round(kpix, 3),
            "webp_kb_per_kpixel": round(kb / kpix, 4) if kpix else 0.0,
            "webp_kb": round(kb, 3),
        }
        report.append(entry)
        print("WEBP %s png=%d webp=%d pixels=%d kb/kpix=%.4f"
              % (out, png_bytes, webp_bytes, n_pixels, entry["webp_kb_per_kpixel"]))
    if args.report:
        with open(args.report, "w", encoding="utf-8") as f:
            json.dump({"quality": args.quality, "method": args.method,
                       "alpha_quality": args.alpha_quality, "items": report}, f, indent=2)
        print("WEBP report written %s" % args.report)


# --------------------------------------------------------------------------- #
# strip
# --------------------------------------------------------------------------- #

def cmd_strip(args):
    meta, base = load_meta(args.meta)
    action = args.action
    idx, act = frame_index(meta, action)
    rows = act["rows"]
    if (0, args.col) not in idx:
        raise SystemExit("no frames for col=%d in action %s" % (args.col, action))
    sheet = load_sheet(meta, base, action)
    fw, fh = meta["frame_size"]
    scale = max(1, int(args.scale))
    cw, ch = fw * scale, fh * scale
    label_h = 18 if args.label else 0
    canvas = Image.new("RGBA", (cw * rows, ch + label_h), GROUND + (255,))
    d = ImageDraw.Draw(canvas)
    ax, ay = meta.get("anchor_px", [fw / 2, fh * 0.85])
    for k in range(rows):
        fr = get_frame(meta, base, action, sheet, k, args.col)
        fr = fr.resize((cw, ch), Image.NEAREST)
        canvas.alpha_composite(fr, (k * cw, 0))
        if args.anchor_cross:
            cx = k * cw + ax * scale
            cy = ay * scale
            d.line([(cx - 4 * scale, cy), (cx + 4 * scale, cy)], fill=ANCHOR_COLOR, width=1)
            d.line([(cx, cy - 4 * scale), (cx, cy + 4 * scale)], fill=ANCHOR_COLOR, width=1)
        if args.label:
            name = idx[(k, args.col)].get("dir_name", str(k))
            d.text((k * cw + 6, ch + 3), name, font=font(13), fill=INK)
    canvas.save(args.out)
    print("STRIP wrote %s (%dx%d) action=%s col=%d scale=%d"
          % (args.out, canvas.width, canvas.height, action, args.col, scale))


# --------------------------------------------------------------------------- #
# compare
# --------------------------------------------------------------------------- #

def cmd_compare(args):
    metas = []
    for p in [args.meta1, args.meta2, args.meta3]:
        m, b = load_meta(p)
        metas.append((m, b))
    action = args.action
    fw, fh = metas[0][0]["frame_size"]
    rows = metas[0][0]["actions"][action]["rows"]
    scale = max(1, int(args.scale))
    cw, ch = fw * scale, fh * scale
    label_w = 64
    canvas = Image.new("RGBA", (label_w + cw * rows, ch * 3), GROUND + (255,))
    d = ImageDraw.Draw(canvas)
    for r, (meta, base) in enumerate(metas):
        sheet = load_sheet(meta, base, action)
        pitch = meta.get("pitch_deg", "?")
        y0 = r * ch
        d.text((8, y0 + ch // 2 - 8), "%sdeg" % pitch, font=font(16), fill=INK)
        for k in range(rows):
            fr = get_frame(meta, base, action, sheet, k, args.col)
            fr = fr.resize((cw, ch), Image.NEAREST)
            canvas.alpha_composite(fr, (label_w + k * cw, y0))
        d.line([(0, y0), (canvas.width, y0)], fill=GRID, width=1)
    canvas.save(args.out)
    print("COMPARE wrote %s (%dx%d) action=%s" % (args.out, canvas.width, canvas.height, action))


# --------------------------------------------------------------------------- #
# phone
# --------------------------------------------------------------------------- #

def _bbox_height(frame):
    bbox = frame.getchannel("A").getbbox()
    if not bbox:
        return frame.height
    return max(1, bbox[3] - bbox[1])


def render_phone(meta, base, action, display_px):
    canvas = Image.new("RGBA", (PHONE_W, PHONE_H), GROUND + (255,))
    d = ImageDraw.Draw(canvas)
    for x in range(0, PHONE_W, 36):
        d.line([(x, 0), (x, PHONE_H)], fill=GRID, width=1)
    for y in range(0, PHONE_H, 36):
        d.line([(0, y), (PHONE_W, y)], fill=GRID, width=1)

    rows = meta["actions"][action]["rows"]
    sheet = load_sheet(meta, base, action)
    pitch = meta.get("pitch_deg", "?")
    d.text((10, 8), "pitch %s deg  %s" % (pitch, action), font=font(16), fill=INK)

    # row 1: all dirs share ONE scale so the tallest direction stands display_px
    # high (relative size between directions is preserved); frames are placed so
    # the anchor (feet) sits on the ground line.
    ground1 = 250
    n = rows
    spacing = PHONE_W / (n + 1)
    frames = [get_frame(meta, base, action, sheet, k, 0) for k in range(n)]
    s = display_px / float(max(_bbox_height(fr) for fr in frames))
    ax, ay = meta.get("anchor_px", [frames[0].width / 2, frames[0].height * 0.85])
    for k, fr in enumerate(frames):
        nw, nh = max(1, int(round(fr.width * s))), max(1, int(round(fr.height * s)))
        fr2 = fr.resize((nw, nh), Image.LANCZOS)
        cx = int((k + 1) * spacing)
        canvas.alpha_composite(fr2, (int(round(cx - ax * s)), int(round(ground1 - ay * s))))
    d.text((10, 28), "row 1: %dpx standing height (scale %.3f)" % (display_px, s),
           font=font(12), fill=INK)

    # row 2: three frames at 1:1 native size
    fw, fh = meta["frame_size"]
    picks = [0, n // 2, n - 1]
    ground2 = PHONE_H - 6
    spacing2 = PHONE_W / (len(picks) + 1)
    for i, k in enumerate(picks):
        fr = get_frame(meta, base, action, sheet, k, 0)
        cx = int((i + 1) * spacing2)
        canvas.alpha_composite(fr, (cx - fw // 2, ground2 - fh))
    d.text((10, PHONE_H - 20), "bottom row: 1:1 %dpx" % fw, font=font(12), fill=INK)
    return canvas


def cmd_phone(args):
    meta, base = load_meta(args.meta)
    if args.action not in meta["actions"]:
        raise SystemExit("action %s not in %s" % (args.action, args.meta))
    img = render_phone(meta, base, args.action, args.display_px)
    img.save(args.out)
    print("PHONE wrote %s (%dx%d) action=%s display_px=%d"
          % (args.out, img.width, img.height, args.action, args.display_px))


def cmd_phone_compare(args):
    metas = []
    for p in [args.meta1, args.meta2, args.meta3]:
        m, b = load_meta(p)
        metas.append((m, b))
    imgs = [render_phone(m, b, args.action, args.display_px) for m, b in metas]
    canvas = Image.new("RGBA", (PHONE_W, PHONE_H * len(imgs)), GROUND + (255,))
    for i, im in enumerate(imgs):
        canvas.alpha_composite(im, (0, i * PHONE_H))
    canvas.save(args.out)
    print("PHONE-COMPARE wrote %s (%dx%d)" % (args.out, canvas.width, canvas.height))


# --------------------------------------------------------------------------- #
# argparse
# --------------------------------------------------------------------------- #

def build_parser():
    ap = argparse.ArgumentParser(prog="postprocess.py")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("webp")
    p.add_argument("files", nargs="+")
    p.add_argument("--quality", type=int, default=80)
    p.add_argument("--method", type=int, default=6)
    p.add_argument("--alpha-quality", type=int, default=100)
    p.add_argument("--lossless", action="store_true")
    p.add_argument("--report", default=None)
    p.set_defaults(func=cmd_webp)

    p = sub.add_parser("strip")
    p.add_argument("meta")
    p.add_argument("--action", required=True)
    p.add_argument("--col", type=int, default=0)
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=1)
    p.add_argument("--label", action="store_true")
    p.add_argument("--anchor-cross", action="store_true")
    p.set_defaults(func=cmd_strip)

    p = sub.add_parser("compare")
    p.add_argument("meta1")
    p.add_argument("meta2")
    p.add_argument("meta3")
    p.add_argument("--action", required=True)
    p.add_argument("--col", type=int, default=0)
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=1)
    p.set_defaults(func=cmd_compare)

    p = sub.add_parser("phone")
    p.add_argument("meta")
    p.add_argument("--action", default="Idle")
    p.add_argument("--display-px", type=int, default=48)
    p.add_argument("--out", required=True)
    p.set_defaults(func=cmd_phone)

    p = sub.add_parser("phone-compare")
    p.add_argument("meta1")
    p.add_argument("meta2")
    p.add_argument("meta3")
    p.add_argument("--action", default="Idle")
    p.add_argument("--display-px", type=int, default=48)
    p.add_argument("--out", required=True)
    p.set_defaults(func=cmd_phone_compare)

    return ap


def main():
    ap = build_parser()
    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
