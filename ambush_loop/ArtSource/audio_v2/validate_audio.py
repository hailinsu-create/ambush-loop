#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent file/decoder/loop/budget validation; does not assert hearing."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import re
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy import signal

EXPECTED = "alarm alarm_stinger fire fire_mg fire_scout fire_smg fire_bolt fire_garand fire_mg42 fire_pistol fire_shotgun fire_ping return_fire empty loot op_death escape fail win win_stinger door trip barrel kill hit ui spawn echo_ping handoff leak night_enter tension ambient_yard ambient_warehouse ambient_pump ambient_railcut ambient_depot ambient_radio foot whistle knife crate_lid body_drop select stealth_bed".split()
BASE_SHA = "4dea88b264d57f21da589ab5ad7a6ceb18662d43"


def db(x):
    return round(float(20 * np.log10(max(float(x), 1e-12))), 6)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def check_one(project: Path, r: dict) -> dict:
    path = project / r["resource_path"].removeprefix("res://")
    require(hashlib.sha256(path.read_bytes()).hexdigest() == r["sha256"], "hash " + r["cue"])
    with wave.open(str(path)) as wav:
        require(wav.getcomptype() == "NONE", "compression " + r["cue"])
        require((wav.getnchannels(), wav.getsampwidth(), wav.getframerate(), wav.getnframes()) == (1, 2, 22050, r["frames"]), "WAV contract " + r["cue"])
        raw = wav.readframes(wav.getnframes())
    ints = np.frombuffer(raw, dtype="<i2")
    x = ints.astype(float) / 32767
    decoded = subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-i", str(path), "-f", "s16le", "-acodec", "pcm_s16le", "-"], check=True, capture_output=True, timeout=30)
    require(decoded.stdout == raw, "FFmpeg PCM differs " + r["cue"])
    require(not decoded.stderr, "FFmpeg warning " + r["cue"])
    peak, dc, rms = np.max(np.abs(x)), np.mean(x), np.sqrt(np.mean(x * x))
    true_peak = np.max(np.abs(signal.resample_poly(x, 4, 1)))
    require(np.isfinite(x).all() and rms > .001, "empty/nonfinite " + r["cue"])
    require(np.max(np.abs(ints.astype(np.int32))) < 32767, "clipping " + r["cue"])
    require(abs(dc) <= 1 / 32767, "DC above one LSB " + r["cue"])
    require(db(true_peak) <= -3, "4x reconstructed peak " + r["cue"])
    require(abs(db(peak) - r["source_sample_peak_target_dbfs"]) < .005, "peak target " + r["cue"])
    result = {"cue": r["cue"], "sha256": r["sha256"], "bytes": path.stat().st_size,
              "duration_sec": len(x) / 22050, "peak_dbfs": db(peak), "true_peak_4x_dbfs": db(true_peak),
              "rms_dbfs": db(rms), "dc_mean": float(dc), "dc_dbfs": db(abs(dc)),
              "clipped_samples": int(np.count_nonzero(np.abs(ints.astype(np.int32)) >= 32767)),
              "ffmpeg_decodes_byte_identical_pcm": True,
              "auditory_review": "NOT_LISTENED_NO_AUDIO_CAPABILITY"}
    if r["loop"]:
        require(b"smpl" in path.read_bytes()[:128], "embedded loop missing " + r["cue"])
        join = abs(x[0] - x[-1])
        slope_jump = abs((x[1] - x[0]) - (x[0] - x[-1]))
        diffs = np.abs(np.diff(x))
        p95 = np.percentile(diffs, 95)
        window = 2205
        seam = np.concatenate([x[-window:], x[:window]])
        seam_rms = np.sqrt(np.mean(seam * seam))
        whole_windows = x[:(len(x) // 5512) * 5512].reshape(-1, 5512)
        min_rms = np.min(np.sqrt(np.mean(whole_windows ** 2, axis=1)))
        require(join <= 2 / 32767, "loop step >2 LSB " + r["cue"])
        require(slope_jump <= 4 / 32767, "loop slope >4 LSB " + r["cue"])
        require(join <= max(p95 * 1.5, 2 / 32767), "loop abnormal derivative " + r["cue"])
        require(seam_rms / rms >= .20 and min_rms / rms >= .10, "loop boundary dropout " + r["cue"])
        result["loop_seam"] = {"step_linear": float(join), "step_dbfs": db(join),
                               "slope_jump_linear": float(slope_jump), "slope_jump_dbfs": db(slope_jump),
                               "seam_step_over_derivative_p95": float(join / max(p95, 1e-9)),
                               "seam_200ms_rms_relative_db": db(seam_rms / rms),
                               "minimum_250ms_rms_relative_db": db(min_rms / rms),
                               "repeat_test_cycles": 3, "qualification": "PCM seam test, auditory click review pending"}
        repeated = np.tile(x, 3)
        for at in [len(x), len(x) * 2]:
            require(abs(repeated[at] - repeated[at - 1]) <= 2 / 32767, "repeat loop seam " + r["cue"])
    else:
        require(ints[0] == ints[-1] == 0, "one-shot edge not zero " + r["cue"])
    # Descriptor is evidence of technical differentiation, not perceptual success.
    f, psd = signal.welch(x, fs=22050, nperseg=min(2048, len(x)))
    result["spectral_centroid_hz"] = float(np.sum(f * psd) / max(np.sum(psd), 1e-20))
    result["energy_first_55ms_fraction"] = float(np.sum(x[:1213] ** 2) / max(np.sum(x ** 2), 1e-20))
    return result


def negative_controls(project: Path, records: list[dict]) -> list[dict]:
    """Corrupt otherwise valid real assets; prove validator rejects each defect."""
    by_cue = {r["cue"]: r for r in records}
    rows = []
    with tempfile.TemporaryDirectory(prefix="ambush-audio-negative-") as temporary:
        scratch = Path(temporary)
        for defect, expected in [("clip", "clipping"), ("dc", "DC above"), ("silent", "empty/nonfinite"),
                                 ("wrong_rate", "WAV contract"), ("loop_step", "loop step"), ("wrong_hash", "hash")]:
            r = dict(by_cue["ambient_yard" if defect == "loop_step" else "fire"])
            path = scratch / r["resource_path"].removeprefix("res://")
            path.parent.mkdir(parents=True, exist_ok=True)
            original = (project / r["resource_path"].removeprefix("res://")).read_bytes()
            data = bytearray(original)
            offset = 12
            while data[offset:offset + 4] != b"data":
                count = int.from_bytes(data[offset + 4:offset + 8], "little")
                offset += 8 + count + count % 2
            start = offset + 8
            pcm = np.frombuffer(data[start:], "<i2").copy()
            if defect == "clip":
                pcm[len(pcm) // 3] = 32767
            elif defect == "dc":
                pcm = (pcm.astype(np.int32) + 8).astype("<i2")
            elif defect == "silent":
                pcm[:] = 0
            elif defect == "loop_step":
                pcm[0] += 120
            elif defect == "wrong_rate":
                data[24:28] = (24000).to_bytes(4, "little")
            data[start:] = pcm.tobytes()
            path.write_bytes(data)
            r["sha256"] = "0" * 64 if defect == "wrong_hash" else hashlib.sha256(data).hexdigest()
            try:
                check_one(scratch, r)
            except AssertionError as error:
                require(expected in str(error), f"wrong rejection for {defect}: {error}")
                rows.append({"defect": defect, "rejected": True, "reason": str(error)})
            else:
                raise AssertionError("Negative control accepted " + defect)
    return rows


def validate(project: Path, evidence: Path, source_sha: str):
    cat = json.loads((project / "art/audio_v2/catalog_candidate.json").read_text())
    source = (project / "scripts/sfx/sfx_bus.gd").read_text()
    current = re.findall(r'"([a-z_0-9]+)"', source.split("const CUES := [", 1)[1].split("]", 1)[0])
    cues = [r["cue"] for r in cat["cues"]]
    require(current == EXPECTED == cues and len(cues) == len(set(cues)) == 45, "cue set/order differs from fixed runtime / delegated set")
    require(cat["base_source_sha"] == BASE_SHA, "unexpected base")
    require({p.stem for p in (project / "art/audio_v2").glob("*.wav")} == set(EXPECTED), "extra/missing WAV")
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda r: check_one(project, r), cat["cues"]))
    by_cue = {r["cue"]: r for r in results}
    # Preserve focused sound shape expectations of existing smoke without running gameplay.
    require(by_cue["fire_bolt"]["duration_sec"] - by_cue["fire_smg"]["duration_sec"] >= .06, "bolt/SMG shape")
    require(abs(by_cue["fire_mg"]["duration_sec"] - by_cue["fire_mg42"]["duration_sec"]) >= .02, "MG/MG42 shape")
    require(10 ** (by_cue["fire"]["peak_dbfs"] / 20) > 1.15 * 10 ** (by_cue["ui"]["peak_dbfs"] / 20), "fire/UI ordering")
    require(10 ** (by_cue["tension"]["peak_dbfs"] / 20) >= .18 and 10 ** (by_cue["echo_ping"]["peak_dbfs"] / 20) >= .10, "sting shape")
    total = sum(r["bytes"] for r in results)
    decoded = sum(r["frames"] * 2 for r in cat["cues"])
    require(total == cat["production_wav_bytes"] and total <= 8 * 1024 ** 2, "8 MiB candidate disk budget")
    require(decoded == cat["decoded_pcm_bytes_all_cues"] and decoded <= 8 * 1024 ** 2, "8 MiB all-cue decoded budget")
    # Worst-case coherent category peak sum if adopter enforces proposed voice caps.
    maxima = {}
    for r in cat["cues"]:
        amplitude = 10 ** ((by_cue[r["cue"]]["true_peak_4x_dbfs"] + r["recommended_player_gain_db"] + r["bus_baseline_gain_db"]) / 20)
        maxima[r["voice_class"]] = max(maxima.get(r["voice_class"], 0), amplitude)
    summed = sum(maxima[c] * count for c, count in cat["voice_budget_recommended"].items())
    require(db(summed) <= -1, "proposed 10-voice coherent bound exceeds -1 dBFS")
    clips = []
    for path in sorted((project / "ArtSource/audio_v2/audition").glob("*.wav")):
        with wave.open(str(path)) as w:
            x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float) / 32767
        tp = np.max(np.abs(signal.resample_poly(x, 4, 1)))
        require(np.max(np.abs(x)) < .90 and tp < .95, "audition clipping " + path.name)
        clips.append({"file": path.name, "duration_sec": len(x) / 22050, "peak_dbfs": db(np.max(np.abs(x))), "true_peak_4x_dbfs": db(tp), "auditory_review": "NOT_LISTENED_NO_AUDIO_CAPABILITY"})
    controls = negative_controls(project, cat["cues"])
    report = {"status": "TECHNICAL_PASS_AUDITORY_REVIEW_PENDING", "base_source_sha": BASE_SHA,
              "validated_source_sha": source_sha, "catalog_sha256": hashlib.sha256((project / "art/audio_v2/catalog_candidate.json").read_bytes()).hexdigest(),
              "cue_count": 45, "ffmpeg_decode_pass_count": len(results), "loop_pass_count": sum("loop_seam" in r for r in results),
              "production_wav_bytes": total, "decoded_pcm_bytes_all_cues": decoded,
              "disk_and_all_cue_pcm_budget_bytes": 8 * 1024 ** 2,
              "selected_single_ambient_plus_bed_pcm_bytes": 2 * 16 * 22050 * 2,
              "proposed_max_voices": sum(cat["voice_budget_recommended"].values()),
              "proposed_coherent_true_peak_bound_dbfs": db(summed),
              "voice_caps_enforced_by_current_runtime": False,
              "gain_stress_mix_is_authored_montage_not_gameplay": True,
              "negative_controls": controls, "audition_tracks": clips, "cues": results,
              "hearing_capability": {"audio_device": False, "listening_tool": False, "listened_cues": [], "six_mission_ambiences_listened": [], "reason": "No /dev/snd, no playback/listen/transcription tool exposed; PCM/decoder inspection is not hearing"},
              "remaining": ["Actual listening and gun/mission/UI perceptual quality review", "Main author runtime adoption, loops lifecycle, gain/voice caps", "Integrated six-level battlefield mix and Android later-stage performance"]}
    evidence.mkdir(parents=True, exist_ok=True)
    (evidence / "technical_report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"AUDIO_V2_TECHNICAL_OK cues=45 loops={report['loop_pass_count']} wav_bytes={total} dc_clipping_decode=PASS hearing=NOT_LISTENED proposed_10voice_bound_dbfs={db(summed)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--evidence", type=Path)
    ap.add_argument("--source-sha", required=True)
    a = ap.parse_args()
    evidence = a.evidence or a.project / "ArtSource/audio_v2/evidence"
    validate(a.project.resolve(), evidence.resolve(), a.source_sha)
