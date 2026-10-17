#!/usr/bin/env python3
"""Regenerate G1 readability PNGs under assets/g1/. Requires Pillow. No paid assets."""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))


def save(im: Image.Image, rel: str) -> None:
	path = os.path.join(ROOT, rel)
	os.makedirs(os.path.dirname(path), exist_ok=True)
	im.save(path, "PNG")
	print("wrote", rel, im.size)


def transparent(w: int, h: int) -> Image.Image:
	return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def alert_icon(label: str, accent: tuple) -> Image.Image:
	im = transparent(96, 96)
	d = ImageDraw.Draw(im)
	d.ellipse((8, 8, 88, 88), fill=(28, 28, 24, 230), outline=accent, width=4)
	try:
		font = ImageFont.truetype(
			"/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
			36 if len(label) < 3 else 28,
		)
	except OSError:
		font = ImageFont.load_default()
	bbox = d.textbbox((0, 0), label, font=font)
	tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
	d.text(((96 - tw) / 2, (96 - th) / 2 - 4), label, fill=accent, font=font)
	return im


def trigger_base():
	im = transparent(96, 96)
	d = ImageDraw.Draw(im)
	d.rounded_rectangle(
		(4, 4, 92, 92), radius=12, fill=(32, 36, 40, 230), outline=(180, 190, 200, 255), width=3
	)
	return im, d


def unit_sil(color, facing_arrow=True):
	im = transparent(64, 64)
	d = ImageDraw.Draw(im)
	d.ellipse((16, 14, 48, 50), fill=color, outline=(0, 0, 0, 200), width=2)
	if facing_arrow:
		d.polygon([(48, 32), (60, 26), (60, 38)], fill=color)
	return im


