from pathlib import Path
import shutil,subprocess,json,hashlib,datetime,os,re,ast
B=Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005')
S=Path('/workspace/pr15-fresh-native-sync-stage-dab-20261005')
O=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/fresh-native-sync-qa-20261005')
assert not S.exists() and not O.exists()
shutil.copytree('/workspace/pr15-fresh-native-resume-stage-dab-20261005',S)
O.mkdir(parents=True)
shutil.copy2(B/'readonly_campaign_bridge_sync.gd',S/'qa/readonly_campaign_bridge.gd')
source='dab870595175eed37a6d2a012bc69a76062d48b0'
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(S),'--export-debug','Web Game',str(O/'index.html')]
env=os.environ.copy();env.update({'XDG_DATA_HOME':'/tmp/pr15-web-controls/fresh-native-dab-20261005/isolated-data','XDG_CONFIG_HOME':str(B/'isolated-config'),'XDG_CACHE_HOME':str(B/'isolated-cache')})
meta={'source':source,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'argv':argv,'QA_only_fix':'synchronous readonly queries/input frame markers/event row read-only hit tests; no gameplay mutation','bridge_sha256':hashlib.sha256((B/'readonly_campaign_bridge_sync.gd').read_bytes()).hexdigest()}
print('RESUME_FIXTURE_EXPORT_START '+meta['start'],flush=True)
with (B/'sync-export.log').open('wb') as f:
 try:r=subprocess.run(argv,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=45);code=r.returncode
 except subprocess.TimeoutExpired:code=124
logs=(B/'sync-export.log').read_text(errors='replace');meta.update(actual_exit=code,ERROR=len(re.findall('^ERROR:',logs,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',logs,re.M)),end=datetime.datetime.now(datetime.timezone.utc).isoformat())
(B/'sync-export.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta),flush=True)
assert code==0 and meta['ERROR']==meta['SCRIPT_ERROR']==0
module=ast.parse(Path('/tmp/pr15-web-controls/fresh-native-dab-20261005/prepare_fixture.py').read_text())
fn=next(x for x in module.body if isinstance(x,ast.FunctionDef) and x.name=='entries');import struct
exec(compile(ast.Module(body=[fn],type_ignores=[]),'<pck reader>','exec'))
old=entries(Path('/workspace/pr15-web-artifacts')/source/'debug/index.pck');new=entries(O/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in set(old)&set(new) if old[k]!=new[k])
audit={'source':source,'all_payload_md5_verified':True,'original_entries':len(old),'fixture_entries':len(new),'added':added,'removed':removed,'changed':changed,'fixture_bytes':(O/'index.pck').stat().st_size,'fixture_sha256':hashlib.sha256((O/'index.pck').read_bytes()).hexdigest()}
(B/'sync-pck-payload-audit.json').write_text(json.dumps(audit,indent=2)+'\n');print(json.dumps(audit),flush=True)
assert added==['qa/readonly_campaign_bridge.gd.remap','qa/readonly_campaign_bridge.gdc'] and not removed and set(changed)=={'project.binary','.godot/uid_cache.bin'}
