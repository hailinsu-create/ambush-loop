#!/usr/bin/env bash
set -euo pipefail
# Read-only asset fixture; creates only its own unique data/capture directory.
engine="${1:?Godot 4.7.2 absolute path required}"
output="${2:?Absolute report output required}"
project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
catalog="${3:-$project/art/v2/actors_manifest.json}"
asset_root="${4:-$project}"
run_id="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
mkdir -p "$output" "$project/build/actor-review/$run_id/data"
fixture="$project/build/actor-review/$run_id/fixture"
mkdir -p "$fixture"
python3 - "$project" "$fixture" "$catalog" "$asset_root" <<'PY'
import json,shutil,sys
from pathlib import Path
project,fixture,catalog,asset_root=map(Path,sys.argv[1:])
manifest=json.loads(catalog.read_text())
paths=[l['path'] for a in manifest['assets'] for l in a['lods']]+[t['path'] for t in manifest['textures']]
for name in paths:
    target=fixture/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(asset_root/name,target)
shutil.copy2(catalog,fixture/'art/v2/actors_manifest.json')
shutil.copy2(project/'ArtSource/v2/actor_acceptance/review.gd',fixture/'review.gd')
(fixture/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Actor Asset Acceptance"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n')
PY
export XDG_DATA_HOME="$project/build/actor-review/$run_id/data"
export XDG_CONFIG_HOME="$project/build/actor-review/$run_id/config"
export XDG_CACHE_HOME="$project/build/actor-review/$run_id/cache"
export ACTOR_REVIEW_OUTPUT="$output"
export LIBGL_ALWAYS_SOFTWARE=1
printf 'ACTOR_REVIEW_RUN_ID=%s\nSOURCE_SHA=%s\n' "$run_id" "$(git -C "$project" rev-parse HEAD)"
"$engine" --headless --editor --path "$fixture" --import > "$output/fixture-import.log" 2>&1
"$engine" --path "$fixture" --rendering-method gl_compatibility --audio-driver Dummy --script res://review.gd