def main() -> None:
	save(alert_icon("?", (255, 210, 64, 255)), "icons/alert_suspicious.png")
	save(alert_icon("?!", (255, 140, 40, 255)), "icons/alert_area.png")
	save(alert_icon("!", (255, 48, 48, 255)), "icons/alert_global.png")
	im = transparent(96, 96)
	d = ImageDraw.Draw(im)
	d.ellipse((8, 8, 88, 88), fill=(40, 40, 36, 120), outline=(90, 90, 80, 160), width=2)
	save(im, "icons/alert_quiet.png")

	im, d = trigger_base()
	d.ellipse((22, 34, 74, 62), outline=(100, 200, 255, 255), width=3)
	d.ellipse((40, 38, 56, 58), fill=(100, 200, 255, 255))
	save(im, "icons/trigger_see_first_enemy.png")

	im, d = trigger_base()
	d.ellipse((28, 28, 68, 68), fill=(60, 60, 50, 255), outline=(220, 180, 60, 255), width=3)
	d.line((48, 20, 48, 76), fill=(220, 180, 60, 255), width=3)
	d.line((20, 48, 76, 48), fill=(220, 180, 60, 255), width=3)
	save(im, "icons/trigger_mine.png")

	im, d = trigger_base()
	for x in range(16, 80, 12):
		d.line((x, 48, x + 8, 48), fill=(255, 220, 80, 255), width=4)
	d.polygon([(72, 40), (84, 48), (72, 56)], fill=(255, 220, 80, 255))
	save(im, "icons/trigger_cross_marker.png")

	im, d = trigger_base()
	d.ellipse((36, 28, 60, 52), outline=(200, 220, 255, 255), width=3)
	d.rounded_rectangle((42, 48, 54, 78), radius=4, fill=(200, 220, 255, 255))
	save(im, "icons/trigger_manual.png")

	CELL = 64
	im = Image.new("RGBA", (CELL, CELL), (72, 78, 58, 255))
	ImageDraw.Draw(im).rectangle((0, 0, CELL - 1, CELL - 1), outline=(50, 54, 40, 255), width=1)
	save(im, "tiles/tile_ground.png")

	im = Image.new("RGBA", (CELL, CELL), (58, 62, 70, 255))
	d = ImageDraw.Draw(im)
	d.rectangle((2, 2, CELL - 3, CELL - 3), outline=(255, 210, 40, 255), width=3)
	save(im, "tiles/tile_high.png")

	im = Image.new("RGBA", (CELL, CELL), (28, 28, 30, 255))
	ImageDraw.Draw(im).rectangle((0, 0, CELL - 1, CELL - 1), outline=(10, 10, 12, 255), width=2)
	save(im, "tiles/tile_wall.png")

	im = Image.new("RGBA", (CELL, CELL), (90, 70, 50, 255))
	ImageDraw.Draw(im).rectangle((4, CELL // 2, CELL - 5, CELL - 4), fill=(70, 55, 40, 255))
	save(im, "tiles/tile_low_cover.png")

	im = Image.new("RGBA", (CELL, CELL), (80, 76, 55, 255))
	ImageDraw.Draw(im).polygon([(4, CELL - 4), (CELL - 4, CELL - 4), (CELL - 4, 20)], fill=(100, 95, 70, 255))
	save(im, "tiles/tile_ramp.png")

	save(unit_sil((70, 140, 220, 255)), "units/friendly.png")
	save(unit_sil((200, 70, 60, 255)), "units/enemy.png")
	save(unit_sil((220, 160, 50, 255)), "units/sentry.png")
	im = unit_sil((40, 40, 48, 255))
	ImageDraw.Draw(im).ellipse((14, 12, 50, 52), outline=(255, 210, 40, 255), width=3)
	save(im, "units/friendly_high.png")

	W, H = 256, 256
	im = transparent(W, H)
	d = ImageDraw.Draw(im)
	cx, cy = 32, H // 2
	pts = [(cx, cy)]
	for a in range(-25, 26):
		rad = math.radians(a)
		pts.append((cx + 200 * math.cos(rad), cy - H * 0 + cy - 200 * math.sin(rad)))
	# fix: cy - r*sin
	pts = [(cx, cy)]
	for a in range(-25, 26):
		rad = math.radians(a)
		pts.append((cx + 200 * math.cos(rad), cy - 200 * math.sin(rad)))
	d.polygon(pts, fill=(255, 140, 40, 90))
	d.line(pts[1:], fill=(255, 140, 40, 200), width=2)
	save(im, "cones/vision_cone_ground.png")

	im = transparent(W, H)
	d = ImageDraw.Draw(im)
	r_in, r_out = 140, 210
	for a in range(-25, 26):
		rad = math.radians(a)
		x1 = cx + r_in * math.cos(rad)
		y1 = cy - r_in * math.sin(rad)
		x2 = cx + r_out * math.cos(rad)
		y2 = cy - r_out * math.sin(rad)
		if a % 3 == 0:
			d.line([(x1, y1), (x2, y2)], fill=(220, 80, 220, 180), width=2)
	d.arc((cx - r_out, cy - r_out, cx + r_out, cy + r_out), -25, 25, fill=(220, 80, 220, 220), width=3)
	save(im, "cones/vision_cone_high_ext.png")

	im = transparent(W, H)
	d = ImageDraw.Draw(im)
	pts = [(cx, cy)]
	for a in range(-35, 36):
		rad = math.radians(a)
		pts.append((cx + 200 * math.cos(rad), cy - 200 * math.sin(rad)))
	d.polygon(pts, fill=(80, 200, 120, 70))
	save(im, "cones/weapon_sector.png")
	save(Image.new("RGBA", (32, 32), (120, 120, 120, 140)), "cones/occlusion_gap.png")

	im = transparent(128, 32)
	d = ImageDraw.Draw(im)
	for x in range(4, 124, 10):
		d.line((x, 16, x + 6, 16), fill=(255, 220, 80, 255), width=4)
	save(im, "markers/marker_line.png")

	im = transparent(64, 64)
	d = ImageDraw.Draw(im)
	d.ellipse((12, 12, 52, 52), fill=(50, 50, 40, 255), outline=(220, 180, 60, 255), width=3)
	save(im, "markers/mine.png")

	im = transparent(64, 64)
	d = ImageDraw.Draw(im)
	d.rectangle((4, 4, 60, 60), outline=(255, 40, 40, 255), width=4)
	d.line((8, 8, 56, 56), fill=(255, 40, 40, 200), width=3)
	d.line((56, 8, 8, 56), fill=(255, 40, 40, 200), width=3)
	save(im, "markers/threat_slot.png")

	im = transparent(64, 64)
	d = ImageDraw.Draw(im)
	d.rectangle((2, 2, 61, 61), outline=(100, 200, 255, 255), width=3)
	d.rectangle((8, 8, 55, 55), fill=(100, 200, 255, 60))
	save(im, "markers/click_preview.png")
	print("DONE")


if __name__ == "__main__":
	main()
