#!/usr/bin/env bash
set -u
pair_variant="${1:?A or B required}"
pair_label="${2:?unique label required}"
pair_controls=/tmp/pr15-metadata-scalar
case "$pair_variant" in
  A) pair_root=/workspace/pr15-metadata-baseline-41ff; pair_proof="$pair_controls/baseline-41ff-proof.json" ;;
  B) pair_root=/workspace/pr15-metadata-candidate-a42; pair_proof="$pair_controls/candidate-a42-proof.json" ;;
  *) exit 2 ;;
esac
[[ ! -e "$pair_controls/$pair_label.start" ]] || { printf 'Refuse to overwrite originals\n' >&2; exit 2; }
git -C "$pair_root" diff --quiet HEAD -- ambush_loop || exit 2
export DISPLAY=:126
export LIBGL_ALWAYS_SOFTWARE=1
export AMBUSH_TEST_SOURCE_SHA="$(git -C "$pair_root" rev-parse HEAD)"
export AMBUSH_A3_GAME_TREE="$(git -C "$pair_root" rev-parse HEAD:ambush_loop)"
export AMBUSH_A3_PROVENANCE_FILE="$pair_proof"
export AMBUSH_PAIR_FIXTURE_SHA="$(sha256sum "$pair_controls/metadata_pair_external.gd" | cut -d ' ' -f 1)"
printf '%s\n%s\n%s\n%s\n' "$pair_variant" "$AMBUSH_TEST_SOURCE_SHA" "$AMBUSH_A3_GAME_TREE" "$AMBUSH_PAIR_FIXTURE_SHA" > "$pair_controls/$pair_label.source"
date -u +%FT%TZ > "$pair_controls/$pair_label.start"
cd "$pair_root" || exit 2
bash ambush_loop/scripts/run_isolated_test.sh "$pair_controls/godot-metadata-pair" \
  a3_campaign_metrics_test.gd --render > "$pair_controls/$pair_label.log" 2>&1 &
pair_pid=$!
printf '%s\n' "$pair_pid" > "$pair_controls/$pair_label.pid"
wait "$pair_pid"
pair_exit=$?
printf '%s\n' "$pair_exit" > "$pair_controls/$pair_label.exit"
date -u +%FT%TZ > "$pair_controls/$pair_label.end"
exit "$pair_exit"
