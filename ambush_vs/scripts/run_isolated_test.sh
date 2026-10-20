#!/usr/bin/env bash
# Isolated Godot test launcher for ambush_vs.
# Sets a private XDG data/config/cache root so user:// cannot touch real saves.
# Direct `godot -s res://scripts/empty_test.gd` without this wrapper must exit 91.
set -euo pipefail

godot_bin="${1:?Pass an absolute path to Godot 4.7.2}"
entry="${2:-empty_test.gd}"
case "$entry" in
  empty_test.gd|w2_sim_test.gd|w2_sim_cli.gd|w2_counterex_test.gd|w2_warehouse_counterex_test.gd|w2_counterex_probe.gd|w2_aim_tolerance_test.gd|w3_greybox_test.gd|w3_level_contract_test.gd|w4_scout_test.gd|w4_scout_carry_test.gd|w5_combat_fx_test.gd|w5b_ladder_safety_test.gd|w6_review_test.gd|w7_combat_test.gd|w8_controls_test.gd|w8_briefing_blacklist_test.gd|w9_playtest_test.gd|ux_controls_capture.gd|ux_aim_magnifier_capture.gd|ux_briefing_capture.gd) ;;
  *)
    printf 'Unsupported test entry for ambush_vs: %s\n' "$entry" >&2
    exit 2
    ;;
esac

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
run_id="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
run_dir="$project_root/build/ambush_vs_test_runs/$run_id"
data_root="$run_dir/data"
mkdir -p -- "$data_root" "$run_dir/config" "$run_dir/cache"
export XDG_DATA_HOME="$data_root"
export XDG_CONFIG_HOME="$run_dir/config"
export XDG_CACHE_HOME="$run_dir/cache"
export AMBUSH_TEST_DATA_ROOT="$data_root"
export AMBUSH_TEST_RUN_ID="$run_id"
printf 'TEST_RUN_ID=%s\nTEST_DATA_ROOT=%s\nTEST_ENTRY=%s\n' "$run_id" "$data_root" "$entry"
set +e
"$godot_bin" --headless --path "$project_root" -s "res://scripts/$entry" 2>&1 | tee "$run_dir/run.log"
exit_code=${PIPESTATUS[0]:-1}
set -e
printf 'TEST_LOG=%s\nTEST_EXIT=%s\n' "$run_dir/run.log" "$exit_code"
exit "$exit_code"
