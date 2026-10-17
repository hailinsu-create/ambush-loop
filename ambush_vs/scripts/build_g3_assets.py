#!/usr/bin/env python3
"""Deterministic G3 asset pipeline: cut/key/seamless/downscale source → assets/g3/.

Source (project-owned AI art): ambush_vs/assets/g3/src/
Outputs WebP/PNG under ambush_vs/assets/g3/ for the greybox (small Web pck).
"""
from __future__ import annotations

import json
import math
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]  # ambush_vs/
SRC = ROOT / "assets" / "g3" / "src"
OUT = ROOT / "assets" / "g3"
TILE_PX = 256
PROP_PX = 192
UNIT_PX = 128
ICON_PX = 128
MAGENTA = np.array([255, 0, 255], dtype=np.float32)
SEED = 20261017


def ensure_dirs() -> None:
	for sub in (
		"tiles",
		"props",
		"units",
		"weapons/icons",
		"fx",
		"masks",
	):
		(OUT / sub).mkdir(parents=True, exist_ok=True)


def save_webp(im: Image.Image, rel: str, quality: int = 82) -> Path:
	path = OUT / rel
	path.parent.mkdir(parents=True, exist_ok=True)
	# Prefer WebP for size; keep alpha.
	if im.mode != "RGBA":
		im = im.convert("RGBA")
	im.save(path, "WEBP", quality=quality, method=4)
	print(f"wrote {rel} {im.size} {path.stat().st_size}B")
	return path


def save_png(im: Image.Image, rel: str) -> Path:
	path = OUT / rel
	path.parent.mkdir(parents=True, exist_ok=True)
	im.save(path, "PNG", optimize=True)
	print(f"wrote {rel} {im.size}")
	return path


def crop_square_center(im: Image.Image) -> Image.Image:
	w, h = im.size
	side = min(w, h)
	x0 = (w - side) // 2
	y0 = (h - side) // 2
	return im.crop((x0, y0, x0 + side, y0 + side))


def make_seamless(im: Image.Image, size: int = TILE_PX) -> Image.Image:
	"""Offset half + blend edges for tileable square (deterministic)."""
	sq = crop_square_center(im.convert("RGB")).resize((size, size), Image.Resampling.LANCZOS)
	arr = np.asarray(sq).astype(np.float32)
	half = size // 2
	# roll by half
	rolled = np.roll(np.roll(arr, half, axis=0), half, axis=1)
	# soft cross-blend using distance from seam
	yy, xx = np.mgrid[0:size, 0:size]
	# distance to nearest wrap edge after roll (center is seamless join)
	dx = np.minimum(xx, size - 1 - xx).astype(np.float32)
	dy = np.minimum(yy, size - 1 - yy).astype(np.float32)
	# blend band near center cross of rolled image
	band = 28.0
	wx = np.clip(1.0 - (np.abs(xx - half) / band), 0.0, 1.0)
	wy = np.clip(1.0 - (np.abs(yy - half) / band), 0.0, 1.0)
	w = np.maximum(wx, wy)[..., None]
	out = arr * (1.0 - w) + rolled * w
	# slight contrast unify
	out = np.clip(out, 0, 255).astype(np.uint8)
	return Image.fromarray(out, "RGB").convert("RGBA")


