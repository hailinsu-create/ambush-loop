from pathlib import Path
import json, re, hashlib, shutil, subprocess
from PIL import Image

root = Path('/workspace/ambush-pr15')
base = root / '.cursor/docs/evidence/20261003-pr15-full-record'
source = '15c0783059bb7c2f9e9cd9b7252a9343e71f4168'
production = 'd860056f2107836c08dfb375a034ebbe694baff6'
levels = ['yard', 'warehouse', 'pump', 'railcut', 'depot', 'radio']
expected = ['command-headless', 'command-render', 'credits-render', 'lifecycle-render']
expected += [f'campaign-{level}-{mode}' for level in levels for mode in ['headless', 'render']]
expected += [f'{entry}-headless' for entry in ['presentation_contract', 'replay_timeline', 'camera_input', 'presentation_lifecycle', 'equipment_freeze', 'utility_runtime', 'command_pose_clock', 'visual_snapshot', 'replay_fx_lifecycle']]
expected += [f'{entry}-render' for entry in ['utility_runtime', 'firearm_runtime', 'visual_snapshot', 'replay_fx_lifecycle']]

extras = {
    'lifecycle-render': [('pr15-runtime', n) for n in ['replay_event_focus.png', 'scout_backpack.png']],
    'firearm_runtime-render': [('pr15-runtime', f'r4_runtime_{n}.png') for n in ['actual_mg', 'actual_fallback', 'actual_history_mg']],
    'visual_snapshot-render': [('pr15-runtime', f'history_hud_{n}.png') for n in ['desktop', 'phone']],
    'replay_fx_lifecycle-render': [('pr15-environment-battle', f'{level}_history_fx_clear.png') for level in levels],
}
assert len(expected) == 29
assert {p.name.removeprefix('formal-') for p in base.glob('formal-*')} == set(expected)
rows = []
for name in expected:
    directory = base / ('formal-' + name)
    path = directory / 'run.json'
    data = json.loads(path.read_text())
    assert data['actual_source_sha'] == source
    assert (data['actual_exit_code'], data['failures'], data['engine_error_lines']) == (0, 0, 0), name
    if name in extras:
        data['captures'] = []
        for category, filename in extras[name]:
            artifact = root / 'ambush_loop/build/asset_review' / category / filename
            retained = directory / filename
            shutil.copyfile(artifact, retained)
            data['captures'].append({'retained_path': str(retained.relative_to(root)), 'sha256': hashlib.sha256(retained.read_bytes()).hexdigest(), 'image_size': list(Image.open(retained).size), 'source': 'root framebuffer', 'hash_verified': True})
        data['captured_frames'] = len(data['captures'])
    if name.endswith('-render'):
        data['environment'].update({'DISPLAY': ':112', 'AMBUSH_TEST_X11_DISPLAY': ':112', 'LIBGL_ALWAYS_SOFTWARE': '1'})
    data['log_path'] = str((directory / 'run.log').relative_to(root))
    data['exit_path'] = str((directory / 'run.exit').relative_to(root))
    for capture in data['captures']:
        artifact = root / capture['retained_path']
        assert hashlib.sha256(artifact.read_bytes()).hexdigest() == capture['sha256'], str(artifact)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    rows.append(data)
assert len({row['run_id'] for row in rows}) == 29

goldens = {'yard': (2, 1283, 34), 'warehouse': (2, 1191, 67), 'pump': (2, 907, 34), 'railcut': (2, 719, 38), 'depot': (2, 957, 35), 'radio': (3, 1413, 51)}
campaign = []
for level in levels:
    modes = []
    for mode in ['headless', 'render']:
        report = json.loads((base / f'formal-campaign-{level}-{mode}/report.json').read_text())
        assert len(report['runs']) == 3
        for run in report['runs']:
            assert (len(run['waves']), run['battle_terminal_tick'], run['events']) == goldens[level]
            assert run['schema'] == 2
        assert len({run['fingerprint'] for run in report['runs']}) == 1
        assert len({tuple(run['waves']) for run in report['runs']}) == 1
        assert len({run['playback_terminal_tick'] for run in report['runs']}) == 1
        if mode == 'render':
            for capture in report['captures']:
                assert capture['attempt_id'] == report['runs'][0]['attempt_id']
                assert '波 %d/%d' % (capture['wave_id'] + 1, goldens[level][0]) in capture['header']
        modes.append(report['runs'][0])
    assert modes[0]['fingerprint'] == modes[1]['fingerprint']
    campaign.append({'level': level, 'waves': modes[0]['waves'], 'battle_terminal_tick': modes[0]['battle_terminal_tick'], 'events': modes[0]['events'], 'playback_terminal_tick': modes[0]['playback_terminal_tick'], 'fingerprint': modes[0]['fingerprint'], 'reference_variants_per_mode': 3})

