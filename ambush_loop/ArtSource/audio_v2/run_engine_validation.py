#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Copy only candidate audio into an isolated minimal Godot project under /tmp.

Never imports the shared main project or invokes destructive game smoke.
Requires the fixed 4.7.2 executable; installed Godot 4.6.3 is rejected.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", type=Path, required=True)
    ap.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--source-sha", required=True)
    ap.add_argument("--evidence", type=Path)
    a = ap.parse_args()
    evidence = (a.evidence or a.project / "ArtSource/audio_v2/evidence").resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="ambush-audio-v2-") as temporary:
        scratch = Path(temporary)
        env = dict(os.environ)
        for var, folder in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
            env[var] = str(scratch / folder)
            (scratch / folder).mkdir()
        version = subprocess.run([str(a.godot), "--version"], env=env, capture_output=True, text=True, check=True).stdout.strip()
        if not version.startswith("4.7.2.stable"):
            raise RuntimeError("Expected 4.7.2, got " + version)
        shutil.copytree(a.project / "art/audio_v2", scratch / "art/audio_v2")
        shutil.copyfile(Path(__file__).with_name("engine_probe.gd"), scratch / "probe.gd")
        (scratch / "project.godot").write_text('config_version=5\n[application]\nconfig/name="AmbushAudioV2IsolatedImport"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        commands = [[str(a.godot), "--headless", "--editor", "--path", str(scratch), "--import"],
                    [str(a.godot), "--headless", "--audio-driver", "Dummy", "--path", str(scratch), "--script", "res://probe.gd"]]
        exits = []
        for i, command in enumerate(commands):
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=180)
            output = result.stdout + result.stderr
            (evidence / ("godot_import.log" if i == 0 else "godot_probe.log")).write_text(output)
            exits.append(result.returncode)
            print("GODOT_STAGE", i, "exit", result.returncode)
            if result.returncode or any(flag in output for flag in ["SCRIPT ERROR:", "ERROR:", "WARNING:"]):
                print(output[-7000:])
                raise RuntimeError("Godot stage failed or reported warnings")
        report = json.loads((scratch / "engine_report.json").read_text())
        report.update({"validated_source_sha": a.source_sha, "exits": exits,
                       "isolated_minimal_project": True, "player_save_touched": False,
                       "main_runtime_integrated": False, "no_device_or_simulator_test": True})
        (evidence / "godot_report.json").write_text(json.dumps(report, indent=2) + "\n")
        if report["cue_count"] != 45 or not all(r["pass"] for r in report["cues"]):
            raise RuntimeError("Incomplete engine report")
        print("AUDIO_V2_GODOT_VALIDATION_OK cues=45 exits=0,0 engine=" + version + " hearing=NOT_LISTENED")


if __name__ == "__main__":
    main()
