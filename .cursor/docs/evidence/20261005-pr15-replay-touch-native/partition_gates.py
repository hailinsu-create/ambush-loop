from pathlib import Path
import os,subprocess,json,hashlib,datetime,re,signal
R=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005');B=Path('/workspace/pr15-replay-touch-candidate-95daa-20261005');G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
source=(B/'scripts/equipment_freeze_test.gd').read_text();parts=[]
for part in ['alert','paused_alert','replay','legal']:
 text=source.replace('for state in ["alert", "paused_alert", "replay"]:',f'for state in {json.dumps([] if part=="legal" else [part])}:').replace('for state in ["scout", "sweep"]:','for state in '+('["scout", "sweep"]' if part=='legal' else '[]')+':')
 start=text.index('\t_fixture(main)\n\tmain._toggle_backpack()',text.index('for state in ["scout", "sweep"]:' if part=='legal' else 'for state in []:',text.index('for action in')))
 end=text.index('\tif failures == 0:',start)
 tail=text[start:end];text=text[:start]+'\tif '+('true' if part=='legal' else 'false')+':\n'+''.join('\t'+line for line in tail.splitlines(True))+text[end:]
 path=R/('equipment-part-'+part+'.gd');path.write_text(text);parts.append({'part':part,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
with (R/'equipment-partition-spec.json').open('x') as f:json.dump({'original_source_sha256':hashlib.sha256(source.encode()).hexdigest(),'parts':parts,'max_each_s':60,'max_equipment_partition_package_s':240,'scope':'same original assertions/fixtures/handlers; only partition state loop lists and legal tail; no new runtime diff; original monolithic cap60 timeout remains failed; unique expected18+18+18+12=66'},f,indent=2)
shim=R/'godot-part';shim.write_text('#!/usr/bin/env python3\nimport sys,os\nfrom pathlib import Path\na=sys.argv[1:];p=Path(os.environ["PR15_EQUIPMENT_PART"]);assert p.parent==Path("'+str(R)+'") and p.is_file();assert a[-1]=="res://scripts/equipment_freeze_test.gd";a[-1]=str(p);os.execv("'+G+'",["'+G+'","--audio-driver","Dummy"]+a)\n');shim.chmod(0o755)
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def run(label,entry,mode,part=None):
 env=os.environ.copy();env.update(DISPLAY=':99',LIBGL_ALWAYS_SOFTWARE='1')
 if part:env['PR15_EQUIPMENT_PART']=part['path']
 argv=['bash',str(B/'scripts/run_isolated_test.sh'),str(shim) if part else '/tmp/pr15-hud-diagnostic/godot-dummy',entry,mode]
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
packets=[]
for p in parts:packets.append(run('partition-equipment-'+p['part'],'equipment_freeze_test.gd','--headless',p))
checks=[int(re.search('EQUIPMENT_FREEZE_OK checks=(\\d+)',(R/('partition-equipment-'+p['part']+'.log')).read_text()).group(1)) for p in parts]
assert checks==[18,18,18,12],checks
with (R/'equipment-partition-END.json').open('x') as f:json.dump({'checks':checks,'unique_original_assertions':sum(checks),'actual_exits':[p['actual_exit'] for p in packets],'original_monolithic_cap_timeout_not_overridden':True},f,indent=2)
for entry,mode in [('replay_event_text_source_test.gd','--headless'),('command_pose_clock_test.gd','--headless'),('presentation_lifecycle_test.gd','--render')]:run('required-'+entry.removesuffix('.gd'),entry,mode)
print('PARTITION_REQUIRED_END actual0 all same original assertions/Guard/E0/S0; monolithic timeout remains',flush=True)
