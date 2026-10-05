from pathlib import Path
import os,json,subprocess,uuid,datetime,time,re,signal
R=Path('/tmp/pr15-replay-first-draw-20261005')
G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
live=[line for line in subprocess.check_output(['ps','-eo','pid,stat,comm'],text=True).splitlines()[1:] if len(line.split())>=3 and not line.split()[1].startswith('Z') and any(t in line.split()[2].lower() for t in ['godot','chromium'])]
assert not live,live
start=time.monotonic();save('window-start.json',{'utc':utc(),'cap_s':240,'parent_return':'QA END19:36:27 explicit sole window return','workload':'pure A/B native first draw via engine GUI input; no performance profiling'})
receipts=[]
try:
 for side,stage in [('A','/workspace/pr15-replay-save-stage-1ec-20261005'),('B','/workspace/pr15-replay-touch-candidate-95daa-20261005')]:
  rid=uuid.uuid4().hex;base=R/'ambush_test_runs'/rid;data=base/'data';data.mkdir(parents=True)
  out=R/side;out.mkdir()
  env=os.environ.copy();env.update(DISPLAY=':99',LIBGL_ALWAYS_SOFTWARE='1',XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(base/'config'),XDG_CACHE_HOME=str(base/'cache'),AMBUSH_TEST_RUN_ID=rid,AMBUSH_TEST_DATA_ROOT=str(data),FIRST_DRAW_OUTPUT=str(out))
  argv=[G,'--rendering-method','gl_compatibility','--fixed-fps','60','--audio-driver','Dummy','--path',stage,'-s',str(R/'first_draw.gd')]
  rec={'side':side,'start':utc(),'argv':argv,'cap_s':90,'uuid':rid,'synthetic_engine_GUI_input':True};save(side+'-request.json',rec)
  with (R/(side+'.log')).open('xb') as log:
   p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);rec['pid']=p.pid
   try:p.wait(timeout=min(90,240-(time.monotonic()-start)));rec['timeout']=False
   except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait();rec['timeout']=True
  raw=(R/(side+'.log')).read_text();rec.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',raw,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',raw,re.M)),guard='TEST_STORAGE_ISOLATED user_dir=' in raw,summary=[s for s in raw.splitlines() if 'FIRST_DRAW checks=' in s])
  save(side+'-receipt.json',rec);receipts.append(rec);print(json.dumps(rec),flush=True)
  if not (rec['actual_exit']==rec['ERROR']==rec['SCRIPT_ERROR']==0 and rec['guard'] and not rec['timeout']):break
finally:
 live=[line for line in subprocess.check_output(['ps','-eo','pid,stat,comm'],text=True).splitlines()[1:] if len(line.split())>=3 and not line.split()[1].startswith('Z') and any(t in line.split()[2].lower() for t in ['godot','chromium'])]
 save('window-end.json',{'utc':utc(),'wall_s':time.monotonic()-start,'live_engines':live,'receipts':receipts})
 assert not live,live
assert len(receipts)==2 and all(r['actual_exit']==r['ERROR']==r['SCRIPT_ERROR']==0 for r in receipts)
print('NATIVE_FIRST_DRAW_WINDOW_END actual0 live0',flush=True)
