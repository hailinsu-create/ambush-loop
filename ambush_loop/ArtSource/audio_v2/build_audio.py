#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Original deterministic audio candidate synthesis. No recordings or API calls.

Run with Python 3.12 / NumPy 2.3.5 / SciPy 1.17.0. All design parameters
are here; the generated catalog is a candidate, never a runtime manifest.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import platform
import struct
import wave
from pathlib import Path

import numpy as np
import scipy
from scipy import signal

BASE_SHA = "4dea88b264d57f21da589ab5ad7a6ceb18662d43"
SR = 22050
SYNTH_SR = 44100
LOOP_SEC = 16.0
SPEC_VERSION = "audio-v2-candidate-r1"

# cue, duration, class, source peak dBFS, player gain dB, authored intent
# Bed goes to Music (-6 dB bus in the fixed runtime); others retain SFX.
SPECS = [
    ("alarm", .90, "signal", -6, -11, "Mechanical industrial siren: rising motor, two falling sweeps; immediate danger"),
    ("alarm_stinger", .48, "signal", -6, -11, "Two struck steel alarm bell partial clusters; distinguishes plan lock from siren"),
    ("fire", .24, "gun", -6, -15, "Generic rifle: broadband muzzle transient, chest body, small outdoor reflections"),
    ("fire_mg", .19, "gun", -6, -15, "Heavy automatic: low body, three very short legacy burst accents, bolt chatter"),
    ("fire_scout", .38, "gun", -6, -15, "Scoped rifle: bright initial crack, lean body, longer sparse outdoor tail"),
    ("fire_smg", .11, "gun", -6, -15, "SMG: compact dry blast, open-bolt rattle; no extra shot events"),
    ("fire_bolt", .39, "gun", -6, -15, "Bolt rifle: weighty muzzle, delayed two-stage mechanical bolt return"),
    ("fire_garand", .22, "gun", -6, -15, "Garand: medium rifle blast, fast receiver slap; no clip-ejection ping on each shot"),
    ("fire_mg42", .14, "gun", -6, -15, "MG42: high narrow crack and five compressed legacy burst accents, lighter bolt buzz"),
    ("fire_pistol", .15, "gun", -6, -15, "Pistol: small sharp report and slide, short dry reflections"),
    ("fire_shotgun", .32, "gun", -6, -15, "Shotgun legacy family: broad low pressure body, gravelly shot dispersion"),
    ("fire_ping", .27, "foley", -10, -16, "Small struck clip/metal feedback; only existing fire_ping trigger may use it"),
    ("return_fire", .26, "gun", -6, -18, "Distant hostile report: low-pass muzzle, reflected body; softer than friendly weapon"),
    ("empty", .12, "foley", -10, -16, "Dry trigger and receiver latch double click, no pitched warning beep"),
    ("loot", .28, "foley", -10, -16, "Canvas pouch rustle, brass and latch settle; restrained pickup confirmation"),
    ("op_death", .72, "signal", -8, -11, "Cloth/body fall plus low damped two-tone loss motif; no recorded voice"),
    ("escape", .80, "signal", -8, -11, "Urgent descending short radio motif and receding boot scuffs"),
    ("fail", 1.15, "signal", -8, -11, "Muted low struck minor interval and diffuse tail, no sub-only boom"),
    ("win", .90, "signal", -10, -12, "Quiet restrained ascending struck open interval"),
    ("win_stinger", 1.20, "signal", -10, -12, "Three warm damped metal notes ending above win; brief outcome flourish"),
    ("door", .60, "foley", -10, -16, "Latch, hinge friction, hollow heavy door closure and metal frame settle"),
    ("trip", .40, "foley", -10, -16, "Tensioned wire release and spring/latch snap; also existing tool pickup"),
    ("barrel", 1.15, "signal", -6, -11, "Layered pressure blast, metal shell modes and scattered debris, controlled tail"),
    ("kill", .19, "foley", -10, -16, "Muted material impact and short downward wooden resonance"),
    ("hit", .12, "foley", -10, -16, "Dry cloth/gear hit, short body, restrained high-frequency edge"),
    ("ui", .065, "ui", -14, -16, "Soft tactile mechanical switch with damped woody tick"),
    ("spawn", .32, "foley", -10, -16, "Boot/gear approach and muted radio squelch; existing advance warning only"),
    ("echo_ping", .70, "signal", -8, -13, "Band-limited radio double-dot then longer tone with two quiet reflected taps"),
    ("handoff", .85, "signal", -10, -14, "Paper turn and restrained rising metal interval between nights"),
    ("leak", .70, "signal", -8, -12, "Receding footfalls and radio squelch, distinct from terminal escape"),
    ("night_enter", .68, "signal", -10, -14, "Soft low open fifth underneath brief cloth/page texture"),
    ("tension", .76, "signal", -8, -13, "Muted irregular steel pulses, low mechanical swell; no sustained harsh alarm"),
    ("ambient_yard", LOOP_SEC, "ambient", -12, -16, "Dusk yard: diffuse wind, intermittent insect texture, distant transformer and fence movement"),
    ("ambient_warehouse", LOOP_SEC, "ambient", -12, -16, "Warehouse aisle: muffled ventilation, sparse timber/steel creaks, hollow drip reflections"),
    ("ambient_pump", LOOP_SEC, "ambient", -12, -16, "Pump station: 58 Hz motor harmonics, cyclic valve vibration, flowing water and light drips"),
    ("ambient_railcut", LOOP_SEC, "ambient", -12, -16, "Signal/rail cut: open wind, restrained distant wheel/rail pairs, signal relay taps"),
    ("ambient_depot", LOOP_SEC, "ambient", -12, -16, "Fuel depot: distant diesel harmonics, tank wall resonance, pipe vent and sparse chain movement"),
    ("ambient_radio", LOOP_SEC, "ambient", -12, -16, "Radio station: filtered static, restrained test-carrier bursts, fan and relay clicks; no speech/messages"),
    ("foot", .20, "foley", -10, -20, "One gravel/concrete boot contact, heel/body then grit; no cadence baked in"),
    ("whistle", .52, "signal", -8, -13, "Breathy short human-style whistle synthesis, soft pitch drift and release"),
    ("knife", .28, "foley", -10, -16, "Short fabric/air swish then muted material contact, restrained metal scrape"),
    ("crate_lid", .53, "foley", -10, -16, "Wooden lid slide/creak, latch, hollow wood settle"),
    ("body_drop", .55, "foley", -10, -18, "Heavy clothed body contact followed by gear and gravel settling"),
    ("select", .10, "ui", -14, -16, "Light two-part selector detent, distinct from ui switch"),
    ("stealth_bed", LOOP_SEC, "bed", -15, -10, "Quiet non-rhythmic low mechanical/air texture, sparse stable fifth; no tactical messages"),
]


