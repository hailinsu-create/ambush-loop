#!/usr/bin/env bash
set -euo pipefail
export DISPLAY=:112
export AMBUSH_TEST_X11_DISPLAY=:112
export AMBUSH_TEST_SOURCE_SHA=d7e6fe1fb3a9251ded4e3f0692d194880476cf07
export LIBGL_ALWAYS_SOFTWARE=1
exec /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --main-pack /workspace/ambush-pr15/ambush_loop/build/player_journey/d7e6fe1fb3a9/player-journey.pck "$@"
