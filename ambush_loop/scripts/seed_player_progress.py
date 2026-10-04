"""Copy two hash-pinned real ConfigFiles into a new guarded Linux test run.

Run from the Godot wrapper after run_isolated_test.sh sets its private XDG.
No unlocks/settings are synthesized and no other user files are copied.
"""
import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1]).resolve(strict=True)
manifest = json.loads(manifest_path.read_text())
run_id = os.environ["AMBUSH_TEST_RUN_ID"]
data = Path(os.environ["AMBUSH_TEST_DATA_ROOT"]).resolve(strict=True)
if not re.fullmatch(r"[0-9a-f]{32}", run_id) or data.parts[-3:] != ("ambush_test_runs", run_id, "data"):
    raise SystemExit("Player progress seed requires a fresh guarded test run")
if Path(os.environ["XDG_DATA_HOME"]).resolve() != data:
    raise SystemExit("Player progress seed XDG differs from guarded data root")
if set(manifest["files"]) != {"ambush_loop.cfg", "ambush_loop_settings.cfg"} or manifest["provenance"] != "actual native player WON and original Continue":
    raise SystemExit("Seed must pin the two files from an actual native win")
destination = data / "godot/app_userdata/Ambush Loop"
if destination.exists():
    raise SystemExit("Refuse to overwrite existing test user data")
receipt = {"manifest": str(manifest_path), "manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
           "origin": manifest, "run_id": run_id, "files": {}}
for name, record in manifest["files"].items():
    if hashlib.sha256((manifest_path.parent / name).read_bytes()).hexdigest() != record["sha256"]:
        raise SystemExit("Source save hash differs: " + name)
destination.mkdir(parents=True)
for name, record in manifest["files"].items():
    shutil.copyfile(manifest_path.parent / name, destination / name)
    actual = hashlib.sha256((destination / name).read_bytes()).hexdigest()
    if actual != record["sha256"]:
        raise SystemExit("Copied save hash differs: " + name)
    receipt["files"][name] = {"sha256": actual, "destination": str(destination / name)}
receipt_path = data.parent / "progress-seed-receipt.json"
receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
print("PLAYER_PROGRESS_SEED_RECEIPT=" + str(receipt_path))
