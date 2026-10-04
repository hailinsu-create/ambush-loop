import subprocess,sys,json,hashlib,os,datetime,re
from pathlib import Path
mode,label,root,proof=sys.argv[1:5]
assert mode in ['A','B']
base=Path('/tmp/pr15-hud-diagnostic')
assert not (base/(label+'.log')).exists()
source=subprocess.check_output(['git','-C',root,'rev-parse','HEAD'],text=True).strip()
tree=subprocess.check_output(['git','-C',root,'rev-parse','HEAD:ambush_loop'],text=True).strip()
subprocess.run(['git','-C',root,'diff','--exit-code','HEAD','--','ambush_loop'],check=True,stdout=subprocess.DEVNULL)
env=os.environ.copy(); env.update({'DISPLAY':':127','LIBGL_ALWAYS_SOFTWARE':'1','AMBUSH_TEST_SOURCE_SHA':source,'AMBUSH_A3_GAME_TREE':tree,'AMBUSH_A3_PROVENANCE_FILE':proof,'AMBUSH_HUD_PROFILE_ON':mode,'AMBUSH_PAIR_FIXTURE_SHA':hashlib.sha256((base/'hud_batch_pair_external.gd').read_bytes()).hexdigest(),'AMBUSH_PAIR_IMPORT_METADATA':str(base/'import-sidecars-manifest.json'),'AMBUSH_PAIR_IMPORT_METADATA_SHA':hashlib.sha256((base/'import-sidecars-manifest.json').read_bytes()).hexdigest()})
cmd=['bash',root+'/ambush_loop/scripts/run_isolated_test.sh',str(base/'godot-hud-batch-pair'),'a3_campaign_metrics_test.gd','--render']
meta={'variant':mode,'argv':cmd,'source':source,'game_tree':tree,'display':':127','driver_sha256':env['AMBUSH_PAIR_FIXTURE_SHA'],'proof_sha256':hashlib.sha256(Path(proof).read_bytes()).hexdigest(),'start':datetime.datetime.now(datetime.timezone.utc).isoformat()}
(base/(label+'.source')).write_text(mode+'\n'+source+'\n'+tree+'\n'+env['AMBUSH_PAIR_FIXTURE_SHA']+'\n')
(base/(label+'.start')).write_text(meta['start']+'\n')
with (base/(label+'.log')).open('wb') as log:
 p=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT);meta['owned_wrapper_pid']=p.pid
 (base/(label+'.pid')).write_text(str(p.pid)+'\n');p.wait()
meta['actual_exit']=p.returncode;meta['end']=datetime.datetime.now(datetime.timezone.utc).isoformat()
data=(base/(label+'.log')).read_text(errors='replace')
meta['ERROR']=len(re.findall(r'^ERROR:',data,re.M));meta['SCRIPT_ERROR']=len(re.findall(r'^SCRIPT ERROR:',data,re.M));meta['stdout_bytes']=(base/(label+'.log')).stat().st_size
m=re.search(r'^TEST_RUN_ID=(.*)$',data,re.M);meta['uuid']=m.group(1) if m else None
meta['terminal_lines']=[x for x in data.splitlines() if 'HUD_BATCH_PAIR_TEST' in x or x.startswith('SCRIPT ERROR:') or x.startswith('ERROR:')]
(base/(label+'.exit')).write_text(str(p.returncode)+'\n');(base/(label+'.end')).write_text(meta['end']+'\n');(base/(label+'.json')).write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta,indent=2));sys.exit(p.returncode)