def seed_for(label: str) -> int:
    return int.from_bytes(hashlib.sha256((SPEC_VERSION + ":" + label).encode()).digest()[:8], "little")


class Designer:
    def __init__(self, cue: str, sec: float):
        self.cue = cue
        self.rng = np.random.Generator(np.random.PCG64(seed_for(cue)))
        self.n = round(sec * SYNTH_SR)
        self.x = np.zeros(self.n, np.float64)

    def noise(self, sec: float, low: float, high: float) -> np.ndarray:
        n = round(sec * SYNTH_SR)
        raw = self.rng.standard_normal(n)
        filt = signal.butter(3, [low, high], btype="bandpass", fs=SYNTH_SR, output="sos")
        out = signal.sosfilt(filt, raw)
        return out / max(np.sqrt(np.mean(out * out)), 1e-9)

    def add(self, a: np.ndarray, at: float = 0, gain: float = 1, circular: bool = False):
        start = round(at * SYNTH_SR)
        if circular:
            np.add.at(self.x, (np.arange(len(a)) + start) % self.n, a * gain)
        else:
            count = min(len(a), self.n - start)
            if count > 0:
                self.x[start:start + count] += a[:count] * gain

    def burst(self, at: float, sec: float, low: float, high: float, gain: float, decay: float = .025, attack: float = .0007, circular: bool = False):
        a = self.noise(sec, low, high)
        t = np.arange(len(a)) / SYNTH_SR
        env = (1 - np.exp(-t / attack)) * np.exp(-t / decay)
        env *= np.minimum((sec - t) / .008, 1)
        self.add(a * env, at, gain, circular)

    def modes(self, at: float, sec: float, freqs: list[float], gain: float, decay: float = .08, attack: float = .0008, circular: bool = False):
        t = np.arange(round(sec * SYNTH_SR)) / SYNTH_SR
        a = np.zeros_like(t)
        for i, f in enumerate(freqs):
            a += np.sin(2 * np.pi * f * t + self.rng.uniform(-.2, .2)) * np.exp(-t / (decay / (1 + .25 * i))) / (1 + .65 * i)
        a *= (1 - np.exp(-t / attack)) * np.minimum((sec - t) / .012, 1)
        self.add(a, at, gain, circular)

    def sweep(self, at: float, sec: float, f0: float, f1: float, gain: float, decay: float = .06):
        t = np.arange(round(sec * SYNTH_SR)) / SYNTH_SR
        phase = 2 * np.pi * (f1 * t + (f0 - f1) * decay * (1 - np.exp(-t / decay)))
        a = np.sin(phase) * (1 - np.exp(-t / .001)) * np.exp(-t / decay)
        a *= np.minimum((sec - t) / .015, 1)
        self.add(a, at, gain)

    def metal(self, at: float, scale: float = 1, gain: float = .1, circular: bool = False):
        self.burst(at, .055, 1500, 7300, gain, .004, circular=circular)
        self.modes(at, .18, [740 * scale, 1231 * scale, 2179 * scale, 3197 * scale], gain * .45, .045, circular=circular)

    def foot(self, at: float, gain: float = 1):
        self.sweep(at, .14, 143, 68, .24 * gain, .035)
        self.burst(at + .009, .16, 240, 5800, .18 * gain, .026, .001)
        self.burst(at + .06, .10, 1700, 6800, .04 * gain, .022, .006)

    def cloth(self, at: float, sec: float = .2, gain: float = .1):
        self.burst(at, sec, 340, 6500, gain, sec / 3, .012)

    def shot(self, at: float, body: float, crack: float, weight: float = 1, tail: float = .13, cutoff: float = 8500):
        self.burst(at, .065, crack, cutoff, .72 * weight, .006, .0002)
        self.burst(at + .001, .09, 170, 1900, .31 * weight, .016, .00035)
        self.sweep(at, .16, body * 1.8, body, .60 * weight, .024)
        self.metal(at + .017, 1.1, .045 * weight)
        # Sparse low-pass, non-identical reflections; no exact slapback-copy comb.
        for delay, scale in [(.031, .08), (.066, .037), (.106, .018)]:
            self.burst(at + delay, tail, 160, min(4200, cutoff), scale * weight, tail / 3, .003)

    def periodic_noise(self, low: float, high: float, gain: float, modulation: int = 3):
        f = np.fft.rfftfreq(self.n, 1 / SYNTH_SR)
        z = self.rng.standard_normal(len(f)) + 1j * self.rng.standard_normal(len(f))
        shape = (1 - np.exp(-(f / low) ** 4)) * np.exp(-(f / high) ** 4)
        shape[0] = 0
        z *= shape
        z[-1] = z[-1].real
        a = np.fft.irfft(z, n=self.n)
        a /= max(np.sqrt(np.mean(a * a)), 1e-9)
        t = np.arange(self.n) / SYNTH_SR
        a *= .76 + .16 * np.sin(2 * np.pi * modulation * t / LOOP_SEC + .8) + .08 * np.sin(2 * np.pi * (modulation + 2) * t / LOOP_SEC)
        self.x += a * gain

    def hum(self, f0: float, gain: float, cycles: int = 3):
        t = np.arange(self.n) / SYNTH_SR
        f0 = round(f0 * LOOP_SEC) / LOOP_SEC
        env = .85 + .15 * np.sin(2 * np.pi * cycles * t / LOOP_SEC)
        for i, scale in enumerate([1, .42, .20, .09], 1):
            self.x += np.sin(2 * np.pi * f0 * i * t + i * .3) * gain * scale * env


