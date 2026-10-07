from pathlib import Path
import os,subprocess,uuid,json,datetime,time,re,signal
R=Path('/tmp/pr15-natural-tool-originals-20261005');G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
start=time.monotonic();save('budget-start.json',{'utc':utc(),'monotonic':start,'cap_s':240,'scope':'original record metadata<=45 then serial two renderer consumers<=90 each; no producer/performance/assets'})
rid=uuid.uuid4().hex;base=R/'ambush_test_runs'/rid;data=base/'data';data.mkdir(parents=True)
env=os.environ.copy();env.update(XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(base/'config'),XDG_CACHE_HOME=str(base/'cache'),AMBUSH_TEST_RUN_ID=rid,AMBUSH_TEST_DATA_ROOT=str(data))
argv=[G,'--headless','--audio-driver','Dummy','--path','/workspace/pr15-replay-save-stage-1ec-20261005','-s',str(R/'inspect.gd')]
packet={'start':utc(),'argv':argv,'cap_s':45,'uuid':rid};save('admission-request.json',packet)
with (R/'admission.log').open('xb') as log:
 p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);packet['pid']=p.pid
 try:p.wait(timeout=45);packet['timeout']=False
 except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait();packet['timeout']=True
raw=(R/'admission.log').read_text();packet.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',raw,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',raw,re.M)),guard='TEST_STORAGE_ISOLATED user_dir=' in raw)
save('admission-receipt.json',packet);print(json.dumps(packet),flush=True)
assert packet['actual_exit']==packet['ERROR']==packet['SCRIPT_ERROR']==0 and packet['guard'] and not packet['timeout']
