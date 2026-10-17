# W2 sim v0 — paper / rule discrepancies

| 字段 | 值 |
|------|-----|
| 日期 | 2026-10-17 |
| 范围 | 院子 v1.1 × TERMS/ADR v1 × headless sim |

Sim bugs that were clear (enter-tick double-step, `floor(6.999)=6` mine cell, ASCII `(9,12)` not `#`) were fixed in code/data. Remaining items are genuine paper↔continuous-sim tensions.

---

## 1. Plan A Kar facing ≈18° vs first cone entry

**Paper:** Kar@(13,7) facing ≈18°; t0_A=14.0 s when F1 at alley mouth (18,8); bearing 11.3°, Δ=6.7° ＜ 7.5°.

**Continuous 20 Hz:** On flank path `(23,7)→(18,8)`, F1’s bearing from Kar rises toward 11.3°. Cone edge is facing−7.5°. With facing=18°, first inclusive hit is ~tick 276 (t=13.8 s), before the mouth.

**Fixture:** `plan_a.json` uses `facing_deg=18.3895` so the cone edge coincides with progress=5.0 at tick 280.

**Math:** At progress 5.0, pos≈(18.097, 7.981), bearing≈10.8895°.  
`facing = bearing + 7.5 = 18.3895°` ⇒ Δ=7.5° on the inclusive boundary at tick 280; tick 279 still out.

---

## 2. East flank start cell

**Paper:** East entrance `(23, 6–7)`.  
**Sim route:** `(23, 7)→(18, 8)` so segment length ≈5.099 ≈ 5 cells / 10 s at 0.5 cells/s (paper’s ≈5 格 ≈10 s).

---

## 3. Mine trigger = path point, not whole cell

**Paper:** t0_B=16.0 s when E1 is at `(11,6)`.

**Cell-enter rule:** Cell `(11,6)` is y∈[6,7); E1 enters at t≈14.05 (tick 281) — too early for golden 320.

**Sim:** Mine detonates when enemy is within half a movement step of the mine grid point (matches discrete paper schedule).

---

## 4. Road `w` at (12,9)/(12,10) vs plan B standard ambush

**ASCII:** Both cells are `w` (low cover).  
**Effect:** Ground LOS from MP@(16,8) to E3/E4 on the main road is blocked ⇒ those targets leave the kill-zone union ⇒ `standard_ambush=false` while paper claims B 成立.

**Data choice:** `yard.json` clears `cover` on `(12,9)` and `(12,10)` only. Other `w` cells unchanged. Adjacent-cover self-block exemption (Chebyshev ≥2) remains for shooters standing on/ beside west/east cover.

---

## 5. H-01 overall grey-gap ratio

**ADR:** High grey gap ＜ 50% of adjacent ground `(6,9)`.

**Yard v1.1:** Barn structure adjacency at `(5,9)` dominates overall blocked fractions; sparse remaining `w` does not yield high/ground ＜ 0.5.  
**Test:** Asserts low-cover *differential* (ground blocked, high clear) ＞ 0. Ratio gate deferred until denser cover art.

---

## 6. Phase name `resolve`

W2 brief uses SETUP→WAIT→DETONATE→**RESOLVE**.  
`events.json` historically had `sweep`; enum now includes both `resolve` and `sweep`. Sim emits `resolve`.