def soundscape(d: Designer):
    c = d.cue
    d.periodic_noise(70, 1300 if c == "ambient_warehouse" else 2900, .024, 3)
    if c == "ambient_yard":
        d.hum(100, .008)
        d.periodic_noise(350, 4200, .012, 1)
        for at in [1.2, 4.8, 9.6, 13.3]:
            for gap in [0, .093, .21]:
                d.modes(at + gap, .075, [3970, 4387], .008, .021, .005, True)
        d.modes(7.8, .9, [156, 391, 743], .012, .22, .012, True)
    elif c == "ambient_warehouse":
        d.hum(83, .021)
        d.periodic_noise(150, 730, .015, 2)
        for at in [2.3, 8.4, 14.1]:
            d.burst(at, .55, 160, 2600, .016, .16, .06, True)
            d.modes(at, .7, [113, 227, 607], .020, .17, .012, True)
        for at in [4.1, 11.2]:
            for gap, gain in [(0, .015), (.065, .006), (.131, .003)]:
                d.modes(at + gap, .32, [920, 1597, 2449], gain, .055, .001, True)
    elif c == "ambient_pump":
        d.hum(58, .055, 5)
        d.periodic_noise(380, 3800, .025, 4)
        for at in np.arange(.6, 16, .8):
            d.modes(float(at), .29, [172, 344, 687], .010, .06, .005, True)
        for at in [3.7, 6.1, 10.9, 15.4]:
            d.modes(at, .2, [1127, 2371], .013, .036, .001, True)
    elif c == "ambient_railcut":
        d.periodic_noise(90, 2200, .027, 1)
        d.hum(71, .01)
        for at in [2.6, 3.5, 4.7, 6.1, 7.6]:
            for gap in [0, .165]:
                d.modes(at + gap, .3, [249, 581, 1109], .013, .061, .001, True)
                d.burst(at + gap, .15, 200, 2200, .007, .038, .001, True)
        d.metal(11.2, .7, .012, True)
        d.metal(11.33, .78, .009, True)
    elif c == "ambient_depot":
        d.hum(38, .034, 1)
        d.hum(76, .025, 2)
        d.periodic_noise(110, 710, .034, 2)
        for at in np.arange(.1, 16, .5):
            d.modes(float(at), .16, [118, 276], .006, .034, .001, True)
        d.burst(6.1, 1.2, 850, 4600, .019, .36, .16, True)
        for at in [10.2, 10.31, 10.56]:
            d.metal(at, .48, .009, True)
    elif c == "ambient_radio":
        d.periodic_noise(510, 3900, .045, 3)
        d.hum(150, .016, 4)
        for at in [2.1, 7.5, 12.8]:
            # Abstract service-carrier pattern, not linguistic Morse or a message.
            for gap, dur in [(0, .07), (.22, .16)]:
                d.modes(at + gap, dur, [871, 1742], .018, dur / 1.7, .006, True)
            d.burst(at + .44, .12, 550, 2700, .015, .028, .003, True)
        for at in [4.7, 14.2]:
            d.metal(at, 1.4, .008, True)
    elif c == "stealth_bed":
        d.hum(92, .022, 1)
        d.hum(138, .009, 2)
        d.periodic_noise(120, 890, .028, 1)


