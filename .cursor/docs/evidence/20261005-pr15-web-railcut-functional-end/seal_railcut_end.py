from pathlib import Path
import json, hashlib, datetime, subprocess, shutil, socket
ROOT = Path('/workspace/ambush-pr15')
BASE = Path('/tmp/pr15-web-controls/railcut-native-8532-20261005')
OLD = ROOT/'.cursor/docs/evidence/20261005-pr15-web-railcut-producer'
DEST = ROOT/'.cursor/docs/evidence/20261005-pr15-web-railcut-functional-end'
assert not DEST.exists()
old = json.loads((OLD/'manifest.json').read_text())
for f in old['files']:
    b = (OLD/f['path']).read_bytes()
    assert len(b) == f['bytes'] and hashlib.sha256(b).hexdigest() == f['sha256'], f['path']
proof = json.loads((BASE/'run-v2/railcut-browser-final-proof.json').read_text())
end = json.loads((BASE/'browser-end-tool-receipt.json').read_text())
assert proof['status'] == 'PASS' and end['exit_code'] == 0
assert 'RAILCUT_ENGINE_END' in end['output'] and 'Traceback' not in end['output']
audit = json.loads((BASE/'railcut-offline-audit-receipt.json').read_text())
result = json.loads((BASE/'railcut-offline-audit-result.json').read_text())
assert audit['actual_exit'] == audit['ERROR'] == audit['SCRIPT_ERROR'] == 0 and audit['test_storage_guard_passed'] and not result['failures']
preflight = json.loads((BASE/'preflight.json').read_text())
for pin in preflight['pins']:
    b = (ROOT/pin['path']).read_bytes()
    assert len(b) == pin['bytes'] and hashlib.sha256(b).hexdigest() == pin['sha256']
    assert subprocess.check_output(['git','hash-object',pin['path']], cwd=ROOT, text=True).strip() == pin['git_blob']
assert subprocess.check_output(['git','rev-parse','HEAD:ambush_loop'],cwd=ROOT,text=True).strip() == preflight['game_tree']
raw = (BASE/'run-v2/railcut-record.bin').read_bytes()
assert len(raw) == old['original_record']['bytes'] and hashlib.sha256(raw).hexdigest() == old['original_record']['sha256']
closed = {}
for port in [12815,12816]:
    s = socket.socket(); closed[str(port)] = s.connect_ex(('127.0.0.1',port)) != 0; s.close()
assert all(closed.values())
processes = subprocess.check_output(['ps','-eo','stat,comm,args'],text=True).splitlines()[1:]
live = [r for r in processes if not r.split()[0].startswith('Z') and (r.split()[1] in ['chromium','chrome','chrome_crashpad','Godot_v4.7.2-st','godot'] or ('python3' == r.split()[1] and 'browser_controller' in r))]
assert not live, live
profile = Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005')
assert not (profile/'SingletonLock').exists() and not (profile/'SingletonLock').is_symlink()
whole = []
for rate in [1,2]:
    packet = json.loads((BASE/f'run-v2/railcut-whole-{rate}x.json').read_text())
    receipt = json.loads((BASE/f'run-v2/railcut-whole-natural-{rate}x.json').read_text())
    rows = packet['observer_rows']
    assert receipt['actual_exit'] == 0 and packet['status'] == 'PASS' and not packet['frame_checks']['failures']
    assert packet['record_sha256'] == old['original_record']['sha256']
    assert rows[0]['tick'] == 0 and rows[-1]['tick'] == 7610 and not rows[-1]['playing']
    assert all(r['tick'] == r['view_tick'] and r['rate'] == rate and r['attempt'] == old['original_record']['attempt'] for r in rows)
    assert all(a['tick'] <= b['tick'] for a,b in zip(rows,rows[1:]))
    assert packet['input_to_terminal_callback_wall'] < packet['deadline_wall']
    whole.append({k:v for k,v in packet.items() if k not in ['observer_rows','actual_input_rows'] } | {'observer_row_count':len(rows), 'actual_request_exit':receipt['actual_exit'], 'request_start':receipt['start'], 'request_end':receipt['end']})
post = {'actual_exit':0,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':preflight['source'],'game_tree':preflight['game_tree'],'pins':preflight['pins'],'original_record_bytes':len(raw),'original_record_sha256':hashlib.sha256(raw).hexdigest(),'checkpoint_manifest_files_reverified':len(old['files']),'ports_closed':closed,'live_engines':live,'original_profile_lock_absent':True,'whole':whole,'browser_end':end,'scope':'post-END exact source, original raw artifact, two natural whole streams, closed engine/window/server; no device or performance acceptance'}
(BASE/'post-end-verification.json').write_text(json.dumps(post,ensure_ascii=False,indent=2)+'\n')
DEST.mkdir()
existing = {f['path'] for f in old['files']}
chosen = [p for p in (BASE/'run-v2').iterdir() if p.is_file() and str(p.relative_to(BASE)) not in existing]
chosen += [BASE/n for n in ['whole_railcut_1x.py','whole_railcut_2x.py','railcut_boundary.py','finish_railcut.py','railcut_record_readonly_audit.gd','run_railcut_offline_audit.py','railcut-offline-audit.log','railcut-offline-audit-receipt.json','railcut-offline-audit-result.json','browser-end-tool-receipt.json','post-end-verification.json','seal_railcut_end.py']]
chosen += [p for p in (BASE/'negative-final-proof-global-label').iterdir() if p.is_file()]
files = []
for p in sorted(set(chosen)):
    rel = str(p.relative_to(BASE)); target = DEST/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(p,target)
    b = target.read_bytes(); files.append({'path':rel,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
manifest = {'source':preflight['source'],'game_tree':preflight['game_tree'],'producer_checkpoint_sha':'7c661957276ca7445f7e2cf66896dccda3c53155','sealed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PASS_BOUNDED_RAILCUT_FUNCTIONAL_END','prior_evidence_manifest':'../20261005-pr15-web-railcut-producer/manifest.json','prior_file_count':len(old['files']),'prior_total_bytes':old['total_bytes'],'original_record':old['original_record'],'whole':whole,'browser_final_proof':proof,'offline_artifact_result':result,'file_count':len(files),'total_bytes':sum(f['bytes'] for f in files),'files':files,'scope':'final immutable whole/progress/lifecycle controls and all previously-live driver/HTTP logs after END; original producer/bin/7PNG referenced unchanged from sealed checkpoint; no assets, Site deploy, full campaign, performance, APK, or device acceptance'}
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
for f in files:
    b=(DEST/f['path']).read_bytes();assert len(b)==f['bytes'] and hashlib.sha256(b).hexdigest()==f['sha256']
print(json.dumps({k:v for k,v in manifest.items() if k not in ['files','original_record','whole','browser_final_proof','offline_artifact_result']},ensure_ascii=False))
