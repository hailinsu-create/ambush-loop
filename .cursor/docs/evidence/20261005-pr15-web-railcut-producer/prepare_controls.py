from pathlib import Path
import json,hashlib,subprocess,datetime,shutil,socket
ROOT=Path('/workspace/ambush-pr15');PREV=Path('/tmp/pr15-web-controls/pump-native-8532-20261005');BASE=Path('/tmp/pr15-web-controls/railcut-native-8532-20261005');assert not BASE.exists();BASE.mkdir()
spec=json.loads((ROOT/'.cursor/docs/AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json').read_text());pins=[]
for pin in spec['source_strategy_pins']:
 p=ROOT/pin['path'];actual={'path':pin['path'],'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'git_blob':subprocess.check_output(['git','-C',str(ROOT),'hash-object',str(p)],text=True).strip()};assert actual==pin; pins.append(actual)
assert len(pins)==14
assert subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD:ambush_loop'],text=True).strip()=='45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85'
assert not subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain'],text=True).strip()
profile=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert profile.is_dir() and not (profile/'SingletonLock').exists()
pck=Path('/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-cold-qa-v2-20261005/index.pck');assert pck.stat().st_size==64662184 and hashlib.sha256(pck.read_bytes()).hexdigest()=='f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21'
prior=json.loads((PREV/'run/profile-after-pump.json').read_text());assert prior['state']['settings']['next']=='railcut' and prior['state']['settings']['seen']['railcut']
shutil.copy2(PREV/'run/profile-after-pump.json',BASE/'expected-profile-before.json')
spec.update({'status':'PREPARED_RUNTIME_UNRUN','candidate':{'source_sha':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','game_tree':'45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85'},'current_level':'railcut','order':['verify_original_profile','original_continue_new_knife_attempt','natural_two_wave_producer_and_archive','original_whole1x','original_whole2x','depot_handoff_tutorial_save_reload','END'],'whole_scope':'same original producer scene original Replay UI; no isolated cold setup this slice','site':'version3 unchanged; no redeploy for each level'})
(BASE/'spec.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n')
for name in ['driver_core.py','driver_whole_and_progress.py']:shutil.copy2(PREV/name,BASE/name)
controller=(PREV/'browser_controller.py').read_text().replace('/tmp/pr15-web-controls/pump-native-8532-20261005/run',str(BASE/'run')).replace('PUMP_SINGLE_BROWSER','RAILCUT_SINGLE_BROWSER')
controller=controller.replace("  print('RAILCUT_SINGLE_BROWSER_READY source8532 preserved profile/origin no fixture query; Browser plugin not available; Playwright1.62.0',flush=True)","  print(json.dumps({'RAILCUT_ENGINE_START':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','owned_pages':len(context.pages),'url':URL,'profile':str(PROFILE),'fixture':False,'browser':'existing Playwright1.62.0/Chromium'}),flush=True)")
controller=controller.replace(" print('RAILCUT_SINGLE_BROWSER_END',flush=True)"," print(json.dumps({'RAILCUT_ENGINE_END':datetime.datetime.now(datetime.timezone.utc).isoformat()}),flush=True)")
(BASE/'browser_controller.py').write_text(controller)
preflight={'actual_exit':0,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','head':subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip(),'game_tree':'45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85','pins':pins,'reused_pck':{'bytes':pck.stat().st_size,'sha256':hashlib.sha256(pck.read_bytes()).hexdigest()},'prior_evidence':'47+48 size/SHA exact on precheck; no copies rewritten','expected_profile_public_sha256':prior['public_checkpoint_sha256'],'runtime_started':False,'scope':'source/records/preserved profile existence only; actual Title comparison still pending'}
(BASE/'preflight.json').write_text(json.dumps(preflight,indent=2)+'\n')
print(json.dumps({k:v for k,v in preflight.items() if k!='pins'}),flush=True)