def compose(c: str, sec: float) -> np.ndarray:
    d = Designer(c, sec)
    if c.startswith("ambient_") or c == "stealth_bed":
        soundscape(d)
    elif c in {"fire", "fire_scout", "fire_smg", "fire_bolt", "fire_garand", "fire_pistol", "fire_shotgun", "return_fire"}:
        body, crack, weight, tail, cutoff = {
            "fire": (137, 1500, 1., .10, 8500),
            "fire_scout": (169, 2600, .8, .24, 9200),
            "fire_smg": (196, 1900, .72, .06, 7500),
            "fire_bolt": (114, 1350, 1., .18, 8300),
            "fire_garand": (149, 1850, .92, .10, 8200),
            "fire_pistol": (223, 2150, .55, .055, 7800),
            "fire_shotgun": (83, 750, 1.2, .17, 6800),
            "return_fire": (101, 660, .55, .16, 3400),
        }[c]
        d.shot(.001, body, crack, weight, tail, cutoff)
        if c == "fire_bolt":
            d.metal(.181, .43, .15)
            d.metal(.255, .62, .11)
        elif c == "fire_scout":
            d.burst(.118, .21, 800, 4500, .035, .062, .004)
        elif c == "fire_garand":
            d.metal(.042, .71, .12)
        elif c == "fire_smg":
            d.modes(.013, .075, [383, 921, 2081], .12, .019)
        elif c == "fire_shotgun":
            d.burst(.012, .18, 200, 4200, .18, .036)
    elif c in {"fire_mg", "fire_mg42"}:
        # Fixed baseline assets already contain bursts; retain that sonic shape.
        # These are compressed timbral accents, not physical cadence simulation.
        count, gap = (3, .030) if c == "fire_mg" else (5, .014)
        for i in range(count):
            d.shot(.001 + i * gap, 107 if count == 3 else 178, 1100 if count == 3 else 2550, (1 - .10 * i) / count ** .3, .045, 8700)
    elif c == "alarm":
        t = np.arange(d.n) / SYNTH_SR
        freq = 570 + 165 * np.cos(2 * np.pi * 2 * t / sec) + 75 * (1 - np.exp(-t / .11))
        phase = 2 * np.pi * np.cumsum(freq) / SYNTH_SR
        env = np.minimum(t / .08, 1) * np.minimum((sec - t) / .1, 1)
        d.x += (np.sin(phase) + .31 * np.sin(phase * 2) + .13 * np.sin(phase * 3)) * env
        d.burst(0, .25, 140, 1900, .055, .13, .02)
    elif c == "alarm_stinger":
        for at, g in [(0, 1), (.16, .7)]:
            d.modes(at, .32, [627, 991, 1661, 2501, 3277], g, .10, .0008)
            d.burst(at, .04, 1100, 7500, g * .10, .004)
    elif c == "barrel":
        d.burst(.001, .30, 100, 7800, .82, .034, .0003)
        d.sweep(.002, .64, 175, 52, .85, .095)
        d.burst(.05, .88, 60, 620, .3, .24, .003)
        d.modes(.042, .74, [171, 394, 841, 1503], .30, .15)
        for at, scale in [(.12, .54), (.23, .73), (.34, .38), (.51, .8), (.69, .44)]:
            d.metal(at, scale, .035)
        d.burst(.21, .70, 230, 3300, .065, .20, .017)
    elif c in {"ui", "select", "empty", "fire_ping"}:
        if c == "ui":
            d.burst(.001, .03, 350, 4100, .12, .003)
            d.modes(.003, .045, [287, 643, 1181], .13, .011)
        elif c == "select":
            d.metal(.001, .36, .10)
            d.modes(.028, .060, [431, 811], .12, .014)
        elif c == "empty":
            d.metal(.001, .64, .35)
            d.metal(.039, .39, .15)
            d.modes(.003, .09, [277, 733], .10, .02)
        else:
            d.modes(.001, .26, [2197, 3553, 5261], .55, .063)
            d.burst(0, .035, 2700, 8300, .08, .003)
    elif c in {"foot", "body_drop", "op_death", "spawn", "leak", "escape"}:
        if c == "foot":
            d.foot(.001)
        elif c in {"body_drop", "op_death"}:
            d.sweep(.005, .3, 133, 60, .42, .058)
            d.cloth(.01, .32, .22)
            d.metal(.13, .31, .035)
            d.foot(.18, .23)
            if c == "op_death":
                d.modes(.05, .6, [164.8, 155.6, 311.2], .09, .14, .012)
        elif c == "spawn":
            d.foot(.005, .5)
            d.cloth(.03, .20, .07)
            d.burst(.16, .14, 620, 2800, .10, .04, .004)
        else:
            for i, at in enumerate([.005, .18, .36, .54]):
                d.foot(at, .75 ** i)
            d.burst(.06, .56, 660, 3100, .12, .17, .01)
            if c == "escape":
                d.modes(.04, .35, [932, 1398], .17, .11, .006)
                d.modes(.38, .37, [622, 933], .14, .12, .006)
    elif c in {"loot", "handoff", "night_enter"}:
        d.cloth(.001, .23 if c == "loot" else .34, .20)
        if c == "loot":
            d.metal(.13, .83, .17)
            d.metal(.20, .48, .07)
        else:
            notes = [220, 293.66, 440] if c == "handoff" else [146.83, 220]
            for i, f in enumerate(notes):
                d.modes(.16 + i * .13, .34, [f, f * 2.02, f * 3.03], .15, .105, .010)
    elif c in {"fail", "win", "win_stinger", "tension"}:
        notes = {"fail": [146.83, 138.59], "win": [261.63, 392], "win_stinger": [196, 261.63, 329.63, 392], "tension": [207.65, 220, 207.65]}[c]
        for i, f in enumerate(notes):
            at = [.015, .14, .33][i] if c == "tension" else .015 + i * .17
            d.modes(at, .62 if c != "tension" else .34, [f, f * 2.01, f * 3.12], .23, .15, .012)
        d.burst(.005, sec * .7, 100, 840, .044, .18, .02)
    elif c in {"door", "crate_lid", "trip", "knife", "kill", "hit"}:
        if c == "door":
            d.metal(.001, .53, .20)
            d.burst(.058, .36, 150, 2100, .10, .18, .025)
            d.modes(.063, .35, [107, 219, 407], .13, .15, .02)
            d.modes(.31, .27, [84, 201, 489], .37, .07)
            d.metal(.345, .4, .12)
        elif c == "crate_lid":
            d.metal(.001, .37, .12)
            d.burst(.035, .35, 230, 2400, .17, .14, .02)
            d.modes(.07, .33, [161, 357, 811], .15, .10, .02)
            d.modes(.32, .18, [139, 283, 561], .24, .045)
        elif c == "trip":
            d.modes(.002, .18, [1519, 2783, 4253], .21, .035)
            d.metal(.048, .68, .18)
            d.sweep(.059, .25, 182, 94, .27, .05)
        elif c == "knife":
            d.burst(.003, .12, 790, 7600, .22, .06, .022)
            d.burst(.11, .12, 130, 3200, .19, .018)
            d.sweep(.114, .15, 206, 102, .21, .026)
            d.metal(.15, .53, .028)
        else:
            d.burst(.001, .085, 210, 3700, .34, .011)
            d.sweep(.001, .15, 211 if c == "hit" else 177, 92, .27, .022)
            d.cloth(.016, .09, .07)
    elif c == "echo_ping":
        for at, dur, f in [(.015, .075, 877), (.16, .075, 877), (.35, .17, 1315)]:
            d.modes(at, dur, [f, f * 2], .28, dur * .8, .005)
            d.modes(at + .095, dur, [f], .05, dur * .65, .006)
        d.burst(.001, .68, 480, 2700, .032, .3, .01)
    elif c == "whistle":
        t = np.arange(d.n) / SYNTH_SR
        f = 1630 + 90 * np.sin(np.pi * t / sec) + 12 * np.sin(2 * np.pi * 5 * t)
        phase = 2 * np.pi * np.cumsum(f) / SYNTH_SR
        env = np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 1.5
        d.x += np.sin(phase) * env + d.noise(sec, 1100, 5300) * env * .11
    else:
        raise ValueError("Unimplemented cue: " + c)
    return d.x


