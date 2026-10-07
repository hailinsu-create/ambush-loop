from pathlib import Path
import subprocess,os,json,datetime,uuid,re,time,socket,hashlib,sys
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
STAGE=Path('/workspace/pr15-hud-subsegment-stage-1ec-20261005')
EXPORT=Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/hud-subsegment-qa-20261005')
GODOT='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,data):
 blob=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode()
 with (R/name).open('xb') as f:f.write(blob)
 return hashlib.sha256(blob).hexdigest()
for port in [12815,12816,12817]:
 s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
live=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(z in x.split()[1].lower() for z in ['godot','chromium'])]
assert not live,live
save('budget-start.json',{'utc':utc(),'monotonic':time.monotonic(),'cap_s':600,'scope':'native P0 selection + export + browser initialization/P0 + four serial OFF ON ON OFF runs + owned END; static preparation before start excluded'})
for kind in ['selection','export']:
 rid=uuid.uuid4().hex; run=R/'ambush_test_runs'/rid;data=run/'data';data.mkdir(parents=True)
 env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache'),'AMBUSH_TEST_RUN_ID':rid,'AMBUSH_TEST_DATA_ROOT':str(data)})
 if kind=='selection':
  env.update({'HUD_RECORD':'/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause/run/yard-record.bin','HUD_SELECTION_OUTPUT':str(R/'selected-window.json')})
  argv=[GODOT,'--headless','--audio-driver','Dummy','--path','/workspace/pr15-replay-save-stage-1ec-20261005','-s',str(R/'select_window.gd')]
 else:
  (data/'godot').mkdir();(data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
  assert not EXPORT.exists();EXPORT.mkdir()
  argv=[GODOT,'--headless','--audio-driver','Dummy','--path',str(STAGE),'--export-debug','Web Game',str(EXPORT/'index.html')]
 receipt={'kind':kind,'start':utc(),'argv':argv,'run_id':rid,'scope':'readonly original selection' if kind=='selection' else 'test-only timer Web export; cached official imports, no assets regenerated'}
 save(kind+'-request.json',receipt)
 with (R/(kind+'.log')).open('xb') as log:
  child=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT);receipt['pid']=child.pid
  try:child.wait(timeout=60);receipt['timed_out']=False
  except subprocess.TimeoutExpired:child.kill();child.wait();receipt['timed_out']=True
 text=(R/(kind+'.log')).read_text();receipt.update({'end':utc(),'actual_exit':child.returncode,'ERROR':len(re.findall('^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',text,re.M)),'guard_passed':'TEST_STORAGE_ISOLATED user_dir=' in text})
 if kind=='export':receipt['files']=[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(EXPORT.iterdir()) if p.is_file()]
 h=save(kind+'-receipt.json',receipt);save(kind+'-receipt-vault.json',receipt);save(kind+'-seal.json',{'sha256':h});print(json.dumps(receipt),flush=True)
 assert receipt['actual_exit']==receipt['ERROR']==receipt['SCRIPT_ERROR']==0
 if kind=='selection':assert receipt['guard_passed']
