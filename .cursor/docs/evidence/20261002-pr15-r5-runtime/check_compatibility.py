"""Read-only R4/R5 semantic gate; never invokes an asset generator.

The accepted producer's pure glTF readers are imported from --candidate. Old
files are read from a fixed git object into a temporary directory. All 51
current runtime GLBs must equal the immutable candidate; no blend/atlas edits.
"""
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('--repo', type=Path, required=True)
ap.add_argument('--candidate', type=Path, required=True)
ap.add_argument('--baseline', required=True)
ap.add_argument('--output', type=Path, required=True)
args = ap.parse_args()
repo = args.repo.resolve()
candidate = args.candidate.resolve()
sys.path.insert(0, str(candidate.parent))
from ambush_loop.ArtSource.v2.actor_acceptance.semantic_hash import compare
from ambush_loop.ArtSource.v2.actor_acceptance.check_utility_delivery import clip_keys
from ambush_loop.ArtSource.v2.actor_acceptance.validate import read

catalog = json.loads((candidate / 'ArtSource/v2/actor_acceptance/catalog_candidate.json').read_text())
report = {'baseline_sha': args.baseline,
          'candidate_source': '29749157c5db064bfea626c3ed9d75d9a1791ece',
          'candidate_delivery': 'ebedb829e3263abbeb6dd266905f24a3869fa281',
          'models': [], 'textures': [], 'old_clips_checked': 0, 'failures': [],
          'helper_sha256': {}}
for name in ['semantic_hash.py', 'check_utility_delivery.py', 'validate.py']:
    helper = candidate / 'ArtSource/v2/actor_acceptance' / name
    report['helper_sha256'][name] = hashlib.sha256(helper.read_bytes()).hexdigest()
with tempfile.TemporaryDirectory(prefix='pr15-r5-semantic-') as directory:
    for asset in catalog['assets']:
        for lod in asset['lods']:
            name = lod['path']
            old = Path(directory) / Path(name).name
            old.write_bytes(subprocess.check_output(
                ['git', 'show', f'{args.baseline}:ambush_loop/{name}'], cwd=repo))
            new = candidate / name
            row = compare(old, new)
            row['path'] = name
            row['current_runtime_equals_candidate'] = (repo / 'ambush_loop' / name).read_bytes() == new.read_bytes()
            od, ob = read(old)
            nd, nb = read(new)
            if od.get('skins'):
                oa = {a['name']: a for a in od['animations']}
                na = {a['name']: a for a in nd['animations']}
                same = all(n in na and clip_keys(od, ob, a) == clip_keys(nd, nb, na[n]) for n, a in oa.items())
                row.update(old_clip_count=len(oa), new_clip_count=len(na), all_old_keys_equal=same)
                report['old_clips_checked'] += len(oa)
                valid = same and len(oa) == 52 and len(na) == 64 and [d['component'] for d in row['differences']] == ['animations']
            else:
                valid = row['raw_equal']
            if not valid or not row['current_runtime_equals_candidate']:
                report['failures'].append(name)
            report['models'].append(row)
for texture in catalog['textures']:
    name = texture['path']
    baseline = subprocess.check_output(['git', 'show', f'{args.baseline}:ambush_loop/{name}'], cwd=repo)
    current = (repo / 'ambush_loop' / name).read_bytes()
    valid = baseline == current == (candidate / name).read_bytes()
    report['textures'].append({'path': name, 'raw_equal': valid, 'sha256': hashlib.sha256(current).hexdigest()})
    if not valid:
        report['failures'].append(name)
args.output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'models': len(report['models']), 'old_clips_checked': report['old_clips_checked'],
                  'textures': len(report['textures']), 'failures': report['failures']}))
assert not report['failures']
