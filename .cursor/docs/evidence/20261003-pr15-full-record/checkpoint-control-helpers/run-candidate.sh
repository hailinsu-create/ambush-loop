#!/usr/bin/env bash
set -uo pipefail
cd /workspace/ambush-pr15 || exit 2
source_sha=15c0783059bb7c2f9e9cd9b7252a9343e71f4168
godot_bin=/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64
run_one() {
  local name="$1" entry="$2" mode="$3" report="$4" engine="$godot_bin"
  [[ "$mode" == render ]] && engine=/tmp/pr15-full-godot
  if [[ "$(git rev-parse HEAD)" != "$source_sha" ]] || [[ -n "$(git diff --name-only)" ]]; then
    printf 'Source changed before %s\n' "$name"; return 2
  fi
  env AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin \
    bash ambush_loop/scripts/run_isolated_test.sh "$engine" "$entry" "--$mode" >"/tmp/pr15-full-final-$name.log" 2>&1
  local result=$?
  printf '%s\n' "$result" >"/tmp/pr15-full-final-$name.exit"
  python3 /tmp/pr15_archive_full.py "$name" "$source_sha" "$entry" "$engine" "$mode" "$report"
  return "$result"
}
case "${1:-}" in
  command-headless) run_one command-headless full_command_record_replay_test.gd headless command-record-report.json ;;
  campaign-headless-a|campaign-headless-b)
    levels=(yard warehouse pump)
    [[ "$1" == campaign-headless-b ]] && levels=(railcut depot radio)
    result=0
    for level in "${levels[@]}"; do
      export AMBUSH_CAMPAIGN_LEVEL="$level"
      run_one "campaign-$level-headless" campaign_replay_test.gd headless "full-campaign-$level-record-report.json" || result=1
    done
    exit "$result"
    ;;
  render)
    result=0
    export AMBUSH_CAMPAIGN_LEVEL=yard
    run_one campaign-yard-render campaign_replay_test.gd render full-campaign-yard-record-report.json || result=1
    unset AMBUSH_CAMPAIGN_LEVEL
    while [[ ! -f .cursor/docs/evidence/20261003-pr15-full-record/formal-command-headless/run.json ]]; do sleep 1; done
    run_one command-render full_command_record_replay_test.gd render command-record-report.json || result=1
    for level in warehouse pump railcut depot radio; do
      export AMBUSH_CAMPAIGN_LEVEL="$level"
      run_one "campaign-$level-render" campaign_replay_test.gd render "full-campaign-$level-record-report.json" || result=1
    done
    unset AMBUSH_CAMPAIGN_LEVEL
    run_one credits-render radio_credits_viewport_test.gd render radio-credits-report.json || result=1
    run_one lifecycle-render presentation_lifecycle_test.gd render none || result=1
    run_one utility_runtime-render utility_runtime_test.gd render r5-utility-report.json || result=1
    run_one firearm_runtime-render firearm_runtime_test.gd render none || result=1
    run_one visual_snapshot-render visual_snapshot_test.gd render none || result=1
    run_one replay_fx_lifecycle-render replay_fx_lifecycle_test.gd render none || result=1
    exit "$result"
    ;;
  regressions)
    result=0
    for entry in presentation_contract replay_timeline camera_input presentation_lifecycle equipment_freeze utility_runtime command_pose_clock visual_snapshot replay_fx_lifecycle; do
      run_one "$entry-headless" "${entry}_test.gd" headless none || result=1
    done
    exit "$result"
    ;;
  *) exit 2 ;;
esac