def chroma_key_magenta(im: Image.Image, thresh: float = 70.0, soft: float = 35.0) -> Image.Image:
	"""Key #FF00FF with despill + soft edge. Returns RGBA."""
	rgba = im.convert("RGBA")
	arr = np.asarray(rgba).astype(np.float32)
	rgb = arr[..., :3]
	# distance to magenta in RGB
	dist = np.linalg.norm(rgb - MAGENTA, axis=-1)
	# also catch near-magenta (high R+B, low G)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	magentaish = (r > 180) & (b > 180) & (g < 120) & ((r + b) > g * 2.5)
	dist = np.where(magentaish, np.minimum(dist, 40.0), dist)
	alpha = np.clip((dist - thresh) / soft, 0.0, 1.0)
	# despill: pull magenta cast toward neutral on fringe
	spill = np.clip(1.0 - (dist / (thresh + soft * 2)), 0.0, 1.0)[..., None]
	neutral = np.mean(rgb, axis=-1, keepdims=True)
	rgb = rgb * (1.0 - 0.65 * spill) + neutral * (0.65 * spill)
	# kill leftover magenta pixels
	alpha = np.where(dist < thresh * 0.55, 0.0, alpha)
	out = np.dstack([np.clip(rgb, 0, 255), alpha * 255.0]).astype(np.uint8)
	return Image.fromarray(out, "RGBA")


def bbox_content(im: Image.Image, pad: int = 4) -> Image.Image:
	"""Crop to non-transparent bbox."""
	arr = np.asarray(im)
	a = arr[..., 3]
	ys, xs = np.where(a > 16)
	if len(xs) == 0:
		return im
	x0, x1 = max(0, xs.min() - pad), min(im.width, xs.max() + pad + 1)
	y0, y1 = max(0, ys.min() - pad), min(im.height, ys.max() + pad + 1)
	return im.crop((x0, y0, x1, y1))


def fit_square(im: Image.Image, size: int) -> Image.Image:
	"""Fit content into size×size canvas preserving aspect."""
	im = bbox_content(im)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	im.thumbnail((size - 4, size - 4), Image.Resampling.LANCZOS)
	ox = (size - im.width) // 2
	oy = (size - im.height) // 2
	canvas.paste(im, (ox, oy), im)
	return canvas


def add_team_ring(im: Image.Image, color: tuple[int, int, int, int], width: int = 3) -> Image.Image:
	"""Readable outline/ring so team color stays clear after rotation."""
	out = im.copy()
	# silhouette outline via alpha edge
	a = np.asarray(im.split()[-1])
	mask = Image.fromarray(a, "L")
	edge = mask.filter(ImageFilter.FIND_EDGES).point(lambda v: 255 if v > 20 else 0)
	edge = edge.filter(ImageFilter.MaxFilter(width * 2 + 1))
	ring = Image.new("RGBA", im.size, (0, 0, 0, 0))
	ring.paste(color, mask=edge)
	return Image.alpha_composite(ring, out)


def sheet_cells(im: Image.Image, cols: int, rows: int) -> list[Image.Image]:
	cw, ch = im.width // cols, im.height // rows
	cells = []
	for r in range(rows):
		for c in range(cols):
			cells.append(im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)))
	return cells


def cut_weapons(im: Image.Image) -> list[Image.Image]:
	"""Five weapons on dark bg in a row — matte dark background."""
	rgb = np.asarray(im.convert("RGB")).astype(np.float32)
	# luminance; weapons are brighter than near-black bg
	lum = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
	# also distance from near-black
	dark = np.linalg.norm(rgb, axis=-1)
	alpha = np.clip((np.maximum(lum, dark) - 28.0) / 30.0, 0.0, 1.0)
	# soften
	alpha_img = Image.fromarray((alpha * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.2))
	alpha = np.asarray(alpha_img).astype(np.float32) / 255.0
	rgba = np.dstack([rgb, alpha * 255]).astype(np.uint8)
	full = Image.fromarray(rgba, "RGBA")
	# split into 5 equal columns
	cells = sheet_cells(full, 5, 1)
	out = []
	for cell in cells:
		out.append(fit_square(cell, ICON_PX))
	return out