legacy = base / 'actual-schema1-874d350/command-record-source-v1.bin'
legacy_hash = hashlib.sha256(legacy.read_bytes()).hexdigest()
assert legacy_hash == '1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12'
for mode in ['headless', 'render']:
    report = json.loads((base / f'formal-command-{mode}/report.json').read_text())
    legacy_row = next(row for row in report['rows'] if row.get('stage') == 'actual_legacy_schema1')
    assert legacy_row['source_binary_sha256'] == legacy_hash
    for terminal, golden in [('won', (1283, 34)), ('escape', (928, 19)), ('abort', (0, 3))]:
        row = next(row for row in report['rows'] if row.get('terminal') == terminal)
        assert (row['battle_terminal_tick'], row['events']) == golden

production_files = ['ambush_loop/scripts/main.gd', 'ambush_loop/scripts/replay/battle_log.gd', 'ambush_loop/scripts/replay/replay_player.gd', 'ambush_loop/scripts/presentation/view_state.gd', 'ambush_loop/scripts/presentation/presenter_3d.gd']
blobs = []
for filename in production_files:
    old = subprocess.check_output(['git', 'show', f'{production}:{filename}'], cwd=root)
    assert old == (root / filename).read_bytes()
    blobs.append({'path': filename, 'sha256': hashlib.sha256(old).hexdigest()})
changed_game = subprocess.check_output(['git', 'diff', '--name-only', production, source, '--', 'ambush_loop'], cwd=root, text=True).splitlines()
assert all(name.endswith('_test.gd') for name in changed_game), changed_game
asset_changes = subprocess.check_output(['git', 'diff', '--name-only', '67f521b5b7f3c8663c3cd2630bd0310a6bedb2a5', source, '--', 'ArtSource', 'ambush_loop/art', 'ambush_loop/assets', 'ambush_loop/audio'], cwd=root, text=True).splitlines()
assert not asset_changes

receipt = {'actual_source_sha': source, 'runtime_source_sha': production, 'formal_runs': len(rows), 'all_actual_exit_codes_zero': True, 'all_engine_errors_zero': True, 'captured_frames': sum(row['captured_frames'] for row in rows), 'runtime_blobs': blobs, 'test_only_changes_since_runtime_source': changed_game, 'asset_paths_changed_since_67f': asset_changes, 'actual_legacy_schema1_source_sha': '874d3501fdd2b34b0966472e22a9e43a28a1b3dd', 'actual_legacy_schema1_binary_sha256': legacy_hash, 'campaign': campaign, 'runs': rows, 'limits': ['0.1s actual command samples plus real unsampled boundaries; not continuous video or exact root interpolation between samples', 'Reference deployments and vacuum; not normal complete six-level player journey', 'Controlled ALERT 30/60 timing and 2x/camera invariance are not measured device FPS', 'Native XTest mouse/keyboard and synthetic touch cancellation are not physical mobile touch', 'Full 3D FX/A3 budget, ears0/45 and0/6, title200 menu P2, original two focus crops, final smoke/QA/APK remain', 'No merge/production/height/G integration; no device/emulator testing']}
(base / 'validation.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + '\n')
helpers = base / 'control-helpers'
helpers.mkdir(exist_ok=True)
for source_path, filename in [('/tmp/pr15_full_candidate15.sh', 'run-candidate.sh'), ('/tmp/pr15-full-godot', 'godot-render.sh'), ('/tmp/pr15_archive_full.py', 'archive.py'), ('/tmp/pr15-full-xorg.conf', 'xorg.conf')]:
    shutil.copyfile(source_path, helpers / filename)
print(json.dumps({'source': source, 'formal_runs': len(rows), 'captures': receipt['captured_frames'], 'campaign': [{k:v for k,v in row.items() if k != 'fingerprint'} for row in campaign]}, ensure_ascii=False))
