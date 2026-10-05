from pathlib import Path
import subprocess,uuid,os,json,datetime,hashlib,re,time
R=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005')
A=Path('/workspace/pr15-replay-save-stage-1ec-20261005');B=Path('/workspace/pr15-replay-touch-candidate-95daa-20261005')
G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
def run(label,argv,env):
 label='v4-'+label
 receipt={'label':label,'start':utc(),'argv':argv,'cap_s':60,'engine':'4.7.2 official ed1daf0bf'};save(label+'-request.json',receipt)
 with (R/(label+'.log')).open('xb') as log:
  p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT);receipt['pid']=p.pid
  try:p.wait(timeout=60);receipt['timeout']=False
  except subprocess.TimeoutExpired:p.kill();p.wait();receipt['timeout']=True
 text=(R/(label+'.log')).read_text();receipt.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',text,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',text,re.M)),guard='TEST_STORAGE_ISOLATED user_dir=' in text,summary=[s for s in text.splitlines() if 'checks=' in s or 'TEST_RUN_ID=' in s or 'failures=' in s]);save(label+'-receipt.json',receipt);print(json.dumps(receipt),flush=True)
 assert receipt['actual_exit']==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and not receipt['timeout'] and receipt['guard']
for label,stage,entry in [('A-final-ui',A,R/'hud_final_oracle.gd'),('B-final-ui',B,R/'hud_final_oracle.gd'),('B-real-old',B,Path('/tmp/pr15-hud-diagnostic/hud_old_record_external.gd'))]:
 rid=uuid.uuid4().hex;runroot=R/'ambush_test_runs'/rid;data=runroot/'data';data.mkdir(parents=True)
 env=os.environ.copy();env.update(XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(runroot/'config'),XDG_CACHE_HOME=str(runroot/'cache'),AMBUSH_TEST_RUN_ID=rid,AMBUSH_TEST_DATA_ROOT=str(data),HUD_ORACLE_OUTPUT=str(R/('v4-'+label+'.json')))
 run(label,[G,'--headless','--audio-driver','Dummy','--path',str(stage),'-s',str(entry)],env)
a=json.loads((R/'v4-A-final-ui.json').read_text());b=json.loads((R/'v4-B-final-ui.json').read_text());assert a==b,'observable final UI/frame/20-bone/socket difference'
save('native-ui-pair.json',{'equal':True,'cases':len(a['rows']),'checks_each':a['checks'],'failures_each':a['failures'],'A_sha256':hashlib.sha256((R/'v4-A-final-ui.json').read_bytes()).hexdigest(),'B_sha256':hashlib.sha256((R/'v4-B-final-ui.json').read_bytes()).hexdigest(),'scope':a['scope']})
for entry,mode in [('presentation_contract_test.gd','--headless'),('equipment_freeze_test.gd','--headless'),('replay_event_text_source_test.gd','--headless'),('command_pose_clock_test.gd','--headless'),('presentation_lifecycle_test.gd','--render')]:
 env=os.environ.copy();env.update(DISPLAY=':99',LIBGL_ALWAYS_SOFTWARE='1')
 run('B-'+entry.removesuffix('.gd'),['bash',str(B/'scripts/run_isolated_test.sh'),'/tmp/pr15-hud-diagnostic/godot-dummy',entry,mode],env)
print('NATIVE_REQUIRED_END actual0 all Guard/E0/S0',flush=True)
