from pathlib import Path
import os, subprocess, datetime, uuid, hashlib, json, re, struct, socket
ROOT=Path('/tmp/pr15-web-controls/site-update-1ec-20261005')
SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e'
STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005')
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'release'
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,value):
    data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with (ROOT/name).open('xb') as f: f.write(data)
    return hashlib.sha256(data).hexdigest()
for port in [12815,12816,12817]:
    s=socket.socket(); assert s.connect_ex(('127.0.0.1',port))!=0; s.close()
active=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])]
assert not active,active
assert not OUT.exists(); OUT.mkdir()
run=ROOT/'export-isolated'/uuid.uuid4().hex; data=run/'data'; (data/'godot').mkdir(parents=True)
(data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
env=os.environ.copy(); env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-release','Web Game',str(OUT/'index.html')]
receipt={'source':SOURCE,'start':now(),'argv':argv,'isolated_data':str(data),'scope':'official 4.7.2 cached QA export, pure production 1ec full Title release; QA loader/raw/settings excluded; no asset source generator/atlas/GLB/Blender rebuild'}
save('export-request.json',receipt)
with (ROOT/'export.log').open('xb') as f:
    child=subprocess.Popen(argv,env=env,stdout=f,stderr=subprocess.STDOUT); receipt['engine_pid']=child.pid
    try: child.wait(timeout=60); receipt['timed_out']=False
    except subprocess.TimeoutExpired: child.kill(); child.wait(); receipt['timed_out']=True
log=(ROOT/'export.log').read_text(); receipt.update({'actual_exit':child.returncode,'end':now(),'ERROR':len(re.findall('^ERROR:',log,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',log,re.M)),'files':[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.iterdir()) if p.is_file()]})
h=save('export-receipt.json',receipt); save('export-receipt-vault.json',receipt); save('export-receipt-seal.json',{'sha256':h,'scope':'original receipt duplicated immediately, exclusive creation'})
print(json.dumps(receipt),flush=True)
assert child.returncode==receipt['ERROR']==receipt['SCRIPT_ERROR']==0
