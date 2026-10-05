#!/usr/bin/env bash
set -euo pipefail

godot_bin="${1:?Pass an absolute path to Godot 4.7.2}"
entry="${2:-smoke_test.gd}"
render_mode="${3:---headless}"
case "$entry" in
  escape_context_boundary_test.gd|shot_fx_boundary_test.gd|shot_fx_source_test.gd|replay_arrow_input_test.gd|smoke_contract_test.gd|escape_intel_source_test.gd|static_teaching_context_test.gd|loot_event_text_test.gd|live_wave_timeline_test.gd|current_wave_hint_test.gd|campaign_result_copy_test.gd|result_highlight_test.gd|cover_command_test.gd|replay_event_text_source_test.gd|first_visit_journey_test.gd|title_focus_keyboard_test.gd|title_menu_viewport_test.gd|replay_autoplay_test.gd) ;;
  full_command_record_replay_test.gd|replay_timeline_test.gd|equipment_freeze_test.gd|presentation_lifecycle_test.gd|campaign_replay_test.gd|visual_snapshot_test.gd|asset_library_test.gd|asset_pack_test.gd|phase_tools_test.gd|actor_visual_test.gd|c2_history_hint_test.gd|actor_battle_test.gd|audio_runtime_test.gd|firearm_runtime_test.gd|environment_assets_test.gd|environment_battle_test.gd|command_pose_clock_test.gd|command_record_replay_test.gd|utility_runtime_test.gd) ;;
  editor_import|corpse_pairing_boundary_test.gd|result_viewport_test.gd|radio_credits_viewport_test.gd|viewport_hud_test.gd|corpse_pose_quality_test.gd|presentation_quality_test.gd|corpse_contact_test.gd|corpse_runtime_test.gd|replay_fx_lifecycle_test.gd|asset_review_capture.gd|presentation_contract_test.gd|presentation_interaction_test.gd|camera_input_test.gd|presentation_capture.gd|presentation_preview.gd) ;;
  smoke_test.gd|pathfinder_test.gd|feel_gate.gd|playable_dump.gd|visual_dump.gd|storage_probe.gd|eval_dump_0de4f1d.gd|eval_dump_71ca4af.gd|eval_dump_v030.gd|eval_dump_v031.gd|eval_dump_v040.gd|eval_dump_touch_hud.gd) ;;
  *) printf 'Unsupported destructive test entry: %s\n' "$entry" >&2; exit 2 ;;
esac
case "$render_mode" in
  --headless) engine_flags=(--headless) ;;
  --render) engine_flags=(--rendering-method gl_compatibility) ;;
  *) printf 'Unsupported rendering mode: %s\n' "$render_mode" >&2; exit 2 ;;
esac
if [[ "$entry" == *capture.gd || "$entry" == escape_context_boundary_test.gd || "$entry" == escape_intel_source_test.gd ]]; then
  engine_flags+=(--audio-driver Dummy)
fi

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
run_id="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
run_dir="$project_root/build/ambush_test_runs/$run_id"
data_root="$run_dir/data"
mkdir -p -- "$data_root"
touch "$project_root/build/.gdignore"
export XDG_DATA_HOME="$data_root"
export XDG_CONFIG_HOME="$run_dir/config"
export XDG_CACHE_HOME="$run_dir/cache"
export AMBUSH_TEST_DATA_ROOT="$data_root"
export AMBUSH_TEST_RUN_ID="$run_id"
launch_root="$project_root"
if [[ "$entry" == asset_pack_test.gd ]]; then
  test_pack="${AMBUSH_TEST_PACK:?Pass an exported PCK in AMBUSH_TEST_PACK}"
  [[ -f "$test_pack" ]] || { printf 'Missing test pack: %s\n' "$test_pack" >&2; exit 2; }
  test_pack="$(realpath -- "$test_pack")"
  launch_root="$run_dir/packed-project"
  mkdir -p -- "$launch_root"
  export AMBUSH_ASSET_PACK_ROOT="$launch_root"
  engine_flags+=(--main-pack "$test_pack" --audio-driver Dummy)
fi
printf 'TEST_RUN_ID=%s\nTEST_DATA_ROOT=%s\nTEST_ENTRY=%s\n' "$run_id" "$data_root" "$entry"
if [[ "$entry" == editor_import ]]; then
  "$godot_bin" --headless --editor --path "$project_root" --import 2>&1 | tee "$run_dir/run.log"
else
  "$godot_bin" "${engine_flags[@]}" --path "$launch_root" -s "res://scripts/$entry" 2>&1 | tee "$run_dir/run.log"
fi
printf 'TEST_LOG=%s\n' "$run_dir/run.log"
