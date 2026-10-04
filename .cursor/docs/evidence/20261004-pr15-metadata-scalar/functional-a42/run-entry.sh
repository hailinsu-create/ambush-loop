#!/usr/bin/env bash
set -u
metadata_entry="${1:?entry required}"
metadata_mode="${2:---headless}"
metadata_label="${3:?unique label required}"
metadata_root=/workspace/ambush-pr15
metadata_controls=/tmp/pr15-metadata-scalar
metadata_source="$(git -C "$metadata_root" rev-parse HEAD)"
metadata_tree="$(git -C "$metadata_root" rev-parse HEAD:ambush_loop)"
if [[ -e "$metadata_controls/$metadata_label.start" ]]; then
  printf 'Refuse to overwrite original run\n' >&2
  exit 2
fi
git -C "$metadata_root" diff --quiet HEAD -- ambush_loop || exit 2
export AMBUSH_TEST_SOURCE_SHA="$metadata_source"
printf '%s\n%s\n' "$metadata_source" "$metadata_tree" > "$metadata_controls/$metadata_label.source"
date -u +%FT%TZ > "$metadata_controls/$metadata_label.start"
cd "$metadata_root" || exit 2
bash ambush_loop/scripts/run_isolated_test.sh \
  "${AMBUSH_METADATA_ENGINE:-/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64}" \
  "$metadata_entry" "$metadata_mode" > "$metadata_controls/$metadata_label.log" 2>&1 &
metadata_pid=$!
printf '%s\n' "$metadata_pid" > "$metadata_controls/$metadata_label.pid"
wait "$metadata_pid"
metadata_exit=$?
printf '%s\n' "$metadata_exit" > "$metadata_controls/$metadata_label.exit"
date -u +%FT%TZ > "$metadata_controls/$metadata_label.end"
exit "$metadata_exit"
