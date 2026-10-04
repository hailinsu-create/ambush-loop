#!/usr/bin/env bash
set -u
pair_controls=/tmp/pr15-metadata-scalar
[[ ! -e "$pair_controls/formal.start" ]] || exit 2
sha256sum "$pair_controls/metadata_pair_external.gd" "$pair_controls/analyze_metadata_pair.py" "$pair_controls/run-pair-entry.sh" "$pair_controls/godot-metadata-pair" > "$pair_controls/formal.controls.sha256"
date -u +%FT%TZ > "$pair_controls/formal.start"
pair_index=0
for pair_variant in A B B A B A A B; do
 pair_index=$((pair_index + 1))
 pair_label="formal-0${pair_index}-${pair_variant}-common4"
 printf '%s %s\n' "$pair_variant" "$pair_label" >> "$pair_controls/formal.order"
 bash "$pair_controls/run-pair-entry.sh" "$pair_variant" "$pair_label"
 pair_exit=$?
 if [[ "$pair_exit" -ne 0 ]]; then
  printf '%s\n' "$pair_exit" > "$pair_controls/formal.exit"
  date -u +%FT%TZ > "$pair_controls/formal.end"
  exit "$pair_exit"
 fi
 python3 "$pair_controls/analyze_metadata_pair.py" --run "$pair_variant:$pair_label" --output "$pair_controls/$pair_label-strict.json" > "$pair_controls/$pair_label-strict.log" 2>&1
 pair_strict=$?
 printf '%s\n' "$pair_strict" > "$pair_controls/$pair_label-strict.exit"
 if [[ "$pair_strict" -ne 0 ]]; then
  printf '%s\n' "$pair_strict" > "$pair_controls/formal.exit"
  date -u +%FT%TZ > "$pair_controls/formal.end"
  exit "$pair_strict"
 fi
done
printf '0\n' > "$pair_controls/formal.exit"
date -u +%FT%TZ > "$pair_controls/formal.end"
exit 0
