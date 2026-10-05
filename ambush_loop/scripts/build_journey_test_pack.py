"""Build isolated PCK with existing a0_preview feature; keep title/main flow.
No asset production generators or original project/preset edits.
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

source = Path(__file__).resolve().parents[1]
repo = source.parent
godot = Path(sys.argv[1]).resolve(strict=True)
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
if subprocess.check_output(["git", "status", "--porcelain", "--", "ambush_loop"], cwd=repo, text=True):
    raise SystemExit("Commit game source before building a fixed journey pack")
build = source / "build/player_journey" / sha[:12]
build.mkdir(parents=True, exist_ok=False)
staged = build / "source"
shutil.copytree(source, staged, ignore=shutil.ignore_patterns(".godot", "build", "ArtSource", "docs", "*.md", "__pycache__"))
presets = staged / "export_presets.cfg"
text = presets.read_text()
assert 'name="Linux Desktop"' in text and 'custom_features=""' in text
presets.write_text(text.replace('custom_features=""', 'custom_features="a0_preview"', 1))
env = os.environ.copy()
env.update(XDG_DATA_HOME=str(build / "data"), XDG_CONFIG_HOME=str(build / "config"), XDG_CACHE_HOME=str(build / "cache"))
for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
    Path(env[key]).mkdir(parents=True)
pack = build / "player-journey.pck"
commands = [[str(godot), "--headless", "--editor", "--path", str(staged), "--import"],
            [str(godot), "--headless", "--path", str(staged), "--export-pack", "Linux Desktop", str(pack)]]
results = []
with (build / "build.log").open("w") as log:
    for command in commands:
        result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT)
        results.append({"command": command, "actual_exit": result.returncode})
        if result.returncode:
            (build / "build-failure.json").write_text(json.dumps({"source_sha": sha, "commands": results}, indent=2))
            raise SystemExit(result.returncode)
receipt = {"source_sha": sha, "game_tree": subprocess.check_output(["git", "rev-parse", "HEAD:ambush_loop"], cwd=repo, text=True).strip(),
           "commands": results, "pack": str(pack), "sha256": hashlib.sha256(pack.read_bytes()).hexdigest(), "bytes": pack.stat().st_size,
           "staging_changes": "Only Linux Desktop custom_features=a0_preview; original title/main scene and rendering configuration kept", "asset_generators_run": False}
(build / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt))
