from pathlib import Path
import hashlib, json, re, shutil, subprocess

root = Path('/workspace/ambush-pr15')
raw = Path('/tmp/pr15-blast-raw-envelope')
dest = root / '.cursor/docs/evidence/20261004-pr15-blast-raw-envelope'
dest.mkdir(parents=True, exist_ok=True)
source = 'aa8e0b650fabe75dd12ddbc23fa110e782bb83fd'
negative = '04c06758d7f09face58cef68d10b36a4be27c534'
runs = []
for label, revision, checks, failures, exit_code in [
    ('negative-04c-h', negative, 22, 6, 1),
    ('fixed-aa8-h', source, 22, 0, 0),
    ('tool_fx_pool_test-aa8-h', source, 255, 0, 0),
    ('visual_snapshot_test-aa8-h', source, 130, 0, 0),
    ('movement_dust_source_boundary_test-aa8-h', source, 35, 0, 0),
    ('tool_fx_pool_test-aa8-r', source, 268, 0, 0),
]:
    log = (raw / (label + '.log')).read_text()
    observed_exit = int((raw / (label + '.exit')).read_text())
    assert observed_exit == exit_code
    assert re.search(r'checks=%s failures=%s' % (checks, failures), log)
    errors = len(re.findall(r'^(?:ERROR:|SCRIPT ERROR:)', log, re.M))
    scripts = len(re.findall(r'^SCRIPT ERROR:', log, re.M))
    assert errors == scripts == 0
    run_id = re.search(r'^TEST_RUN_ID=(.+)$', log, re.M).group(1)
    run = {'label': label, 'source_sha': revision, 'checks': checks,
           'failures': failures, 'actual_exit': observed_exit, 'ERROR': errors,
           'SCRIPT_ERROR': scripts, 'run_id': run_id,
           'wrapper': 'ambush_loop/scripts/run_isolated_test.sh',
           'guard': 'TEST_STORAGE_ISOLATED' in log}
    assert run['guard']
    target = dest / label
    target.mkdir(exist_ok=True)
    for extension in ['log', 'exit']:
        shutil.copy2(raw / (label + '.' + extension), target / ('run.' + extension))
    match = re.search(r'output=res://([^\n]+)', log)
    if match:
        output = root / 'ambush_loop' / match.group(1)
        shutil.copytree(output, target / 'runtime', dirs_exist_ok=True)
    runs.append(run)

shutil.copytree(raw / 'window', dest / 'window', dirs_exist_ok=True)
assert (dest / 'window/Xorg-123.exit').read_text().strip() == '0'
paths = ['scripts/presentation/view_state.gd', 'scripts/tool_fx_raw_envelope_test.gd',
         'scripts/tool_fx_pool_test.gd', 'scripts/visual_snapshot_test.gd',
         'scripts/movement_dust_source_boundary_test.gd', 'scripts/run_isolated_test.sh',
         'scripts/run_isolated_test.ps1']
for label, revision in [('negative-04c', negative), ('fixed-aa8', source)]:
    target = dest / label / 'source'
    for path in paths:
        file = target / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(subprocess.check_output(['git', 'show', revision + ':ambush_loop/' + path], cwd=root))

pngs = list(sorted(dest.rglob('*.png')))
assert len(pngs) == 13
receipt = {'scope': 'All 13 original Window crops individually viewed via view_image; direct API/age fixtures, no normal13/art/performance acceptance. Manual transport HUD retains stale t0/banner in some frames; original first mine age0 crop has transient right control clipping, later stable crop restored.',
           'images': [{'path': str(p.relative_to(dest)), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in pngs]}
(dest / 'view-receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + '\n')
(dest / 'execution.json').write_text(json.dumps({'runs': runs, 'engine': '/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64',
    'engine_sha256': '8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e',
    'legacy_sha256': '1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12',
    'formal_A3_started': False, 'engine_actual_ended': True, 'Xorg_actual_exit': 0}, ensure_ascii=False, indent=2) + '\n')
shutil.copy2(__file__, dest / 'seal_evidence.py')
files = [{'path': str(p.relative_to(dest)), 'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dest.rglob('*')) if p.is_file() and p.name != 'manifest.json']
manifest = {'format': 1, 'source_sha': source, 'negative_sha': negative, 'files': files,
            'total_bytes': sum(p['bytes'] for p in files), 'png_count': len(pngs), 'scope': 'author bounded P2 probe/regressions; not independent QA/FINAL/A3/device'}
(dest / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
for item in files:
    assert hashlib.sha256((dest / item['path']).read_bytes()).hexdigest() == item['sha256']
print({'files': len(files), 'bytes': manifest['total_bytes'], 'pngs': len(pngs), 'runs': len(runs), 'hashes_verified': True})
