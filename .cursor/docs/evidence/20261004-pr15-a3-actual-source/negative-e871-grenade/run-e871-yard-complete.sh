#!/usr/bin/env bash
export DISPLAY=:125
export AMBUSH_TEST_SOURCE_SHA=e8718380b56094512c54df6ed18e10828df6e236
export AMBUSH_A3_GAME_TREE=5ac07d768e5ca631a89d1c1bc7b5b8f402b84443
export AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-window-controls/provenance-e871-yard.json
export AMBUSH_A3_LEVEL=yard
export AMBUSH_A3_STOP_FILE=/tmp/pr15-a3-window-controls/a3-yard-e871-complete-safe-stop
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-yard-e871-complete.start
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_campaign_metrics_test.gd --render > /tmp/pr15-a3-window-controls/a3-yard-e871-complete.log 2>&1 &
yard_complete_pid=$!
printf '%s\n' "$yard_complete_pid" > /tmp/pr15-a3-window-controls/a3-yard-e871-complete.pid
wait "$yard_complete_pid"
yard_complete_exit=$?
printf '%s\n' "$yard_complete_exit" > /tmp/pr15-a3-window-controls/a3-yard-e871-complete.exit
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-yard-e871-complete.end
exit "$yard_complete_exit"
