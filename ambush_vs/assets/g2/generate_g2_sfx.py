#!/usr/bin/env python3
"""Procedural G2 SFX (WAV PCM 22.05kHz mono). Original synthesis; CC0-1.0. Requires numpy."""
from __future__ import annotations

import os
import struct
import wave

import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sfx")
SR = 22050
PEAK_DBFS = -6.0


def write_wav(name: str, samples: np.ndarray) -> None:
	os.makedirs(ROOT, exist_ok=True)
	path = os.path.join(ROOT, name)
	# normalize to peak
	peak = float(np.max(np.abs(samples))) + 1e-12
	target = 10.0 ** (PEAK_DBFS / 20.0)
	samples = (samples / peak) * target
	pcm = np.clip(samples * 32767.0, -32768, 32767).astype(np.int16)
	with wave.open(path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(SR)
		w.writeframes(pcm.tobytes())
	print("wrote", name, f"{len(pcm)/SR:.3f}s", os.path.getsize(path), "B")


def env(n: int, attack: float, release: float) -> np.ndarray:
	a = max(1, int(attack * SR))
	r = max(1, int(release * SR))
	e = np.ones(n, dtype=np.float64)
	e[:a] = np.linspace(0, 1, a)
	if r < n:
		e[-r:] = np.linspace(1, 0, r)
	return e


def noise(n: int, rng: np.random.Generator) -> np.ndarray:
	return rng.standard_normal(n)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
	# simple one-pole
	rc = 1.0 / (2.0 * np.pi * cutoff)
	dt = 1.0 / SR
	alpha = dt / (rc + dt)
	y = np.zeros_like(x)
	acc = 0.0
	for i, v in enumerate(x):
		acc += alpha * (v - acc)
		y[i] = acc
	return y


def highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
	return x - lowpass(x, cutoff)


def tone(n: int, freq: float, rng: np.random.Generator, harm: float = 0.3) -> np.ndarray:
	t = np.arange(n) / SR
	sig = np.sin(2 * np.pi * freq * t)
	sig += harm * np.sin(2 * np.pi * freq * 2 * t)
	sig += 0.1 * noise(n, rng)
	return sig


def gun_shot(rng: np.random.Generator, body_hz: float, crack: float, dur: float) -> np.ndarray:
	n = int(dur * SR)
	nse = noise(n, rng)
	body = lowpass(nse, body_hz) * env(n, 0.001, dur * 0.9)
	cr = highpass(nse, crack) * env(n, 0.0005, 0.04)
	click = tone(min(n, int(0.03 * SR)), 1800, rng, 0.1) * env(min(n, int(0.03 * SR)), 0.0005, 0.02)
	out = np.zeros(n)
	out += body * 0.9
	out += cr * 0.55
	out[: len(click)] += click * 0.35
	return out


def make_all() -> None:
	rng = np.random.default_rng(20261017)

	# Weapon cues (ids match weapons.csv)
	write_wav("weapon_kar98k.wav", gun_shot(rng, 220, 3500, 0.38))
	write_wav("weapon_mp40.wav", gun_shot(rng, 380, 4200, 0.12))
	write_wav("weapon_mg42.wav", gun_shot(rng, 300, 5000, 0.14))
	# Stielhandgranate throw then detonation
	n = int(0.35 * SR)
	throw = highpass(noise(n, rng), 800) * env(n, 0.01, 0.3)
	throw += tone(n, 120, rng, 0.0) * 0.15 * env(n, 0.01, 0.25)
	write_wav("weapon_grenade_throw.wav", throw)
	n = int(0.9 * SR)
	boom = lowpass(noise(n, rng), 180) * env(n, 0.002, 0.85)
	boom += highpass(noise(n, rng), 2000) * env(n, 0.001, 0.12) * 0.6
	write_wav("weapon_grenade_detonate.wav", boom)
	# Tellermine — loudest
	n = int(1.1 * SR)
	mine = lowpass(noise(n, rng), 140) * env(n, 0.001, 1.0)
	mine += highpass(noise(n, rng), 1500) * env(n, 0.0005, 0.15) * 0.8
	mine *= 1.25  # relative loudness before peak normalize
	write_wav("weapon_mine_detonate.wav", mine)

	# Footsteps by ground type
	def foot(cutoff: float, grit: float, dur: float) -> np.ndarray:
		n = int(dur * SR)
		s = lowpass(noise(n, rng), cutoff) * env(n, 0.002, dur * 0.85)
		s += highpass(noise(n, rng), grit) * env(n, 0.001, 0.05) * 0.4
		return s

	write_wav("foot_dirt.wav", foot(400, 2500, 0.18))
	write_wav("foot_mud.wav", foot(220, 900, 0.22))
	write_wav("foot_cobble.wav", foot(700, 4500, 0.16))
	write_wav("foot_grass.wav", foot(500, 2000, 0.17))

	# Alert tiers — must be orderable eyes-closed (ASSET_TIMING)
	# quiet: soft tick
	n = int(0.2 * SR)
	quiet = tone(n, 220, rng, 0.0) * env(n, 0.01, 0.15) * 0.25
	write_wav("alert_quiet.wav", quiet)
	# suspicious: short rising ?
	n = int(0.35 * SR)
	t = np.arange(n) / SR
	sus = np.sin(2 * np.pi * (420 + 180 * t / (n / SR)) * t) * env(n, 0.01, 0.25)
	write_wav("alert_suspicious.wav", sus)
	# area: two-tone ?!
	n = int(0.5 * SR)
	area = np.zeros(n)
	a = tone(int(0.18 * SR), 520, rng, 0.2) * env(int(0.18 * SR), 0.005, 0.12)
	b = tone(int(0.22 * SR), 380, rng, 0.2) * env(int(0.22 * SR), 0.005, 0.15)
	area[: len(a)] += a
	area[int(0.2 * SR) : int(0.2 * SR) + len(b)] += b
	write_wav("alert_area.wav", area)
	# global: urgent siren fragment
	n = int(0.7 * SR)
	t = np.arange(n) / SR
	glob = np.sin(2 * np.pi * (600 + 200 * np.sin(2 * np.pi * 6 * t)) * t) * env(n, 0.01, 0.5)
	write_wav("alert_global.wav", glob)

	# UI tap
	n = int(0.06 * SR)
	ui = highpass(noise(n, rng), 2000) * env(n, 0.0005, 0.04)
	ui += tone(n, 1400, rng, 0.0) * env(n, 0.0005, 0.03) * 0.5
	write_wav("ui_tap.wav", ui)

	# Ambush-trigger sting
	n = int(0.55 * SR)
	sting = np.zeros(n)
	for i, f in enumerate((180, 240, 360)):
		seg = tone(int(0.2 * SR), f, rng, 0.25) * env(int(0.2 * SR), 0.002, 0.16)
		off = int(i * 0.08 * SR)
		sting[off : off + len(seg)] += seg * (1.0 - i * 0.15)
	sting += highpass(noise(n, rng), 3000) * env(n, 0.001, 0.08) * 0.35
	write_wav("ambush_trigger.wav", sting)

	print("G2 SFX DONE")


if __name__ == "__main__":
	make_all()
