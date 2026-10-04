#!/usr/bin/env bash
export DISPLAY=:125
export AMBUSH_TEST_SOURCE_SHA=a44a33ee348fa53e1b1c6d539d7ffcf114e4283c
export AMBUSH_A3_GAME_TREE=4d2acd43abdb4b6b7d0189eed3e2f085e1ab9dac
export AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-window-controls/provenance-a44-yard.json
export AMBUSH_A3_LEVEL=yard
export AMBUSH_A3_STOP_FILE=/tmp/pr15-a3-window-controls/a3-yard-a44-safe-stop
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-yard-a44.start
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_campaign_metrics_test.gd --render > /tmp/pr15-a3-window-controls/a3-yard-a44.log 2>&1 &
a44_yard_pid=$!
printf '%s\n' "$a44_yard_pid" > /tmp/pr15-a3-window-controls/a3-yard-a44.pid
wait "$a44_yard_pid"
a44_yard_exit=$?
printf '%s\n' "$a44_yard_exit" > /tmp/pr15-a3-window-controls/a3-yard-a44.exit
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-yard-a44.end
exit "$a44_yard_exit"
