#!/usr/bin/env bash
set -euo pipefail
export DISPLAY=:112
export AMBUSH_TEST_X11_DISPLAY=:112
export LIBGL_ALWAYS_SOFTWARE=1
export AMBUSH_TEST_SOURCE_SHA=3b4976d1f4348d828a95bb627b2fb57c8501934d
export AMBUSH_JOURNEY_SEED_RECEIPT="${AMBUSH_TEST_DATA_ROOT}/../progress-seed-receipt.json"
python3 /workspace/ambush-pr15/ambush_loop/build/player_journey/3b4976d1f434/source/scripts/seed_player_progress.py /workspace/ambush-pr15/.cursor/docs/evidence/20261004-pr15-pump-journey/run-030/ending-player-progress/manifest.json
exec /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --main-pack /workspace/ambush-pr15/ambush_loop/build/player_journey/3b4976d1f434/player-journey.pck "$@"
