#!/usr/bin/env bash
set -euo pipefail
exec /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --display-driver x11 --audio-driver Dummy "$@"
