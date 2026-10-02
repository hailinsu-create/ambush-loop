#!/usr/bin/env bash
set -euo pipefail
# Read-only asset fixture; creates only its own unique data/capture directory.
engine="${1:?Godot 4.7.2 absolute path required}"
output="${2:?Absolute report output required}"
project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
catalog="${3:-$project/art/v2/actors_manifest.json}"
asset_root="${4:-$project}"
review_script="${5:-$project/ArtSource/v2/actor_acceptance/review.gd}"
profile_contract="${6:-$(dirname -- "$catalog")/firearm_profiles_candidate.json}"
run_id="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
mkdir -p "$output" "$project/build/actor-review/$run_id/data"
fixture="$project/build/actor-review/$run_id/fixture"
mkdir -p "$fixture"
python3 - "$project" "$fixture" "$catalog" "$asset_root" "$review_script" "$profile_contract" <<'PY'
import json,shutil,sys
from pathlib import Path
project,fixture,catalog,asset_root,review_script,profile_contract=map(Path,sys.argv[1:])
manifest=json.loads(catalog.read_text())
paths=[l['path'] for a in manifest['assets'] for l in a['lods']]+[t['path'] for t in manifest['textures']]
for name in paths:
    target=fixture/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(asset_root/name,target)
shutil.copy2(catalog,fixture/'art/v2/actors_manifest.json')
shutil.copy2(project/'ArtSource/v2/actor_acceptance/review.gd',fixture/'base_review.gd')
shutil.copy2(review_script,fixture/'review.gd')
if review_script.name=='firearm_review.gd':
    shutil.copy2(profile_contract,fixture/'firearm_profiles_candidate.json')
if review_script.name=='utility_review.gd':
    shutil.copy2(Path(catalog).parent/'utility_profiles_candidate.json',fixture/'utility_profiles_candidate.json')
if review_script.name=='quality_review.gd':
    yard=json.loads((project/'art/v2/manifest.json').read_text())
    context=[l['path'] for a in yard['assets'] for l in a['lods'] if a['asset_id'] in ['warehouse_fragment','ground_concrete','yard_lamp','oil_drum','sandbag_stack']]+[t['path'] for t in yard['textures']]
    for name in context:
        target=fixture/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(project/name,target)
(fixture/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Actor Asset Acceptance"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n')
PY
export XDG_DATA_HOME="$project/build/actor-review/$run_id/data"
export XDG_CONFIG_HOME="$project/build/actor-review/$run_id/config"
export XDG_CACHE_HOME="$project/build/actor-review/$run_id/cache"
export ACTOR_REVIEW_OUTPUT="$output"
export LIBGL_ALWAYS_SOFTWARE=1
export LP_NUM_THREADS="${LP_NUM_THREADS:-2}"
printf 'ACTOR_REVIEW_RUN_ID=%s\nSOURCE_SHA=%s\n' "$run_id" "$(git -C "$project" rev-parse HEAD)"
"$engine" --headless --editor --path "$fixture" --import > "$output/fixture-import.log" 2>&1
"$engine" --path "$fixture" --rendering-method gl_compatibility --audio-driver Dummy --script res://review.gd
