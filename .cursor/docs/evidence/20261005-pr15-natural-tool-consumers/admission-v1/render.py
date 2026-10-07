from pathlib import Path
import os,subprocess,uuid,json,datetime,time,re,signal
R=Path('/tmp/pr15-natural-tool-originals-20261005');G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
def live():return [line for line in subprocess.check_output(['ps','-eo','pid,stat,comm'],text=True).splitlines()[1:] if len(line.split())>=3 and not line.split()[1].startswith('Z') and any(t in line.split()[2].lower() for t in ['godot','chromium'])]
assert not live();start=time.monotonic();save('compat-render-start.json',{'utc':utc(),'monotonic':start,'cap_s':180,'scope':'new bounded old-mine neutral compatibility + real repack pose consumers; original positive mine gate remains unmet and original240 ended'})
receipts=[]
try:
 for label in ['warehouse-mine','railcut-repack']:
  rid=uuid.uuid4().hex;base=R/'ambush_test_runs'/rid;data=base/'data';data.mkdir(parents=True);out=R/label;out.mkdir()
  env=os.environ.copy();env.update(DISPLAY=':99',LIBGL_ALWAYS_SOFTWARE='1',XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(base/'config'),XDG_CACHE_HOME=str(base/'cache'),AMBUSH_TEST_RUN_ID=rid,AMBUSH_TEST_DATA_ROOT=str(data),TOOL_CASE=label,TOOL_OUTPUT=str(out))
  argv=[G,'--rendering-method','gl_compatibility','--fixed-fps','60','--audio-driver','Dummy','--path','/workspace/pr15-replay-save-stage-1ec-20261005','-s',str(R/'render.gd')]
  packet={'start':utc(),'argv':argv,'cap_s':75,'uuid':rid,'label':label};save(label+'-request.json',packet)
  with (R/(label+'.log')).open('xb') as log:
   p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);packet['pid']=p.pid
   try:p.wait(timeout=min(75,180-(time.monotonic()-start)));packet['timeout']=False
   except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait();packet['timeout']=True
  raw=(R/(label+'.log')).read_text();packet.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',raw,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',raw,re.M)),guard='TEST_STORAGE_ISOLATED user_dir=' in raw)
  save(label+'-receipt.json',packet);receipts.append(packet);print(json.dumps(packet),flush=True)
  if not (packet['actual_exit']==packet['ERROR']==packet['SCRIPT_ERROR']==0 and packet['guard'] and not packet['timeout']):break
finally:
 save('compat-render-end.json',{'utc':utc(),'wall_s':time.monotonic()-start,'cap_s':180,'live_engines':live(),'receipts':receipts});assert not live()
assert len(receipts)==2 and all(r['actual_exit']==r['ERROR']==r['SCRIPT_ERROR']==0 for r in receipts)
