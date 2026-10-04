#!/usr/bin/env bash
set -euo pipefail
export DISPLAY=:112
export AMBUSH_TEST_X11_DISPLAY=:112
export AMBUSH_TEST_SOURCE_SHA=124057250ffbaf3390da7689fd968acf072ee1b4
export LIBGL_ALWAYS_SOFTWARE=1
exec /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --main-pack /workspace/ambush-pr15/ambush_loop/build/player_journey/124057250ffb/player-journey.pck "$@"
