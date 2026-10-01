#!/usr/bin/env python3
"""Run real cloud checks on an isolated archive of the exact checked-out commit."""
import argparse
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--tools-dir", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
output = args.output.resolve()
if output.exists():
    raise SystemExit("Output must be a new directory; never reuse old evidence")
output.mkdir(parents=True)
tools = args.tools_dir.resolve() / "bin"
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
result = {"source_sha": sha, "technical_status": "failed",
          "external_gpt_review": "unavailable", "product_snapshot": "unverified",
          "checks": {}}


def run(name, command, cwd, timeout=180, markers=()):
    with (output / f"{name}.log").open("w") as log:
        try:
            completed = subprocess.run(command, cwd=cwd, stdout=log,
                                       stderr=subprocess.STDOUT, timeout=timeout)
        except subprocess.TimeoutExpired:
            result["checks"][name] = {"status": "timeout", "exit_code": None}
            raise
    text = (output / f"{name}.log").read_text()
    result["checks"][name] = {"exit_code": completed.returncode, "status": "failed"}
    if completed.returncode != 0:
        raise RuntimeError(f"{name} exited {completed.returncode}; see {name}.log")
    for marker in markers:
        if marker not in text:
            raise RuntimeError(f"{name}: missing marker {marker}")
    result["checks"][name]["status"] = "passed"


try:
    # Ignored local files are never used as source or included in evidence.
    if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=normal"],
                               cwd=repo, text=True).strip():
        raise RuntimeError("Commit changes first: verification requires a clean source checkout")
    expected = subprocess.check_output(["git", "show", f"{sha}:.codex/cloud/blender-headless.py"], cwd=repo)
    if (tools / "blender-headless").read_bytes() != expected:
        raise RuntimeError("Installed launcher differs from the source commit")
    run("godot-version", [str(tools / "godot"), "--version"], repo, markers=("4.7.2.stable",))
    run("blender-version", [str(tools / "blender"), "--version"], repo, markers=("Blender 5.2.2",))
    run("gltf-version", [str(tools / "gltf-transform"), "--version"], repo, markers=("4.5.1",))
    run("lifecycle", ["python3", str(repo / ".codex/cloud/test-look-runtime.py"),
                      str(tools / "blender-headless"), str(output / "runtime")], repo,
        timeout=240, markers=("LOOK_RUNTIME_CHECKS_OK",))
    with tempfile.TemporaryDirectory(prefix="ambush-cloud-verify-") as temporary:
        isolated = Path(temporary)
        archive = isolated / "source.tar"
        with archive.open("wb") as stream:
            subprocess.run(["git", "archive", sha], cwd=repo, stdout=stream, check=True)
        subprocess.run(["tar", "-xf", str(archive), "-C", str(isolated)], check=True)
        archive.unlink()
        art = isolated / "ambush_loop/ArtSource"
        names = ["yard_crate.glb", "yard_crate_turnaround.png", "yard_crate_iso.png", "yard_crate_top.png"]
        for name in names:
            (art / name).unlink(missing_ok=True)
        run("render", [str(tools / "blender-headless"), "--python", str(art / "build_yard_crate.py")],
            isolated, timeout=960, markers=("Blender quit",))
        run("gltf-inspect", [str(tools / "gltf-transform"), "inspect", str(art / names[0])], isolated)
        sizes = {}
        for name, size in zip(names[1:], [(960, 480), (256, 256), (256, 192)]):
            data = (art / name).read_bytes()
            if data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != size:
                raise RuntimeError(f"Wrong rendered PNG: {name}")
            sizes[name] = size
        result["rendered_dimensions"] = sizes
        for name in names:
            shutil.copy2(art / name, output / name)
        project = isolated / "ambush_loop"
        run("godot-import", [str(tools / "godot"), "--headless", "--editor", "--path", str(project), "--import"],
            isolated, timeout=300)
        run("accept-gate", ["bash", str(project / "scripts/run_isolated_test.sh"),
                            str(tools / "godot"), "accept_cta_flow_gate.gd"], isolated,
            markers=("TEST_STORAGE_ISOLATED", "ACCEPT_CTA_FLOW_OK level=yard"))
    result["technical_status"] = "passed"
finally:
    (output / "verification.json").write_text(json.dumps(result, indent=2) + "\n")
    summary = (f"Source: `{sha}`\n\nTechnical checks: **{result['technical_status']}**\n\n"
               "External GPT review: **unavailable** (no authenticated Project interface).\n\n"
               "Product snapshot: **unverified**. CI is not publication or Android acceptance.\n")
    (output / "summary.md").write_text(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as stream:
            stream.write(summary)
