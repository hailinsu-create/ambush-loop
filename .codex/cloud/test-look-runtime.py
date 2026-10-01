#!/usr/bin/env python3
"""Integration checks against the installed launcher, real Blender and Xvfb."""

import concurrent.futures
import ctypes
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


launcher = str(Path(sys.argv[1]).absolute())
output = Path(sys.argv[2]).absolute()
output.mkdir(parents=True, exist_ok=True)
results = {}

# Adopt any orphan produced by a broken launcher so a PID-1 reaper cannot hide
# the leak, and do not count unrelated Blender jobs running in the environment.
libc = ctypes.CDLL(None, use_errno=True)
if libc.prctl(36, 1, 0, 0, 0) != 0:  # Linux PR_SET_CHILD_SUBREAPER
    raise OSError(ctypes.get_errno(), "cannot enable test child-subreaper")


def runtime_pids():
    rows = subprocess.check_output(["ps", "-eo", "pid=,ppid=,comm="], text=True)
    processes = {int(pid): (int(parent), name)
                 for pid, parent, name in (row.split() for row in rows.splitlines())}
    owned = {os.getpid()}
    while True:
        descendants = {pid for pid, (parent, _) in processes.items() if parent in owned}
        if descendants <= owned:
            break
        owned |= descendants
    return {pid for pid, (_, name) in processes.items()
            if pid in owned and name in ("Xvfb", "blender")}


before = runtime_pids()


def execute(name, expression, expected, extra_env=None):
    env = os.environ.copy()
    env.update(extra_env or {})
    with (output / f"{name}.log").open("w") as log:
        completed = subprocess.run(
            [launcher, "--python-expr", expression], env=env,
            stdout=log, stderr=subprocess.STDOUT, timeout=40,
        )
    text = (output / f"{name}.log").read_text()
    results[name] = {"exit_code": completed.returncode, "expected": expected}
    assert completed.returncode == expected, (name, completed.returncode, text)
    return text


try:
    text = execute("success", "print('LOOK_RUNTIME_OK', flush=True)", 0)
    assert "LOOK_RUNTIME_OK" in text
    execute("python-failure", "raise RuntimeError('EXPECTED_LOOK_FAILURE')", 1)
    execute("timeout", "import time; time.sleep(60)", 124,
            {"AMBUSH_BLENDER_TIMEOUT": "2"})
    execute("invalid-timeout", "print('MUST_NOT_RUN')", 1,
            {"AMBUSH_BLENDER_TIMEOUT": "nan"})

    for signum, name in [(signal.SIGTERM, "term"), (signal.SIGINT, "interrupt")]:
        path = output / f"{name}.log"
        with path.open("w") as log:
            process = subprocess.Popen(
                [launcher, "--python-expr",
                 "import time; print('LOOK_WAITING', flush=True); time.sleep(60)"],
                stdout=log, stderr=subprocess.STDOUT,
            )
            try:
                deadline = time.monotonic() + 20
                while "LOOK_WAITING" not in path.read_text():
                    assert process.poll() is None, path.read_text()
                    assert time.monotonic() < deadline, "Blender failed to become ready"
                    time.sleep(0.1)
                # Cancel only the launcher: it must clean up its own children.
                process.send_signal(signum)
                code = process.wait(timeout=15)
                results[name] = {"exit_code": code, "expected": 128 + signum}
                assert code == 128 + signum, path.read_text()
            finally:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=15)

    expression = "import os,time; print('LOOK_DISPLAY='+os.environ['DISPLAY'],flush=True); time.sleep(2)"
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(execute, f"concurrent-{n}", expression, 0) for n in range(2)]
        displays = [re.search(r"LOOK_DISPLAY=(:\d+)", future.result()).group(1)
                    for future in futures]
    assert len(set(displays)) == 2, displays
    results["concurrent_displays"] = displays

    after = runtime_pids()
    results["new_runtime_pids"] = sorted(after - before)
    assert not after - before, f"Unreaped or running children: {after - before}"
    results["status"] = "passed"
    print("LOOK_RUNTIME_CHECKS_OK", json.dumps(results, sort_keys=True))
finally:
    (output / "runtime-checks.json").write_text(json.dumps(results, indent=2) + "\n")
