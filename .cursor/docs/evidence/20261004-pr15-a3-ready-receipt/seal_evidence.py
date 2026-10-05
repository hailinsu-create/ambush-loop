from pathlib import Path
import hashlib, json, re, shutil, subprocess

root=Path('/workspace/ambush-pr15')
base=Path('/tmp/pr15-a3-ready-receipt')
dest=root/'.cursor/docs/evidence/20261004-pr15-a3-ready-receipt'
dest.mkdir(parents=True,exist_ok=True)
source='8b37c31b0bc833c51862e4eb9ae01ca10bb3ffca'
log=(base/'contract-8b37-h.log').read_text()
assert int((base/'contract-8b37-h.exit').read_text())==0
assert re.search(r'checks=67 failures=0',log) and 'TEST_STORAGE_ISOLATED' in log
assert not re.search(r'^(?:ERROR:|SCRIPT ERROR:)',log,re.M)
run_id=re.search(r'^TEST_RUN_ID=(.+)$',log,re.M).group(1)
runtime=root/'ambush_loop/build/asset_review/pr15-runtime'/('a3-collector-contract-'+run_id)
shutil.copytree(runtime,dest/'runtime',dirs_exist_ok=True)
for name in ['contract-8b37-h.log','contract-8b37-h.exit','provenance-source.json','raw-inspection.json','production-blobs-unchanged.json','readonly-8b37.md']:
    shutil.copy2(base/name,dest/name)
for path in ['scripts/a3_render_metrics.gd','scripts/a3_collector_contract_test.gd','scripts/a3_provenance.gd','scripts/prepare_a3_provenance.py','scripts/a3_collector_probe_test.gd','scripts/run_isolated_test.sh','scripts/run_isolated_test.ps1']:
    target=dest/'source'/path
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(subprocess.check_output(['git','show',source+':ambush_loop/'+path],cwd=root))
shutil.copy2(__file__,dest/'seal_evidence.py')
files=[{'path':str(p.relative_to(dest)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dest.rglob('*')) if p.is_file() and p.name!='manifest.json']
manifest={'source_sha':source,'game_tree':'a4990e991d1b3b635d76c454ab3e16d319ffa43d','files':files,'total_bytes':sum(f['bytes'] for f in files),'scope':'headless67/0 manual callbacks/intentional invalid chunks; no new Window/performance/FINAL/device evidence','actual_exit':0,'ERROR':0,'SCRIPT_ERROR':0,'run_id':run_id}
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
for f in files:assert hashlib.sha256((dest/f['path']).read_bytes()).hexdigest()==f['sha256']
assert not list(dest.rglob('*.png'))
print({'files':len(files),'bytes':manifest['total_bytes'],'all_hashes_verified':True,'actual_H_exit':0,'Window_started':False,'formal_A3_started':False})
