#!/usr/bin/env python3
"""Run Blender with a private authenticated Xvfb and reap both children."""

import math
import os
from pathlib import Path
import secrets
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time


class Cancelled(Exception):
    pass


def stop(process):
    """Only terminate the process group created by this launcher, then wait."""
    if process is None:
        return
    if process.poll() is None:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
    else:
        process.wait()


def run(args):
    cancelled = 0

    def on_signal(signum, _frame):
        nonlocal cancelled
        cancelled = signum

    def check_cancelled():
        if cancelled:
            raise Cancelled()

    previous = {s: signal.signal(s, on_signal) for s in (signal.SIGINT, signal.SIGTERM)}
    server = blender = None
    read_fd = write_fd = None
    try:
        xvfb = shutil.which("Xvfb")
        xauth = shutil.which("xauth")
        if not xvfb or not xauth:
            raise RuntimeError("Xvfb and xauth required; install them during environment setup")
        executable = Path(__file__).absolute().with_name("blender")
        if not executable.is_file() or not os.access(executable, os.X_OK):
            raise RuntimeError(f"Blender executable missing: {executable}")
        threads = int(os.environ.get("AMBUSH_BLENDER_THREADS", "2"))
        timeout = float(os.environ.get("AMBUSH_BLENDER_TIMEOUT", "900"))
        if not 1 <= threads <= 1024 or not math.isfinite(timeout) or timeout <= 0:
            raise ValueError("threads must be 1..1024 and timeout must be finite and positive")

        with tempfile.TemporaryDirectory(prefix="ambush-look-") as temp:
            authority = Path(temp) / "Xauthority"
            authority.touch(mode=0o600)
            cookie = secrets.token_hex(16)

            def authorize(display):
                # Send the ephemeral cookie through stdin, never argv or logs.
                subprocess.run(
                    [xauth, "-f", str(authority), "source", "-"],
                    input=f"add :{display} MIT-MAGIC-COOKIE-1 {cookie}\n",
                    text=True, check=True, timeout=10,
                    stdout=subprocess.DEVNULL,
                )

            # Xvfb loads cookies independently of the display number. Add the
            # client record for its allocated number after readiness is known.
            authorize(0)
            check_cancelled()
            read_fd, write_fd = os.pipe()
            server = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1280x720x24",
                 "-nolisten", "tcp", "-auth", str(authority)],
                pass_fds=(write_fd,), start_new_session=True,
                stdout=subprocess.DEVNULL,
            )
            os.close(write_fd)
            write_fd = None
            try:
                deadline = time.monotonic() + 15
                display_bytes = b""
                while b"\n" not in display_bytes:
                    check_cancelled()
                    if server.poll() is not None:
                        raise RuntimeError(f"Xvfb exited before readiness: {server.returncode}")
                    if time.monotonic() >= deadline:
                        raise RuntimeError("Xvfb readiness timed out")
                    if select.select([read_fd], [], [], 0.1)[0]:
                        chunk = os.read(read_fd, 32)
                        if not chunk:
                            raise RuntimeError("Xvfb closed its readiness pipe")
                        display_bytes += chunk
                        if len(display_bytes) > 32:
                            raise RuntimeError("invalid Xvfb display response")
                display = display_bytes.strip().decode("ascii")
                if not display.isdecimal():
                    raise RuntimeError("invalid Xvfb display number")
                os.close(read_fd)
                read_fd = None
                authorize(display)
                check_cancelled()
                child_env = os.environ.copy()
                child_env.update(DISPLAY=f":{display}", XAUTHORITY=str(authority))
                blender = subprocess.Popen(
                    [str(executable), "--background", "--factory-startup",
                     "--gpu-backend", "opengl", "--threads", str(threads),
                     "--python-exit-code", "1", *args],
                    env=child_env, start_new_session=True,
                )
                deadline = time.monotonic() + timeout
                while blender.poll() is None:
                    check_cancelled()
                    if server.poll() is not None:
                        raise RuntimeError(f"Xvfb exited during Blender: {server.returncode}")
                    if time.monotonic() >= deadline:
                        print("AMBUSH_LOOK_TIMEOUT: Blender did not exit before deadline", file=sys.stderr)
                        return 124
                    time.sleep(0.1)
                check_cancelled()
                code = blender.wait()
                return code if code >= 0 else 128 - code
            finally:
                # Keep auth and the display alive until Blender has stopped.
                stop(blender)
                stop(server)
    except Cancelled:
        return 128 + cancelled
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        print(f"AMBUSH_LOOK_ERROR: {exc}", file=sys.stderr)
        return 128 + cancelled if cancelled else 1
    finally:
        for fd in (read_fd, write_fd):
            if fd is not None:
                os.close(fd)
        for sig, handler in previous.items():
            signal.signal(sig, handler)


if __name__ == "__main__":
    sys.exit(run(sys.argv[1:]))
