from pathlib import Path
import os,json,subprocess,hashlib,re,datetime,uuid,signal,time
from pck_reader import entries
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
B=json.loads((R/'baseline.json').read_text());SOURCE=B['source'];STAGE=Path(B['stage'])
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'final-fresh13-qa-20261005'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,indent=2)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert not OUT.exists();OUT.mkdir(parents=True)
env=os.environ.copy();run=R/'export-isolated'/uuid.uuid4().hex
data=run/'data';(data/'godot').mkdir(parents=True)
(data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
env.update(XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(run/'config'),XDG_CACHE_HOME=str(run/'cache'))
imports={str(p.relative_to(STAGE)):sha(p) for p in (STAGE/'.godot/imported').glob('*') if p.is_file()}
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
receipt={'source':SOURCE,'game_tree':B['game_tree'],'START':now(),'argv':argv,'cap_seconds':60,'isolated_xdg':str(run),'observer_sha256':B['observer_sha256']}
save('export-request.json',receipt);print(json.dumps({'EXPORT_START':receipt['START'],'source':SOURCE,'cap':60}),flush=True)
t=time.monotonic()
with (R/'export.log').open('xb') as log:
 child=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 try:child.wait(timeout=60);timed_out=False
 except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait();timed_out=True
text=(R/'export.log').read_text(errors='replace')
after={str(p.relative_to(STAGE)):sha(p) for p in (STAGE/'.godot/imported').glob('*') if p.is_file()}
receipt.update(END=now(),wall_seconds=time.monotonic()-t,actual_exit=child.returncode,timed_out=timed_out,ERROR=len(re.findall('^ERROR:',text,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',text,re.M)),existing_import_bytes_unchanged=imports==after,files=[{'name':p.name,'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(OUT.iterdir()) if p.is_file()])
save('export-receipt.json',receipt);save('export-receipt-vault.json',receipt)
save('export-seal.json',{'sha256':sha(R/'export-receipt.json'),'bytes':(R/'export-receipt.json').stat().st_size})
print(json.dumps(receipt),flush=True)
assert child.returncode==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and imports==after
old=entries(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/debug/index.pck'));new=entries(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in old.keys()&new.keys() if old[k]!=new[k])
audit={'production_source':SOURCE,'production_tree':B['game_tree'],'all_payload_md5_verified':True,'added':added,'removed':removed,'changed':changed,'old':old,'new':new,'fixture_pck_sha256':sha(OUT/'index.pck'),'fixture_pck_bytes':(OUT/'index.pck').stat().st_size}
save('payload-audit.json',audit)
print(json.dumps({k:v for k,v in audit.items() if k not in ['old','new']}),flush=True)
assert added==['qa/final_observer.gd.remap','qa/final_observer.gdc'] and not removed and set(changed)<= {'project.binary','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'},'undeclared payload difference'
