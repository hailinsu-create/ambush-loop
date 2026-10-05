#!/usr/bin/env bash
set -euo pipefail
export DISPLAY=:112
export AMBUSH_TEST_X11_DISPLAY=:112
export LIBGL_ALWAYS_SOFTWARE=1
export AMBUSH_TEST_SOURCE_SHA=bfc2374f68b522dffb7a8247224c366c78ba1830
export AMBUSH_JOURNEY_SEED_RECEIPT="${AMBUSH_TEST_DATA_ROOT}/../progress-seed-receipt.json"
python3 /workspace/ambush-pr15/ambush_loop/build/player_journey/bfc2374f68b5/source/scripts/seed_player_progress.py /workspace/ambush-pr15/.cursor/docs/evidence/20261004-pr15-remaining-journey/origin-d7-yard-player/manifest.json
exec /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --main-pack /workspace/ambush-pr15/ambush_loop/build/player_journey/bfc2374f68b5/player-journey.pck "$@"
