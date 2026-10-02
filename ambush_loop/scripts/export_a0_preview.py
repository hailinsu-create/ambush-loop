#!/usr/bin/env python3
"""Build the separate A0 debug APK from an isolated source copy, without player data.

Requires official Godot 4.7.2, JDK 17, Android SDK 36 and matching Android templates.
The normal project, export presets, editor settings and signing keys are untouched.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("godot", "java", "sdk", "templates"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--version-code", type=int, default=2026100201)
    parser.add_argument("--abi", choices=("arm64-v8a", "x86_64"), default="arm64-v8a",
                        help="x86_64 is for cloud Android emulator verification only.")
    args = parser.parse_args()
    if not sys.platform.startswith("linux"):
        raise SystemExit("This isolated exporter currently supports Linux hosts.")
    source = Path(__file__).resolve().parents[1]
    godot, java, sdk, templates = (getattr(args, name).resolve() for name in ("godot", "java", "sdk", "templates"))
    exe_suffix = ".exe" if os.name == "nt" else ""
    java_exe = java / "bin" / ("java" + exe_suffix)
    if not 0 < args.version_code < 2100000000:
        raise SystemExit("Version code must be in Android's positive supported range.")
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    java_version = subprocess.check_output([java_exe, "-version"], stderr=subprocess.STDOUT, text=True)
    if not version.startswith("4.7.2.stable") or 'version "17.' not in java_version:
        raise SystemExit("Use Godot 4.7.2 and JDK 17.")
    required = [templates / "android_debug.apk", templates / "version.txt",
                sdk / "platforms/android-36/android.jar", sdk / "build-tools/36.0.0/aapt"]
    if not all(p.is_file() for p in required) or (templates / "version.txt").read_text().strip() != "4.7.2.stable":
        raise SystemExit("Matching Android templates and SDK 36/build-tools 36.0.0 are required.")
    build = source / "build/a0_exports" / uuid.uuid4().hex
    build.mkdir(parents=True)
    (source / "build/.gdignore").touch()
    staged = build / "source"
    shutil.copytree(source, staged, ignore=shutil.ignore_patterns(".godot", "build", "ArtSource", "docs", "*.md", "__pycache__"))
    data = build / "data"
    config = build / "config"
    env = os.environ.copy()
    env.update(XDG_DATA_HOME=str(data), XDG_CONFIG_HOME=str(config), XDG_CACHE_HOME=str(build / "cache"),
               JAVA_HOME=str(java), ANDROID_HOME=str(sdk), ANDROID_SDK_ROOT=str(sdk))
    env["PATH"] = str(java / "bin") + os.pathsep + env["PATH"]
    template_out = data / "godot/export_templates/4.7.2.stable"
    template_out.mkdir(parents=True)
    for name in ("android_debug.apk", "android_release.apk", "version.txt"):
        if (templates / name).is_file():
            shutil.copy2(templates / name, template_out / name)
    # Reuse a local debug key so later samples can update this package in place.
    # It is deliberately outside the staged source and ignored by git.
    key = build.parent / "a0-debug.keystore"
    if not key.exists():
        subprocess.run([str(java / "bin" / ("keytool" + exe_suffix)), "-genkeypair", "-keystore", str(key),
                        "-storepass", "android", "-alias", "androiddebugkey", "-keypass", "android",
                        "-dname", "CN=Android Debug,O=Android,C=US", "-keyalg", "RSA", "-keysize", "2048",
                        "-validity", "10000"], check=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # TRES string values are JSON-compatible. Values never enter a shell command.
    settings = config / "godot/editor_settings-4.7.tres"
    settings.parent.mkdir(parents=True)
    values = {"export/android/java_sdk_path": str(java), "export/android/android_sdk_path": str(sdk),
              "export/android/debug_keystore": str(key), "export/android/debug_keystore_user": "androiddebugkey",
              "export/android/debug_keystore_pass": "android"}
    settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
                        "\n".join(k + " = " + json.dumps(v) for k, v in values.items()) + "\n")
    project = staged / "project.godot"
    project.write_text(project.read_text().replace('run/main_scene="res://scenes/title.tscn"',
                       'run/main_scene="res://scenes/presentation/preview_boot.tscn"'))
    presets = staged / "export_presets.cfg"
    text = presets.read_text()
    text = text[text.index("[preset.2]"):].replace("[preset.2", "[preset.0")
    replacements = {
        'name="Android APK"': 'name="A0 Preview"',
        'custom_features="mobile"': 'custom_features="mobile,a0_preview"',
        'version/code=77': 'version/code=' + str(args.version_code),
        'version/name="0.6.28"': 'version/name="0.7.0-a0.1"',
        'package/unique_name="com.ambushloop.game"': 'package/unique_name="com.ambushloop.game.a0"',
        'package/name="Ambush Loop"': 'package/name="Ambush Loop A0"',
        'exclude_filter="docs/*,*.md"': 'exclude_filter="ArtSource/*,docs/*,*.md,scripts/*test*.gd,scripts/*dump*.gd,scripts/*capture*.gd,scripts/presentation_preview.gd"',
    }
    for old, new in replacements.items():
        if old not in text:
            raise SystemExit("Export preset changed; review A0 transformation: " + old)
        text = text.replace(old, new, 1)
    if args.abi == "x86_64":
        text = text.replace("architectures/arm64-v8a=true", "architectures/arm64-v8a=false")
        text = text.replace("architectures/x86_64=false", "architectures/x86_64=true")
    presets.write_text(text)
    apk = build / ("AmbushLoop-A0.apk" if args.abi == "arm64-v8a" else "AmbushLoop-A0-emulator.apk")
    log_path = build / "export.log"
    with log_path.open("w") as log:
        for flags in (["--editor", "--import"], ["--export-debug", "A0 Preview", str(apk)]):
            result = subprocess.run([str(godot), "--headless", "--path", str(staged), *flags],
                                    env=env, stdout=log, stderr=subprocess.STDOUT)
            if result.returncode:
                raise SystemExit(f"Godot exited {result.returncode}; see {log_path}")
    if not apk.is_file():
        raise SystemExit("Exporter produced no APK; see " + str(log_path))
    tools = sdk / "build-tools/36.0.0"
    badging = subprocess.check_output([str(tools / "aapt"), "dump", "badging", str(apk)], text=True, env=env)
    subprocess.run([str(tools / "apksigner"), "verify", str(apk)], env=env, check=True)
    if "package: name='com.ambushloop.game.a0'" not in badging or ("native-code: '" + args.abi + "'") not in badging:
        raise SystemExit("Unexpected package identity or ABI.")
    (build / "badging.txt").write_text(badging)
    manifest = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip(),
                "source_dirty": bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=source, text=True).strip()),
                "godot": version, "java": java_version.splitlines()[0], "version_code": args.version_code,
                "abi": args.abi,
                "package": "com.ambushloop.game.a0", "apk_bytes": apk.stat().st_size,
                "apk_sha256": hashlib.sha256(apk.read_bytes()).hexdigest(), "validation": "export+aapt+apksigner; device pending"}
    (build / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("A0_APK=" + str(apk))
    print("A0_EXPORT_MANIFEST=" + str(build / "manifest.json"))
    print(json.dumps(manifest))


if __name__ == "__main__":
    main()