def soft_edge_masks(size: int = 64) -> dict[str, Image.Image]:
	"""Soft blend masks for neighbor edge overlays (N/E/S/W)."""
	masks = {}
	for name, axis, flip in (
		("n", 0, False),
		("s", 0, True),
		("w", 1, False),
		("e", 1, True),
	):
		grad = np.zeros((size, size), dtype=np.float32)
		band = size // 3
		if axis == 0:  # vertical gradient
			for i in range(band):
				v = 1.0 - (i / float(band))
				if name == "n":
					grad[i, :] = v
				else:
					grad[size - 1 - i, :] = v
		else:
			for i in range(band):
				v = 1.0 - (i / float(band))
				if name == "w":
					grad[:, i] = v
				else:
					grad[:, size - 1 - i] = v
		masks[name] = Image.fromarray((grad * 255).astype(np.uint8), "L")
	return masks


def make_lantern_glow(size: int = 72) -> Image.Image:
	"""Small warm localized glow (not map-washing discs)."""
	im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	cx = cy = size // 2
	for r, a in ((size // 2, 22), (size // 3, 48), (size // 6, 120), (5, 210)):
		d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 150, 40, a))
	return im


def make_drop_shadow(size: int = 96) -> Image.Image:
	im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	d.ellipse((10, 20, size - 6, size - 4), fill=(0, 0, 0, 100))
	return im.filter(ImageFilter.GaussianBlur(5))


def make_high_edge_trim(size: int = 64) -> Image.Image:
	"""Thin warm edge trim for high-tier readability (ADR-HEIGHT)."""
	im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	d.rectangle((1, 1, size - 2, size - 2), outline=(255, 214, 96, 200), width=2)
	return im



def add_roof_detail(im: Image.Image) -> Image.Image:
	"""Keep roof face seamless for world-UV. Ridge/eaves are drawn per-building at runtime.

	Do NOT bake horizontal eaves bands into the tile — with world-space UV those
	repeat every few cells and read as glitchy dark stripes.
	"""
	return im


def moonlight_grade_swatch() -> Image.Image:
	"""Lookup-ish overlay: very light cool wash for docs/contact."""
	im = Image.new("RGBA", (64, 64), (40, 48, 62, 22))
	return im


