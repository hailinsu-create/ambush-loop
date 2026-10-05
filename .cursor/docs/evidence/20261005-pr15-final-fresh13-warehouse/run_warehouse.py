from pathlib import Path
import subprocess,sys,os,signal,time,json,datetime,hashlib,socket
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,indent=2)
for port in [12815,12816,12817,12915]:
 s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0,(port,'busy');s.close()
live=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])]
assert not live,live
assert Path(json.loads((R/'spec.json').read_text())['profile']).exists()
audit=json.loads((R/'aligned-payload-audit.json').read_text());assert not audit['removed'] and set(audit['changed'])<= {'project.binary','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'}
steps=[('preserved-title-warehouse-entry','initialize_warehouse.py',180),('warehouse-natural-two-waves','produce_warehouse.py',900),('warehouse-original-checkpoint-boundary','finish_warehouse.py',300)]
receipt={'START':now(),'cap_seconds':1430,'steps':steps,'source':json.loads((R/'spec.json').read_text())['candidate'],'argv':[sys.executable,str(R/'browser_controller_warehouse.py')],'profile_preserved':True}
save('warehouse-window-request.json',receipt);print(json.dumps({'FIRST_PACKAGE_START':receipt['START'],**receipt}),flush=True)
t=time.monotonic();child=subprocess.Popen(receipt['argv'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,start_new_session=True,bufsize=1)
child.stdin.write(''.join(json.dumps({'label':label,'script':str(R/file)})+'\n' for label,file,cap in steps)+json.dumps({'label':'close-warehouse-packet','close':True})+'\n');child.stdin.flush();child.stdin.close()
import threading
timed_out=False
def timeout():
 global timed_out
 timed_out=True
 try:os.killpg(child.pid,signal.SIGKILL)
 except ProcessLookupError:pass
timer=threading.Timer(1430,timeout);timer.start()
step_timer=None
caps={label:cap for label,file,cap in steps}
with (R/'warehouse-controller.log').open('x') as log:
 for line in child.stdout:
  log.write(line);log.flush();print(line,end='',flush=True)
  try:row=json.loads(line)
  except json.JSONDecodeError:continue
  if row.get('kind')=='REQUEST_START' and row.get('label') in caps:
   if step_timer:step_timer.cancel()
   step_timer=threading.Timer(caps[row['label']],timeout);step_timer.start()
  elif row.get('kind')=='REQUEST_END' and step_timer:step_timer.cancel();step_timer=None
child.wait();timer.cancel()
if step_timer:step_timer.cancel()
receipt.update(END=now(),wall_seconds=time.monotonic()-t,actual_exit=child.returncode,timed_out=timed_out)
packets=[]
for label,file,cap in steps:
 p=R/'warehouse-run/receipts'/(label+'.json')
 if p.exists():
  data=json.loads(p.read_text());seconds=(datetime.datetime.fromisoformat(data['end'])-datetime.datetime.fromisoformat(data['start'])).total_seconds();packets.append({'label':label,'actual_exit':data['actual_exit'],'wall_seconds':seconds,'cap_seconds':cap,'within_cap':seconds<=cap})
receipt['request_results']=packets
receipt['all_steps_passed']=len(packets)==len(steps) and all(x['actual_exit']==0 and x['within_cap'] for x in packets)
save('warehouse-window-end.json',receipt);save('warehouse-window-end-vault.json',receipt)
print(json.dumps({'FIRST_PACKAGE_END':receipt}),flush=True)
assert child.returncode==0 and receipt['all_steps_passed'] and not timed_out
