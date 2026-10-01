"""Read-only identity gate before Ambush Loop's vivo acceptance tests."""
import argparse
import json
import re
import subprocess

PACKAGE = "com.ambushloop.game"


class PreflightError(Exception):
    pass


def adb_read(adb, args):
    # No installation, permission change, app launch, log clearing or file writes.
    try:
        result = subprocess.run([adb, *args], capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=15)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PreflightError(type(error).__name__) from error
    if result.returncode:
        raise PreflightError("adb command failed")
    return result.stdout


def device_rows(output):
    rows = []
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith(("List of devices", "*")):
            continue
        fields = line.split()
        if len(fields) >= 2:
            rows.append((fields[0], fields[1]))
    return rows


def inspect_device(adb, serial=None, expected_model="V2266A", expected_code=80,
                   expected_name="0.6.30-font-cache-diag", read=adb_read):
    rows = device_rows(read(adb, ["devices", "-l"]))
    if serial:
        candidates = [row for row in rows if row[0] == serial]
    else:
        candidates = rows
    if len(candidates) != 1:
        return {"ready": False, "reason": "select_one_device", "device_count": len(candidates)}
    target, state = candidates[0]
    if state != "device":
        return {"ready": False, "reason": "device_not_authorized", "state": state}
    prefix = ["-s", target, "shell"]
    model = read(adb, prefix + ["getprop", "ro.product.model"]).strip()
    if model != expected_model:
        return {"ready": False, "reason": "wrong_model", "model": model}
    installed = read(adb, prefix + ["pm", "path", PACKAGE])
    if not any(line.startswith("package:") for line in installed.splitlines()):
        return {"ready": False, "reason": "package_missing", "model": model}
    details = read(adb, prefix + ["dumpsys", "package", PACKAGE])
    code = re.search(r"^\s*versionCode=(\d+)\b", details, re.MULTILINE)
    name = re.search(r"^\s*versionName=([^\r\n]+)", details, re.MULTILINE)
    identity = {"model": model, "package": PACKAGE,
                "version_code": int(code[1]) if code else None,
                "version_name": name[1].strip() if name else None}
    matches = identity["version_code"] == expected_code and identity["version_name"] == expected_name
    return {"ready": matches, "reason": "identity_verified" if matches else "wrong_version", **identity}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", help="Required when multiple USB/Wi-Fi entries exist")
    parser.add_argument("--expected-model", default="V2266A")
    parser.add_argument("--expected-code", type=int, default=80)
    parser.add_argument("--expected-name", default="0.6.30-font-cache-diag")
    args = parser.parse_args()
    try:
        report = inspect_device(args.adb, args.serial, args.expected_model,
                                args.expected_code, args.expected_name)
    except PreflightError as error:
        report = {"ready": False, "reason": "adb_unavailable", "error": str(error)}
    print(json.dumps(report, ensure_ascii=False))
    return 0 if report["ready"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
