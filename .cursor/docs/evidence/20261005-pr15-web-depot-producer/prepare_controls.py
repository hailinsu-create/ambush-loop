from pathlib import Path
import json,hashlib,subprocess,datetime,shutil,socket
ROOT=Path('/workspace/ambush-pr15');PREV=Path('/tmp/pr15-web-controls/railcut-native-8532-20261005');BASE=Path('/tmp/pr15-web-controls/depot-native-8532-20261005')
assert not BASE.exists()
assert not subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain'],text=True).strip()
spec=json.loads((ROOT/'.cursor/docs/AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json').read_text());pins=[]
for pin in spec['source_strategy_pins']:
 p=ROOT/pin['path'];actual={'path':pin['path'],'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'git_blob':subprocess.check_output(['git','-C',str(ROOT),'hash-object',str(p)],text=True).strip()};assert actual==pin;pins.append(actual)
assert len(pins)==14 and subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD:ambush_loop'],text=True).strip()=='45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85'
for name in ['20261005-pr15-web-railcut-producer','20261005-pr15-web-railcut-functional-end']:
 prior_root=ROOT/'.cursor/docs/evidence'/name;m=json.loads((prior_root/'manifest.json').read_text())
 for f in m['files']:
  b=(prior_root/f['path']).read_bytes();assert len(b)==f['bytes'] and hashlib.sha256(b).hexdigest()==f['sha256']
profile=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert profile.is_dir() and not (profile/'SingletonLock').exists() and not (profile/'SingletonLock').is_symlink()
processes=subprocess.check_output(['ps','-eo','stat,comm,args'],text=True).splitlines()[1:]
live=[r for r in processes if not r.split()[0].startswith('Z') and r.split()[1] in ['chromium','chrome','Godot_v4.7.2-st','godot']];assert not live,live
for port in [12815,12816]:
 s=socket.socket();closed=s.connect_ex(('127.0.0.1',port))!=0;s.close();assert closed
pck=Path('/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-cold-qa-v2-20261005/index.pck');assert pck.stat().st_size==64662184 and hashlib.sha256(pck.read_bytes()).hexdigest()=='f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21'
prior=json.loads((PREV/'run-v2/profile-after-railcut.json').read_text());assert prior['state']['settings']['next']=='depot' and prior['state']['settings']['seen']['depot']
BASE.mkdir();shutil.copyfile(PREV/'run-v2/profile-after-railcut.json',BASE/'expected-profile-before.json')
spec.update({'status':'PREPARED_RUNTIME_UNRUN','candidate':{'source_sha':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','game_tree':'45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85'},'current_level':'depot','order':['verify_original_profile','original_continue_new_knife_attempt','natural_two_wave_producer_and_archive','original_whole1x','original_whole2x','radio_handoff_tutorial_save_reload','END'],'whole_scope':'same original producer scene original Replay UI; no isolated cold setup','site':'version3 unchanged; no redeploy per level','receipt_contract':'isolated runtime exec dictionary, lexical controller state, exclusive-create receipt plus immediate content SHA; existing labels rejected'})
(BASE/'spec.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n')
for name in ['driver_core.py','driver_whole_and_progress.py']:shutil.copyfile(PREV/name,BASE/name)
init=(PREV/'initialize.py').read_text().replace(str(PREV),str(BASE)).replace("plan=spec['missions'][3]","plan=spec['missions'][4]").replace('railcut','depot').replace("spec['missions'][2]['expected_after_natural_win']","spec['missions'][3]['expected_after_natural_win']").replace('RAILCUT','DEPOT')
(BASE/'initialize.py').write_text(init)
for old,new in [('produce_railcut.py','produce_depot.py'),('whole_railcut_1x.py','whole_depot_1x.py'),('whole_railcut_2x.py','whole_depot_2x.py'),('railcut_boundary.py','depot_boundary.py')]:
 s=(PREV/old).read_text().replace('railcut','depot').replace('RAILCUT','DEPOT')
 if 'boundary' in old:s=s.replace("=='depot' and state['phase']", "=='radio' and state['phase']").replace("get('depot')","get('radio')").replace('depot_saved_depot_next_title','depot_saved_radio_next_title').replace("'next':'depot'","'next':'radio'").replace('save unlock depot handoff','save unlock radio handoff').replace('no depot producer','no radio producer')
 (BASE/new).write_text(s)
audit=(PREV/'railcut_record_readonly_audit.gd').read_text().replace('RAILCUT','DEPOT').replace('railcut','depot');(BASE/'depot_record_readonly_audit.gd').write_text(audit)
runner=(PREV/'run_railcut_offline_audit.py').read_text().replace('RAILCUT','DEPOT').replace('railcut','depot').replace('run-v2/','run/');(BASE/'run_depot_offline_audit.py').write_text(runner)
preflight={'actual_exit':0,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','head':subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip(),'game_tree':'45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85','pins':pins,'reused_pck':{'bytes':pck.stat().st_size,'sha256':hashlib.sha256(pck.read_bytes()).hexdigest()},'prior_evidence':'railcut28+48 size/SHA exact; no files rewritten','expected_profile_public_sha256':prior['public_checkpoint_sha256'],'live_engines':live,'ports_closed':True,'profile_lock_absent':True,'runtime_started':False,'scope':'source/archive/profile existence precheck; actual Title exact comparison pending'}
(BASE/'preflight.json').write_text(json.dumps(preflight,indent=2)+'\n');shutil.copyfile(Path(__file__),BASE/'prepare_controls.py');print(json.dumps({k:v for k,v in preflight.items() if k!='pins'}),flush=True)