def build_tiles() -> dict:
	mapping = {
		"mud": "tex_mud.jpg",
		"grass": "tex_grass.jpg",
		"cobble": "tex_cobble.jpg",
		"planks": "tex_planks.jpg",
		"stonewall": "tex_stonewall.jpg",
	}
	meta = {}
	# Per-material lift so mud/grass/cobble stay distinguishable under moonlight.
	boosts = {
		"mud": (1.28, 10.0, (1.18, 0.96, 0.82)),  # warmer brown
		"grass": (1.24, 8.0, (0.85, 1.28, 0.88)),  # greener
		"cobble": (1.26, 12.0, (1.08, 1.04, 0.90)),  # cooler grey, not blue wash
		"planks": (1.20, 10.0, (1.14, 1.00, 0.86)),
		"stonewall": (1.16, 8.0, (1.04, 1.00, 0.94)),
	}
	for name, src_name in mapping.items():
		im = Image.open(SRC / src_name)
		tile = make_seamless(im, TILE_PX)
		mul, add, tint = boosts[name]
		arr = np.asarray(tile).astype(np.float32)
		rgb = arr[..., :3] * mul + add
		rgb *= np.array(tint, dtype=np.float32)
		# Stronger local contrast so mud/grass/cobble separate under moonlight.
		mean = rgb.mean(axis=(0, 1), keepdims=True)
		rgb = mean + (rgb - mean) * 1.28
		arr[..., :3] = np.clip(rgb, 0, 255)
		tile = Image.fromarray(arr.astype(np.uint8), "RGBA")
		save_webp(tile, f"tiles/{name}.webp")
		meta[name] = f"tiles/{name}.webp"

	roof = Image.open(SRC / "tex_roof_slate_left_shingle_right.jpg")
	w, h = roof.size
	left = roof.crop((0, 0, w // 2, h))
	right = roof.crop((w // 2, 0, w, h))

	def _lift_roof(im: Image.Image) -> Image.Image:
		arr = np.asarray(im).astype(np.float32)
		arr[..., :3] = np.clip(arr[..., :3] * 1.18 + 10.0, 0, 255)
		return Image.fromarray(arr.astype(np.uint8), "RGBA")

	slate = add_roof_detail(_lift_roof(make_seamless(left, TILE_PX)))
	shingle = add_roof_detail(_lift_roof(make_seamless(right, TILE_PX)))
	save_webp(slate, "tiles/roof_slate.webp")
	save_webp(shingle, "tiles/roof_shingle.webp")
	meta["roof_slate"] = "tiles/roof_slate.webp"
	meta["roof_shingle"] = "tiles/roof_shingle.webp"

	# aliases for loader convenience
	for alias, src in (
		("tile_ground.webp", "mud.webp"),
		("tile_high.webp", "roof_slate.webp"),
		("tile_wall.webp", "stonewall.webp"),
		("tile_ramp.webp", "planks.webp"),
		("tile_low_cover.webp", "cobble.webp"),
	):
		Image.open(OUT / "tiles" / src).save(OUT / "tiles" / alias, "WEBP", quality=82, method=4)
		print("alias", alias, "<-", src)
	return meta


def chroma_key_magenta_strong(im: Image.Image) -> Image.Image:
	"""Key compressed JPG magenta + purple fringe (despill). Returns RGBA."""
	# Slightly looser thresh for JPEG fringing around #FF00FF.
	return chroma_key_magenta(im, thresh=55.0, soft=48.0)


def cut_sandbag_sheet() -> dict:
	"""Cut dedicated sandbag sheet → straight×3, L, T, end, round pile."""
	src_path = SRC / "sandbag_sheet_magenta.jpg"
	if not src_path.is_file():
		print("WARN missing", src_path)
		return {}
	sheet = Image.open(src_path)
	keyed = chroma_key_magenta_strong(sheet)
	# Hand-tuned content boxes from projection (1280×720 sheet).
	# (name, x0, y0, x1, y1) inclusive-ish; pad applied after.
	boxes = [
		("sandbag_straight_s", 40, 128, 325, 262),
		("sandbag_straight_m", 360, 128, 800, 265),
		("sandbag_straight_l", 808, 125, 1248, 265),
		("sandbag_corner_l", 55, 330, 340, 595),
		("sandbag_junction_t", 365, 340, 725, 595),
		("sandbag_end_cap", 760, 365, 910, 600),
		("sandbag_pile_round", 970, 365, 1220, 605),
	]
	meta: dict = {}
	for name, x0, y0, x1, y1 in boxes:
		cell = keyed.crop((x0, y0, x1, y1))
		cell = bbox_content(cell, pad=6)
		# Preserve aspect on transparent canvas (do not stretch bags).
		# Straights stay wide; piles stay roughly square.
		pw, ph = cell.size
		max_side = 256 if "straight" in name or "junction" in name or "corner" in name else 192
		scale = min(max_side / max(pw, 1), max_side / max(ph, 1), 1.0)
		# Upscale small cuts a bit for phone readability.
		if max(pw, ph) < 180:
			scale = max_side / max(pw, ph)
		nw, nh = max(1, int(pw * scale)), max(1, int(ph * scale))
		cell = cell.resize((nw, nh), Image.Resampling.LANCZOS)
		canvas = Image.new("RGBA", (nw + 8, nh + 8), (0, 0, 0, 0))
		canvas.paste(cell, (4, 4), cell)
		# Cool night grade: slight blue rim / darker burlap to match moonlight scene.
		arr = np.asarray(canvas).astype(np.float32)
		rgb, a = arr[..., :3], arr[..., 3:4] / 255.0
		rgb = rgb * np.array([0.92, 0.94, 1.02], dtype=np.float32)
		rgb = np.clip(rgb * 0.90, 0, 255)
		out = np.dstack([rgb, arr[..., 3]]).astype(np.uint8)
		prop = Image.fromarray(out, "RGBA")
		save_webp(prop, f"props/{name}.webp", quality=88)
		meta[name] = f"props/{name}.webp"
	# Legacy aliases used by older paths / W3 checks.
	if "sandbag_straight_m" in meta:
		Image.open(OUT / meta["sandbag_straight_m"]).save(OUT / "props/sandbag_straight.webp", "WEBP", quality=88, method=4)
		meta["sandbag_straight"] = "props/sandbag_straight.webp"
	if "sandbag_corner_l" in meta:
		Image.open(OUT / meta["sandbag_corner_l"]).save(OUT / "props/sandbag_curve.webp", "WEBP", quality=88, method=4)
		meta["sandbag_curve"] = "props/sandbag_curve.webp"
	return meta


def build_props() -> dict:
	sheet = Image.open(SRC / "props_sheet_magenta.jpg")
	keyed = chroma_key_magenta(sheet)
	cells = sheet_cells(keyed, 4, 2)
	names = [
		"sandbag_curve",
		"sandbag_straight",
		"ammo_crate",
		"crate_stack",
		"barrel",
		"hay_bale",
		"cart",
		"shed_roof",
	]
	meta = {}
	for name, cell in zip(names, cells):
		# Skip legacy sandbags — replaced by dedicated sheet below.
		if name.startswith("sandbag_"):
			continue
		prop = fit_square(cell, PROP_PX)
		save_webp(prop, f"props/{name}.webp", quality=85)
		meta[name] = f"props/{name}.webp"
	meta.update(cut_sandbag_sheet())
	return meta


def build_units() -> dict:
	sheet = Image.open(SRC / "units_sheet_magenta.jpg")
	keyed = chroma_key_magenta(sheet, thresh=65.0, soft=40.0)
	cells = sheet_cells(keyed, 4, 2)
	# top: partisans, bottom: germans
	names = [
		"friendly_kar98k",
		"friendly_mp40",
		"friendly_mg42",
		"friendly_grenade",
		"enemy_rifle",
		"enemy_smg",
		"enemy_mg",
		"enemy_officer",
	]
	meta = {}
	for i, (name, cell) in enumerate(zip(names, cells)):
		u = fit_square(cell, UNIT_PX)
		if i < 4:
			u = add_team_ring(u, (70, 160, 255, 230), width=3)
		else:
			u = add_team_ring(u, (220, 70, 60, 230), width=3)
		save_webp(u, f"units/{name}.webp", quality=85)
		meta[name] = f"units/{name}.webp"
	# mine has no unit — reuse ammo crate silhouette note in meta
	return meta


def build_weapons() -> dict:
	sheet = Image.open(SRC / "weapons_sheet.jpg")
	icons = cut_weapons(sheet)
	ids = ["kar98k", "mp40", "mg42", "grenade", "mine"]
	meta = {}
	for wid, icon in zip(ids, icons):
		# dark padded card bg for UI readability
		card = Image.new("RGBA", (ICON_PX, ICON_PX), (24, 26, 30, 255))
		d = ImageDraw.Draw(card)
		d.rounded_rectangle((2, 2, ICON_PX - 3, ICON_PX - 3), radius=12, outline=(180, 170, 130, 255), width=2)
		card.paste(icon, (0, 0), icon)
		save_webp(card, f"weapons/icons/{wid}.webp", quality=88)
		# transparent sprite for map (no card)
		save_webp(icon, f"weapons/sprites/{wid}.webp", quality=88)
		meta[wid] = f"weapons/icons/{wid}.webp"
	return meta


def build_fx() -> dict:
	save_webp(make_lantern_glow(72), "fx/lantern_glow.webp", quality=80)
	save_webp(make_drop_shadow(96), "fx/drop_shadow.webp", quality=80)
	save_webp(make_high_edge_trim(64), "fx/high_edge.webp", quality=90)
	save_webp(moonlight_grade_swatch(), "fx/moonlight_tint.webp", quality=80)
	# vignette (white=keep, black=darken) stored as alpha mask style
	size = 256
	vig = Image.new("L", (size, size), 0)
	px = vig.load()
	cx = cy = size / 2
	for y in range(size):
		for x in range(size):
			dx = (x - cx) / cx
			dy = (y - cy) / cy
			r = math.sqrt(dx * dx + dy * dy)
			v = int(np.clip((r - 0.82) / 0.50, 0, 1) * 42)
			px[x, y] = v
	vig_rgba = Image.merge("RGBA", (Image.new("L", (size, size), 6), Image.new("L", (size, size), 8), Image.new("L", (size, size), 18), vig))
	save_webp(vig_rgba, "fx/vignette.webp", quality=80)
	masks = soft_edge_masks(64)
	for k, m in masks.items():
		rgba = Image.merge("RGBA", (m, m, m, m))
		save_webp(rgba, f"masks/edge_{k}.webp", quality=90)
	return {"lantern": "fx/lantern_glow.webp", "vignette": "fx/vignette.webp"}


def contact_sheet(paths: list[tuple[str, str]]) -> None:
	cols = 6
	thumb = 96
	pad = 8
	label_h = 16
	rows = math.ceil(len(paths) / cols)
	W = cols * (thumb + pad) + pad
	H = rows * (thumb + label_h + pad) + pad + 28
	sheet = Image.new("RGBA", (W, H), (16, 18, 22, 255))
	d = ImageDraw.Draw(sheet)
	try:
		font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
		title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
	except OSError:
		font = ImageFont.load_default()
		title = font
	d.text((pad, 6), "Ambush VS G3 assets (project-owned source → pipeline)", fill=(220, 210, 180), font=title)
	for i, (label, rel) in enumerate(paths):
		p = OUT / rel
		if not p.is_file():
			continue
		im = Image.open(p).convert("RGBA")
		im.thumbnail((thumb, thumb), Image.Resampling.LANCZOS)
		r, c = divmod(i, cols)
		x = pad + c * (thumb + pad)
		y = 28 + pad + r * (thumb + label_h + pad)
		bg = Image.new("RGBA", (thumb, thumb), (30, 32, 36, 255))
		bg.paste(im, ((thumb - im.width) // 2, (thumb - im.height) // 2), im)
		sheet.paste(bg, (x, y))
		d.text((x, y + thumb + 1), label[:18], fill=(180, 180, 170), font=font)
	# contact sheet as PNG for artifacts (not in web export)
	save_png(sheet, "contact_sheet.png")


def write_manifest(meta: dict) -> None:
	manifest = {
		"schema": 1,
		"gate": "G3-art-batch",
		"source": "assets/g3/src/",
		"license": "project-owned (owner image tool for Ambush Loop)",
		"pipeline": "scripts/build_g3_assets.py",
		"tile_px": TILE_PX,
		"outputs": meta,
	}
	path = OUT / "manifest.json"
	path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print("wrote manifest.json")


def main() -> None:
	if not SRC.is_dir():
		raise SystemExit(f"missing source dir {SRC}")
	ensure_dirs()
	meta: dict = {}
	meta["tiles"] = build_tiles()
	meta["props"] = build_props()
	meta["units"] = build_units()
	meta["weapons"] = build_weapons()
	meta["fx"] = build_fx()
	write_manifest(meta)

	paths: list[tuple[str, str]] = []
	for k, v in meta["tiles"].items():
		paths.append((k, v))
	for k, v in meta["props"].items():
		paths.append((k, v))
	for k, v in meta["units"].items():
		paths.append((k, v))
	for k, v in meta["weapons"].items():
		paths.append((f"w_{k}", v))
	paths.append(("lantern", "fx/lantern_glow.webp"))
	paths.append(("vignette", "fx/vignette.webp"))
	contact_sheet(paths)
	print("G3 build DONE →", OUT)


if __name__ == "__main__":
	main()
