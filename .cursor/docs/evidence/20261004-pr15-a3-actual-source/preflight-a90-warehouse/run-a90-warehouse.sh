#!/usr/bin/env bash
export DISPLAY=:125
export AMBUSH_TEST_SOURCE_SHA=a90eb0798914c023f5c8902303c72f2619abd7c2
export AMBUSH_A3_GAME_TREE=ec73ed78833b5608919ae98e39ba7a58c4e03f41
export AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-window-controls/provenance-a90-warehouse.json
export AMBUSH_A3_LEVEL=warehouse
export AMBUSH_A3_STOP_FILE=/tmp/pr15-a3-window-controls/a3-warehouse-a90-safe-stop
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-warehouse-a90.start
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_campaign_metrics_test.gd --render > /tmp/pr15-a3-window-controls/a3-warehouse-a90.log 2>&1 &
a90_warehouse_pid=$!
printf '%s\n' "$a90_warehouse_pid" > /tmp/pr15-a3-window-controls/a3-warehouse-a90.pid
wait "$a90_warehouse_pid"
a90_warehouse_exit=$?
printf '%s\n' "$a90_warehouse_exit" > /tmp/pr15-a3-window-controls/a3-warehouse-a90.exit
date -u +%FT%TZ > /tmp/pr15-a3-window-controls/a3-warehouse-a90.end
exit "$a90_warehouse_exit"
