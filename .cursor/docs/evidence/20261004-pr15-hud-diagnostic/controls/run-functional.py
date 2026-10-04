import subprocess,sys,json,time,os,signal,re,datetime
from pathlib import Path
label,entry,root=sys.argv[1:4]
base=Path('/tmp/pr15-hud-diagnostic')
assert not (base/(label+'.json')).exists() and not (base/(label+'.log')).exists()
source=subprocess.check_output(['git','-C',root,'rev-parse','HEAD'],text=True).strip()
tree=subprocess.check_output(['git','-C',root,'rev-parse','HEAD:ambush_loop'],text=True).strip()
cmd=['bash',root+'/ambush_loop/scripts/run_isolated_test.sh',str(base/(os.environ.get('AMBUSH_DIAG_ENGINE','godot-dummy'))),entry,os.environ.get('AMBUSH_DIAG_MODE','--headless')]
meta={'argv':cmd,'source':source,'game_tree':tree,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'timeout_seconds':240,'timed_out':False}
with (base/(label+'.log')).open('wb') as log:
 p=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 meta['owned_wrapper_pid']=p.pid
 try:p.wait(timeout=240)
 except subprocess.TimeoutExpired:
  meta['timed_out']=True
  os.killpg(p.pid,signal.SIGTERM)
  try:p.wait(timeout=5)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
meta['actual_wrapper_exit']=p.returncode
meta['end']=datetime.datetime.now(datetime.timezone.utc).isoformat()
data=(base/(label+'.log')).read_text(errors='replace')
meta['ERROR']=len(re.findall(r'^ERROR:',data,re.M));meta['SCRIPT_ERROR']=len(re.findall(r'^SCRIPT ERROR:',data,re.M))
m=re.search(r'^TEST_RUN_ID=(.*)$',data,re.M);meta['uuid']=m.group(1) if m else None
meta['terminal_lines']=[x for x in data.splitlines() if 'FAILED' in x or '_OK' in x or x.startswith('SCRIPT ERROR:') or x.startswith('ERROR:') or x.startswith('          at:')]
(base/(label+'.json')).write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta,indent=2))
