from pathlib import Path
import json, shutil, hashlib, re, datetime
from PIL import Image

root = Path('/workspace/ambush-pr15')
base = Path('/tmp/pr15-hud-diagnostic')
out = root / '.cursor/docs/evidence/20261004-pr15-hud-diagnostic'
assert not out.exists(), 'Never overwrite sealed evidence'
sources = {}

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def copy(p, rel):
    p = Path(p)
    q = out / rel
    assert p.is_file() and not q.exists(), (p, q)
    q.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, q)
    assert sha(p) == sha(q)
    sources[str(q.relative_to(out))] = str(p)

closure = base / 'owned-display-closure.json'
c = json.loads(closure.read_text())
c['actual_display_wrapper_exit'] = 0
c['wrapper_completion_observed'] = '2026-10-04T23:01:28 UTC'
closure.write_text(json.dumps(c, indent=2) + '\n')

for p in sorted(base.rglob('*')):
    if not p.is_file() or '__pycache__' in p.parts:
        continue
    copy(p, 'controls/' + str(p.relative_to(base)))
for name in ['hud_profile_external.gd', 'hud_style_boundary_external.gd', 'hud_batch_pair_external.gd', 'hud_old_record_external.gd']:
    assert sha(root/'ambush_loop/scripts'/name) == sha(base/name)

inventory = json.loads((base/'output-inventory.json').read_text())
images = []
for run in inventory:
    src = Path(run['output'])
    for file in run['files']:
        p = Path(file['path'])
        rel = 'runs/' + run['label'] + '/original-output/' + str(p.relative_to(src))
        copy(p, rel)
        if p.suffix == '.png':
            im = Image.open(p).convert('RGBA')
            images.append({'label': run['label'], 'path': rel, 'viewed_original': True,
                           'width': im.width, 'height': im.height, 'png_sha256': sha(p),
                           'rgba_sha256': hashlib.sha256(im.tobytes()).hexdigest()})

for p in sorted(base.glob('*.json')):
    d = json.loads(p.read_text())
    if 'argv' not in d or not d.get('uuid') or 'actual_wrapper_exit' not in d:
        continue
    worktree = Path(d['argv'][1]).parents[2]
    run_root = worktree/'ambush_loop/build/ambush_test_runs'/d['uuid']
    log = run_root/'run.log'
    if log.exists():
        copy(log, 'runs/' + p.stem + '/guard-run.log')
    user_dir = run_root/'data/godot/app_userdata/Ambush Loop'
    bins = {
        'baseline-contract-dump': ['battle-0.bin', 'battle-1.bin', 'battle-2.bin'],
        'clock-entry-terminal-diag': ['clock-entry-terminal.bin'],
        'baseline-style-H-fixed': ['style-phase-values.bin'],
        'candidate-style-H': ['style-phase-values.bin'],
    }.get(p.stem, [])
    for name in bins:
        copy(user_dir/name, 'runs/' + p.stem + '/original-userdata/' + name)

for name in ['replay_event_focus.png', 'scout_backpack.png']:
    p = root/'ambush_loop/build/asset_review/pr15-runtime'/name
    rel = 'runs/candidate-lifecycle-R/original-output/' + name
    copy(p, rel)
    im = Image.open(p).convert('RGBA')
    images.append({'label': 'candidate-lifecycle-R', 'path': rel, 'viewed_original': True,
                   'width': im.width, 'height': im.height, 'png_sha256': sha(p),
                   'rgba_sha256': hashlib.sha256(im.tobytes()).hexdigest()})
assert len(images) == 34
static = [x for x in images if x['label'].startswith('batch-formal-') and x['path'].endswith('yard-static-confirmed-shot.png')]
assert len(static)==8 and len({x['rgba_sha256'] for x in static})==1
style_a = out/'runs/baseline-style-H-fixed/original-userdata/style-phase-values.bin'
style_b = out/'runs/candidate-style-H/original-userdata/style-phase-values.bin'
assert style_a.read_bytes() == style_b.read_bytes()
proof = {'format': 1, 'images': images, 'physical_original_png_count':len(images),
         'formal_static_all_eight_rgba_equal':True, 'formal_static_rgba_sha256':static[0]['rgba_sha256'],
         'phase_style_original_bins_equal':True, 'phase_style_bytes':style_a.stat().st_size,
         'phase_style_sha256':sha(style_a),
         'scope':'Original images viewed individually; no conversion of originals, no edits/montage. RGBA decoding for equality only. Advancing trajectories are bounded, not frame-paired or complete replay.'}
(out/'visual-equivalence.json').write_text(json.dumps(proof,indent=2)+'\n')
entries=[{'path':str(p.relative_to(out)), 'bytes':p.stat().st_size, 'sha256':sha(p),
          **({'copied_from':sources[str(p.relative_to(out))]} if str(p.relative_to(out)) in sources else {'generated_summary':True})}
         for p in sorted(out.rglob('*')) if p.is_file()]
manifest={'format':1,'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'baseline_sha':'f275178c0f60a7579685f9823894cafc3386f6da',
          'candidate_sha':'541d06440a97dd77f8c484a8de2a0ce364a8d91e',
          'manifest_excludes_itself':True,'files':entries,'file_count':len(entries),
          'total_bytes':sum(x['bytes'] for x in entries)}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'path':str(out),'files':len(entries),'bytes':manifest['total_bytes'],
                  'manifest_sha256':sha(out/'manifest.json'),'png_count':len(images),
                  'static_rgba_sha256':static[0]['rgba_sha256']}))