def finish(x: np.ndarray, is_loop: bool, peak_db: float) -> np.ndarray:
    if is_loop:
        # Circular antialias resampling and DC rejection retain periodicity.
        x = signal.resample(x, len(x) // 2)
        f = np.fft.rfftfreq(len(x), 1 / SR)
        z = np.fft.rfft(x)
        z *= (1 - np.exp(-(f / 32) ** 4)) * np.exp(-(f / 8700) ** 12)
        z[0] = 0
        x = np.fft.irfft(z, n=len(x))
        # Put the periodic boundary at the smoothest non-silent location.
        # No edge fade/dropout; all neighboring pairs already lie on the cycle.
        diff = x - np.roll(x, 1)
        curvature = np.roll(diff, -1) - diff
        score = np.abs(diff) + 2 * np.abs(curvature)
        start = int(np.argmin(score))
        x = np.roll(x, -start)
    else:
        x = signal.resample_poly(x, 1, 2)
        x = signal.sosfilt(signal.butter(2, 38, "highpass", fs=SR, output="sos"), x)
        fade_in, fade_out = min(15, len(x) // 8), min(440, len(x) // 8)
        x[:fade_in] *= np.sin(np.linspace(0, np.pi / 2, fade_in)) ** 2
        x[-fade_out:] *= np.sin(np.linspace(np.pi / 2, 0, fade_out)) ** 2
        window = np.sin(np.linspace(0, np.pi, len(x))) ** 2
        x -= np.mean(x) / np.mean(window) * window
        x[0] = x[-1] = 0
    x *= 10 ** (peak_db / 20) / max(np.max(np.abs(x)), 1e-9)
    return np.rint(x * 32767).astype("<i2")


def write_wav(path: Path, pcm: np.ndarray, loop: bool = False):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = pcm.astype("<i2").tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    if loop:
        # WAV smpl end is inclusive. Explicit import sidecar sets exclusive end;
        # fixed engine AUTO leaves the inclusive value unchanged (off by one).
        header = struct.pack("<9I", 0, 0, round(1e9 / SR), 60, 0, 0, 0, 1, 0)
        point = struct.pack("<6I", 0, 0, 0, len(pcm) - 1, 0, 0)
        smpl = header + point
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    chunks += b"data" + struct.pack("<I", len(data)) + data
    path.write_bytes(b"RIFF" + struct.pack("<I", len(chunks) + 4) + b"WAVE" + chunks)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def import_sidecar(path: Path, frames: int, is_loop: bool):
    # Sidecar configuration is intentional input, not checked-in editor cache.
    # Path MD5 is the Godot importer destination convention, verified in harness.
    resource = "res://art/audio_v2/" + path.name
    dest = "res://.godot/imported/" + path.name + "-" + hashlib.md5(resource.encode()).hexdigest() + ".sample"
    path.with_suffix(".wav.import").write_text(f'''[remap]
importer="wav"
type="AudioStreamWAV"
path="{dest}"

[deps]
source_file="{resource}"
dest_files=["{dest}"]

[params]
force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=22050
edit/trim=false
edit/normalize=false
edit/loop_mode={2 if is_loop else 1}
edit/loop_begin=0
edit/loop_end={frames if is_loop else -1}
compress/mode=0
''', encoding="utf-8")


def audition(out: Path, assets: dict[str, np.ndarray], records: list[dict]):
    review = out / "ArtSource/audio_v2/audition"
    review.mkdir(parents=True, exist_ok=True)
    index = {"hearing_status": "NOT_LISTENED_NO_AUDIO_CAPABILITY", "sample_rate": SR, "tracks": []}
    recs = {r["cue"]: r for r in records}
    groups = [
        ("01_weapons", [c for c, *_ in SPECS if c.startswith("fire") or c == "return_fire"], .55),
        ("02_foley_ui", [c for c, *_ in SPECS if recs[c]["voice_class"] in {"foley", "ui"} and c != "fire_ping"], .40),
        ("03_signals", [c for c, *_ in SPECS if recs[c]["voice_class"] == "signal"], .6),
        ("04_six_loop_seams", [c for c, *_ in SPECS if c.startswith("ambient_")] + ["stealth_bed"], .5),
    ]
    for name, cues, pause in groups:
        track, ranges, cursor = [], [], 0
        for cue in cues:
            a = assets[cue]
            is_loop = recs[cue]["loop"]
            if is_loop:
                a = np.concatenate([a, a[:2 * SR]])
            ranges.append({"cue": cue, "start_sec": cursor / SR, "end_sec": (cursor + len(a)) / SR,
                           "loop_seam_sec": (cursor + LOOP_SEC * SR) / SR if is_loop else None,
                           "gain_note": "source level; player/bus gain not applied"})
            track.extend([a, np.zeros(round(pause * SR), "<i2")])
            cursor += len(a) + round(pause * SR)
        path = review / (name + ".wav")
        write_wav(path, np.concatenate(track))
        index["tracks"].append({"file": path.name, "sha256": sha(path), "ranges": ranges})
    # Representative integration-gain montage, not gameplay or auditory proof.
    mix = np.zeros(16 * SR)
    events = [(0, "ambient_yard"), (0, "stealth_bed"), (.5, "ui"), (.9, "select"),
              (1.3, "loot"), (2.0, "alarm"), (2.5, "alarm_stinger"), (3.5, "tension"),
              (6, "barrel"), (7.2, "op_death"), (8.3, "echo_ping"), (9.5, "leak"),
              (10.5, "fire_bolt"), (11.3, "empty"), (12, "win"), (13.2, "win_stinger")]
    for i in range(12):
        events.extend([(4 + i * .068, "fire_smg"), (4 + i * .055, "fire_mg42")])
    events.extend([(4.01, "fire_garand"), (4.02, "fire_scout"), (4.03, "return_fire"), (4.025, "hit")])
    for at, cue in events:
        a = assets[cue].astype(float) / 32767
        r = recs[cue]
        gain = 10 ** ((r["recommended_player_gain_db"] + r["bus_baseline_gain_db"]) / 20)
        start = round(at * SR)
        end = min(len(mix), start + len(a))
        mix[start:end] += a[:end - start] * gain
    path = review / "05_gain_stress_mix.wav"
    if np.max(np.abs(mix)) >= .90:
        raise RuntimeError("Stress mix exceeds -0.92 dBFS; change gain design")
    write_wav(path, np.rint(mix * 32767).astype("<i2"))
    index["tracks"].append({"file": path.name, "sha256": sha(path), "events": events,
                            "gain_note": "recommended player + fixed bus gain; overlapping tails, no limiter or normalization"})
    (review / "index.json").write_text(json.dumps(index, indent=2) + "\n")


def build(out: Path):
    art = out / "art/audio_v2"
    art.mkdir(parents=True, exist_ok=True)
    records, assets = [], {}
    for cue, sec, cls, peak, gain, intent in SPECS:
        is_loop = cls in {"ambient", "bed"}
        pcm = finish(compose(cue, sec), is_loop, peak)
        path = art / (cue + ".wav")
        write_wav(path, pcm, is_loop)
        import_sidecar(path, len(pcm), is_loop)
        assets[cue] = pcm
        records.append({"cue": cue, "resource_path": "res://art/audio_v2/" + path.name,
                        "candidate_status": "TECHNICAL_CANDIDATE_AUDITORY_REVIEW_PENDING",
                        "intent": intent, "voice_class": cls, "seed": seed_for(cue),
                        "source": "original procedural pressure/noise/modal synthesis; no sampled recordings",
                        "license": "CC0-1.0", "sha256": sha(path), "bytes": path.stat().st_size,
                        "sample_rate": SR, "channels": 1, "bits": 16, "compression": "PCM (Godot compress/mode=0)",
                        "frames": len(pcm), "duration_sec": len(pcm) / SR,
                        "loop": is_loop, "loop_begin_frame": 0, "loop_end_frame_exclusive": len(pcm) if is_loop else None,
                        "source_sample_peak_target_dbfs": peak, "recommended_player_gain_db": gain,
                        "bus": "Music" if cls == "bed" else "SFX", "bus_baseline_gain_db": -6 if cls == "bed" else 0,
                        "max_instances_per_cue_recommended": 1,
                        "playback_semantics": "dedicated continuous player; stop/crossfade on mission/scene change" if is_loop else "one trigger per existing event; restart same cue as fixed runtime",
                        "auditory_review": "NOT_LISTENED_NO_AUDIO_CAPABILITY"})
    cat = {"schema": 1, "candidate_version": SPEC_VERSION, "base_source_sha": BASE_SHA,
           "build_script_sha256": sha(Path(__file__)), "cue_count": len(records),
           "license": "CC0-1.0 for generated audio; MIT for authored scripts",
           "status": "CANDIDATE_ONLY_NOT_RUNTIME_INTEGRATED_NOT_FINAL_AUDIO_ACCEPTANCE",
           "toolchain": {"python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__},
           "voice_budget_recommended": {"gun": 4, "foley": 2, "signal": 1, "ui": 1, "ambient": 1, "bed": 1},
           "production_wav_bytes": sum(r["bytes"] for r in records),
           "decoded_pcm_bytes_all_cues": sum(r["frames"] * 2 for r in records),
           "cues": records}
    (art / "catalog_candidate.json").write_text(json.dumps(cat, indent=2) + "\n")
    lines = ["cue,resource_path,voice_class,duration_sec,loop,recommended_player_gain_db,bus,auditory_review"]
    for r in records:
        lines.append(",".join(str(r[k]) for k in ["cue", "resource_path", "voice_class", "duration_sec", "loop", "recommended_player_gain_db", "bus", "auditory_review"]))
    (art / "cue_map_candidate.csv").write_text("\n".join(lines) + "\n")
    audition(out, assets, records)
    hashes = []
    for root in [art, out / "ArtSource/audio_v2/audition"]:
        for p in sorted(root.rglob("*")):
            if p.is_file():
                hashes.append(f"{sha(p)}  {p.relative_to(out).as_posix()}")
    target = out / "ArtSource/audio_v2/generated.sha256"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(hashes) + "\n")
    print(f"AUDIO_V2_BUILD_OK cues={len(records)} wav_bytes={cat['production_wav_bytes']} out={out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-project", type=Path, default=Path(__file__).resolve().parents[2])
    build(parser.parse_args().output_project.resolve())
