from pathlib import Path
import os,subprocess,json,hashlib,datetime,re,signal
R=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005');B=Path('/workspace/pr15-replay-touch-candidate-95daa-20261005');G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def run(label,entry,mode,part=None):
 env=os.environ.copy();env.update(DISPLAY=':99',LIBGL_ALWAYS_SOFTWARE='1',AMBUSH_LEGACY_RECORD_FIXTURE='/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin')
 if part:env['PR15_EQUIPMENT_PART']=part['path']
 argv=['bash',str(B/'scripts/run_isolated_test.sh'),str(shim) if part else '/tmp/pr15-hud-diagnostic/godot-dummy',entry,mode]
 label='configured-'+label
 packet={'label':label,'start':utc(),'argv':argv,'cap_s':60,'part':part,'process_group_owned':True}
 with (R/(label+'-request.json')).open('x') as f:json.dump(packet,f,indent=2)
 with (R/(label+'.log')).open('xb') as log:
  p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);packet['pid']=p.pid
  try:p.wait(timeout=60);packet['timeout']=False
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait();packet['timeout']=True
 text=(R/(label+'.log')).read_text();packet.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',text,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',text,re.M)),guard='TEST_STORAGE_ISOLATED user_dir=' in text,summary=[s for s in text.splitlines() if 'checks=' in s or 'TEST_RUN_ID=' in s or 'failures=' in s])
 blob=(json.dumps(packet,indent=2)+'\n').encode()
 for suffix in ['-receipt.json','-receipt-vault.json']:
  with (R/(label+suffix)).open('xb') as f:f.write(blob)
 print(json.dumps(packet),flush=True);assert packet['actual_exit']==packet['ERROR']==packet['SCRIPT_ERROR']==0 and packet['guard'] and not packet['timeout']
 return packet

for entry,mode in [('replay_event_text_source_test.gd','--headless'),('command_pose_clock_test.gd','--headless'),('presentation_lifecycle_test.gd','--render')]:run('required-'+entry.removesuffix('.gd'),entry,mode)
print('CONFIGURED_REQUIRED_END actual0 all Guard/E0/S0',flush=True)
