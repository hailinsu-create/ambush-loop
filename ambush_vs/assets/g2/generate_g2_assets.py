#!/usr/bin/env python3
"""Generate G2 yard / weapon / contact-sheet PNGs. Pillow + numpy only. CC0 originals."""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
SEED = 20261017


# Night WWII yard palette — muted, readable under orange cones / yellow high edges.
PAL = {
	"night_sky": (18, 22, 28),
	"dirt": (62, 52, 38),
	"dirt_var": (74, 60, 42),
	"mud": (48, 42, 36),
	"mud_shine": (58, 52, 44),
	"cobble": (54, 56, 60),
	"cobble_mortar": (36, 38, 42),
	"grass": (42, 54, 36),
	"grass_blade": (52, 68, 42),
	"wall": (34, 36, 40),
	"wall_edge": (22, 24, 28),
	"fence": (70, 58, 42),
	"fence_post": (48, 40, 30),
	"high": (40, 42, 50),
	"high_edge": (255, 210, 40),
	"high_roof": (32, 34, 40),
	"ramp": (68, 62, 48),
	"shed": (58, 48, 38),
	"shed_roof": (44, 40, 48),
	"crate": (92, 70, 42),
	"crate_band": (50, 40, 28),
	"sandbag": (96, 86, 58),
	"sandbag_seam": (70, 62, 42),
	"prop_outline": (12, 12, 14),
	"metal": (72, 76, 70),
	"metal_dark": (40, 44, 40),
	"wood": (86, 64, 40),
	"icon_bg": (28, 30, 34),
	"icon_ring": (180, 170, 130),
}


def rng(seed: int = SEED) -> np.random.Generator:
	return np.random.default_rng(seed)


def save(im: Image.Image, rel: str) -> None:
	path = os.path.join(ROOT, rel)
	os.makedirs(os.path.dirname(path), exist_ok=True)
	im.save(path, "PNG", optimize=True)
	print("wrote", rel, im.size)


def transparent(w: int, h: int) -> Image.Image:
	return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def noise_tile(base: tuple, var: tuple, cell: int, seed: int, amount: float = 0.35) -> Image.Image:
	g = rng(seed)
	arr = np.zeros((cell, cell, 4), dtype=np.uint8)
	for y in range(cell):
		for x in range(cell):
			t = float(g.random()) * amount
			r = int(base[0] * (1 - t) + var[0] * t)
			gg = int(base[1] * (1 - t) + var[1] * t)
			b = int(base[2] * (1 - t) + var[2] * t)
			# slight vignette for night readability (darker edges)
			edge = min(x, y, cell - 1 - x, cell - 1 - y) / (cell * 0.5)
			shade = 0.82 + 0.18 * max(0.0, min(1.0, edge))
			arr[y, x] = (int(r * shade), int(gg * shade), int(b * shade), 255)
	return Image.fromarray(arr, "RGBA")


def make_dirt(cell: int = 64) -> Image.Image:
	im = noise_tile(PAL["dirt"], PAL["dirt_var"], cell, SEED + 1, 0.45)
	d = ImageDraw.Draw(im)
	g = rng(SEED + 11)
	for _ in range(40):
		x, y = int(g.integers(0, cell)), int(g.integers(0, cell))
		d.point((x, y), fill=(40, 34, 26, 180))
	d.rectangle((0, 0, cell - 1, cell - 1), outline=(40, 34, 26, 90), width=1)
	return im


def make_mud(cell: int = 64) -> Image.Image:
	im = noise_tile(PAL["mud"], PAL["mud_shine"], cell, SEED + 2, 0.5)
	d = ImageDraw.Draw(im)
	g = rng(SEED + 12)
	for _ in range(6):
		x0, y0 = int(g.integers(4, cell - 8)), int(g.integers(4, cell - 8))
		d.ellipse((x0, y0, x0 + 14, y0 + 8), fill=(38, 34, 30, 160))
	return im


def make_cobble(cell: int = 64) -> Image.Image:
	im = Image.new("RGBA", (cell, cell), PAL["cobble_mortar"] + (255,))
	d = ImageDraw.Draw(im)
	g = rng(SEED + 3)
	bw, bh = 14, 10
	for row, y in enumerate(range(2, cell, bh + 2)):
		ox = 0 if row % 2 == 0 else bw // 2
		for x in range(ox, cell, bw + 2):
			c = (
				PAL["cobble"][0] + int(g.integers(-8, 9)),
				PAL["cobble"][1] + int(g.integers(-8, 9)),
				PAL["cobble"][2] + int(g.integers(-6, 7)),
				255,
			)
			d.rounded_rectangle((x, y, min(x + bw, cell - 2), min(y + bh, cell - 2)), radius=2, fill=c)
	# night darken
	overlay = Image.new("RGBA", (cell, cell), (0, 0, 20, 50))
	im = Image.alpha_composite(im, overlay)
	return im


def make_grass(cell: int = 64) -> Image.Image:
	im = noise_tile(PAL["grass"], PAL["grass_blade"], cell, SEED + 4, 0.4)
	d = ImageDraw.Draw(im)
	g = rng(SEED + 14)
	for _ in range(55):
		x, y = int(g.integers(0, cell)), int(g.integers(0, cell))
		d.line((x, y, x + int(g.integers(-2, 3)), y - int(g.integers(2, 6))), fill=PAL["grass_blade"] + (200,), width=1)
	return im


def make_wall(cell: int = 64) -> Image.Image:
	im = Image.new("RGBA", (cell, cell), PAL["wall"] + (255,))
	d = ImageDraw.Draw(im)
	for y in range(0, cell, 10):
		d.line((0, y, cell, y), fill=PAL["wall_edge"] + (180,), width=1)
	for x in range(0, cell, 16):
		d.line((x, 0, x, cell), fill=PAL["wall_edge"] + (120,), width=1)
	d.rectangle((0, 0, cell - 1, cell - 1), outline=(10, 10, 12, 255), width=2)
	return im


def make_fence(cell: int = 64) -> Image.Image:
	im = transparent(cell, cell)
	d = ImageDraw.Draw(im)
	# ground strip so fence sits on dirt-ish night ground
	d.rectangle((0, cell // 2, cell, cell), fill=PAL["dirt"] + (220,))
	for x in (10, 32, 54):
		d.rectangle((x, 10, x + 6, cell - 6), fill=PAL["fence_post"] + (255,))
	for y in (18, 34, 48):
		d.rectangle((6, y, cell - 6, y + 4), fill=PAL["fence"] + (255,))
	d.rectangle((0, 0, cell - 1, cell - 1), outline=PAL["prop_outline"] + (80,), width=1)
	return im


def make_high(cell: int = 64) -> Image.Image:
	"""Rooftop / high-ground tile — yellow silhouette edge must stay readable (ADR-HEIGHT)."""
	im = Image.new("RGBA", (cell, cell), PAL["high_roof"] + (255,))
	d = ImageDraw.Draw(im)
	# roof planks
	for y in range(4, cell - 4, 8):
		d.line((6, y, cell - 6, y), fill=PAL["high"] + (255,), width=2)
	# chimney / ridge mark for silhouette
	d.rectangle((cell // 2 - 4, 8, cell // 2 + 4, 22), fill=(28, 30, 36, 255))
	d.rectangle((2, 2, cell - 3, cell - 3), outline=PAL["high_edge"] + (255,), width=3)
	return im


def make_ramp(cell: int = 64) -> Image.Image:
	im = Image.new("RGBA", (cell, cell), PAL["dirt"] + (255,))
	d = ImageDraw.Draw(im)
	d.polygon([(4, cell - 4), (cell - 4, cell - 4), (cell - 4, 14)], fill=PAL["ramp"] + (255,))
	for i in range(5):
		y = cell - 8 - i * 8
		d.line((8 + i * 6, y, cell - 6, y), fill=(50, 46, 34, 200), width=1)
	d.rectangle((0, 0, cell - 1, cell - 1), outline=(40, 36, 28, 120), width=1)
	return im


def make_shed(size: int = 96) -> Image.Image:
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	# isometric-ish top-down footprint
	d.rectangle((18, 28, 78, 82), fill=PAL["shed"] + (255,), outline=PAL["prop_outline"] + (255,), width=2)
	d.polygon([(18, 28), (48, 10), (78, 28)], fill=PAL["shed_roof"] + (255,), outline=PAL["prop_outline"] + (255,))
	d.rectangle((40, 50, 56, 82), fill=(30, 28, 26, 255))  # door
	return im


def make_crate(size: int = 64) -> Image.Image:
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	d.rectangle((12, 16, 52, 52), fill=PAL["crate"] + (255,), outline=PAL["prop_outline"] + (255,), width=2)
	d.rectangle((12, 30, 52, 36), fill=PAL["crate_band"] + (255,))
	d.line((32, 16, 32, 52), fill=PAL["crate_band"] + (255,), width=3)
	return im


def make_sandbag(size: int = 64) -> Image.Image:
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	for i, (x, y) in enumerate([(8, 36), (28, 36), (18, 24), (38, 24)]):
		d.rounded_rectangle((x, y, x + 22, y + 14), radius=5, fill=PAL["sandbag"] + (255,), outline=PAL["sandbag_seam"] + (255,), width=1)
	return im


def make_barrel(size: int = 48) -> Image.Image:
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	d.ellipse((10, 8, 38, 40), fill=PAL["metal"] + (255,), outline=PAL["prop_outline"] + (255,), width=2)
	d.ellipse((16, 14, 32, 22), fill=PAL["metal_dark"] + (255,))
	return im


def make_ammo_box(size: int = 48) -> Image.Image:
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	d.rectangle((8, 14, 40, 38), fill=(70, 78, 52, 255), outline=PAL["prop_outline"] + (255,), width=2)
	d.rectangle((14, 10, 34, 16), fill=PAL["metal"] + (255,))
	return im


# --- Weapons (ids match weapons.csv) ---

WEAPON_IDS = ["kar98k", "mp40", "mg42", "grenade", "mine"]


def _icon_canvas(size: int = 96) -> tuple[Image.Image, ImageDraw.ImageDraw]:
	im = Image.new("RGBA", (size, size), PAL["icon_bg"] + (255,))
	d = ImageDraw.Draw(im)
	d.rounded_rectangle((3, 3, size - 4, size - 4), radius=14, outline=PAL["icon_ring"] + (255,), width=3)
	return im, d


def icon_kar98k() -> Image.Image:
	im, d = _icon_canvas()
	# long bolt rifle silhouette (top-down collectible)
	d.rectangle((14, 44, 82, 52), fill=PAL["wood"] + (255,))
	d.rectangle((70, 46, 88, 50), fill=PAL["metal"] + (255,))  # barrel
	d.rectangle((28, 40, 40, 56), fill=PAL["wood"] + (255,))  # stock
	d.ellipse((48, 42, 58, 54), fill=PAL["metal_dark"] + (255,))  # bolt knob
	return im


def icon_mp40() -> Image.Image:
	im, d = _icon_canvas()
	d.rectangle((22, 46, 74, 54), fill=PAL["metal"] + (255,))
	d.rectangle((18, 42, 30, 58), fill=PAL["metal_dark"] + (255,))  # stock folded
	d.rectangle((40, 54, 50, 72), fill=PAL["metal_dark"] + (255,))  # mag
	d.rectangle((66, 48, 82, 52), fill=PAL["metal"] + (220,))
	return im


def icon_mg42() -> Image.Image:
	im, d = _icon_canvas()
	d.rectangle((16, 44, 80, 54), fill=PAL["metal"] + (255,))
	d.rectangle((70, 46, 90, 52), fill=PAL["metal_dark"] + (255,))  # barrel
	d.polygon([(30, 54), (50, 54), (46, 78), (34, 78)], fill=PAL["metal_dark"] + (255,))  # bipod
	d.rectangle((40, 36, 56, 44), fill=(90, 70, 40, 255))  # ammo belt box
	return im


def icon_grenade() -> Image.Image:
	"""Stielhandgranate — stick grenade prop."""
	im, d = _icon_canvas()
	d.rectangle((44, 18, 52, 62), fill=PAL["wood"] + (255,))  # stick
	d.ellipse((34, 56, 62, 84), fill=PAL["metal"] + (255,), outline=PAL["prop_outline"] + (255,), width=2)
	d.rectangle((46, 12, 50, 20), fill=PAL["metal_dark"] + (255,))  # cap
	return im


def icon_mine() -> Image.Image:
	"""Tellermine — flat circular AT mine."""
	im, d = _icon_canvas()
	d.ellipse((18, 22, 78, 78), fill=PAL["metal_dark"] + (255,), outline=(160, 150, 90, 255), width=3)
	d.ellipse((34, 38, 62, 66), fill=PAL["metal"] + (255,))
	d.ellipse((44, 48, 52, 56), fill=(200, 180, 80, 255))  # fuse well
	return im


ICON_FUNCS = {
	"kar98k": icon_kar98k,
	"mp40": icon_mp40,
	"mg42": icon_mg42,
	"grenade": icon_grenade,
	"mine": icon_mine,
}


def sprite_from_icon(icon: Image.Image, size: int = 64) -> Image.Image:
	"""Top-down map prop: crop content onto transparent cell."""
	im = transparent(size, size)
	# re-draw simplified without heavy icon chrome
	return icon.resize((size, size), Image.Resampling.LANCZOS)


def unit_with_weapon(weapon_id: str, size: int = 64) -> Image.Image:
	"""Top-down friendly unit silhouette holding / near weapon prop."""
	im = transparent(size, size)
	d = ImageDraw.Draw(im)
	body = (70, 140, 220, 255)
	d.ellipse((18, 16, 46, 48), fill=body, outline=(0, 0, 0, 200), width=2)
	d.polygon([(46, 32), (58, 26), (58, 38)], fill=body)  # facing
	# tiny weapon accent by id
	if weapon_id == "kar98k":
		d.line((40, 30, 60, 22), fill=PAL["wood"] + (255,), width=3)
	elif weapon_id == "mp40":
		d.line((40, 32, 56, 28), fill=PAL["metal"] + (255,), width=3)
		d.line((48, 32, 48, 42), fill=PAL["metal_dark"] + (255,), width=2)
	elif weapon_id == "mg42":
		d.line((36, 34, 60, 30), fill=PAL["metal"] + (255,), width=4)
	elif weapon_id == "grenade":
		d.ellipse((48, 36, 58, 46), fill=PAL["metal"] + (255,))
		d.line((52, 28, 52, 38), fill=PAL["wood"] + (255,), width=2)
	elif weapon_id == "mine":
		d.ellipse((44, 40, 58, 52), fill=PAL["metal_dark"] + (255,), outline=(200, 180, 80, 255), width=1)
	return im


def make_contact_sheet() -> Image.Image:
	tiles = [
		("dirt", "tiles/dirt.png"),
		("mud", "tiles/mud.png"),
		("cobble", "tiles/cobble.png"),
		("grass", "tiles/grass.png"),
		("wall", "tiles/wall.png"),
		("fence", "tiles/fence.png"),
		("high", "tiles/high.png"),
		("ramp", "tiles/ramp.png"),
		("shed", "props/shed.png"),
		("crate", "props/crate.png"),
		("sandbag", "props/sandbag.png"),
		("barrel", "props/barrel.png"),
		("ammo_box", "props/ammo_box.png"),
	]
	for wid in WEAPON_IDS:
		tiles.append((f"icon_{wid}", f"weapons/icons/{wid}.png"))
		tiles.append((f"sprite_{wid}", f"weapons/sprites/{wid}.png"))
		tiles.append((f"unit_{wid}", f"weapons/units/{wid}.png"))

	cols = 6
	thumb = 96
	pad = 8
	label_h = 18
	rows = math.ceil(len(tiles) / cols)
	W = cols * (thumb + pad) + pad
	H = rows * (thumb + label_h + pad) + pad + 28
	sheet = Image.new("RGBA", (W, H), (16, 18, 22, 255))
	d = ImageDraw.Draw(sheet)
	try:
		font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
		title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
	except OSError:
		font = ImageFont.load_default()
		title_font = font
	d.text((pad, 6), "Ambush VS G2 assets (procedural, CC0)", fill=(220, 210, 180, 255), font=title_font)
	for i, (label, rel) in enumerate(tiles):
		path = os.path.join(ROOT, rel)
		if not os.path.isfile(path):
			continue
		im = Image.open(path).convert("RGBA")
		im.thumbnail((thumb, thumb), Image.Resampling.LANCZOS)
		r, c = divmod(i, cols)
		x = pad + c * (thumb + pad)
		y = 28 + pad + r * (thumb + label_h + pad)
		bg = Image.new("RGBA", (thumb, thumb), (30, 32, 36, 255))
		ox = (thumb - im.width) // 2
		oy = (thumb - im.height) // 2
		bg.paste(im, (ox, oy), im)
		sheet.paste(bg, (x, y))
		d.text((x, y + thumb + 2), label, fill=(180, 180, 170, 255), font=font)
	return sheet


def main() -> None:
	save(make_dirt(), "tiles/dirt.png")
	save(make_mud(), "tiles/mud.png")
	save(make_cobble(), "tiles/cobble.png")
	save(make_grass(), "tiles/grass.png")
	save(make_wall(), "tiles/wall.png")
	save(make_fence(), "tiles/fence.png")
	save(make_high(), "tiles/high.png")
	save(make_ramp(), "tiles/ramp.png")
	# aliases matching greybox loader names
	save(make_dirt(), "tiles/tile_ground.png")
	save(make_high(), "tiles/tile_high.png")
	save(make_wall(), "tiles/tile_wall.png")
	save(make_sandbag(), "tiles/tile_low_cover.png")
	save(make_ramp(), "tiles/tile_ramp.png")

	save(make_shed(), "props/shed.png")
	save(make_crate(), "props/crate.png")
	save(make_sandbag(), "props/sandbag.png")
	save(make_barrel(), "props/barrel.png")
	save(make_ammo_box(), "props/ammo_box.png")

	for wid, fn in ICON_FUNCS.items():
		icon = fn()
		save(icon, f"weapons/icons/{wid}.png")
		# top-down prop sprite: transparent, weapon only
		spr = transparent(64, 64)
		# paste icon content scaled without full chrome — draw simplified
		small = icon.resize((56, 56), Image.Resampling.LANCZOS)
		spr.paste(small, (4, 4), small)
		save(spr, f"weapons/sprites/{wid}.png")
		save(unit_with_weapon(wid), f"weapons/units/{wid}.png")

	sheet = make_contact_sheet()
	save(sheet, "contact_sheet.png")
	print("G2 visual assets DONE")


if __name__ == "__main__":
	main()
