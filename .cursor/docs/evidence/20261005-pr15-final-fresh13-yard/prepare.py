from pathlib import Path
import json,hashlib,subprocess,shutil,ast,datetime
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
REPO=Path('/workspace/ambush-pr15')
SOURCE='b74f1fc2f190f574cd0c31aba04e495829337214'
TREE='1e8af45ee23098f763acc139b56f8f7e0f41665a'
STAGE=Path('/workspace/pr15-final-fresh13-stage-1ec-20261005')
PURE=Path('/workspace/pr15-replay-save-stage-1ec-20261005')
PROFILE=Path('/workspace/.ambush-loop-env/web-final-fresh13-1ec-20261005')
OLD=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005')
def save(name,value):
 with (R/name).open('x') as f:json.dump(value,f,ensure_ascii=False,indent=2)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert subprocess.check_output(['git','rev-parse','HEAD:ambush_loop'],cwd=REPO,text=True).strip()==TREE
assert not STAGE.exists() and not PROFILE.exists()
shutil.copytree(PURE,STAGE)
checked=[];omitted=[]
files=subprocess.check_output(['git','ls-tree','-r','--name-only','-z',SOURCE,'ambush_loop'],cwd=REPO).decode().split('\0')[:-1]
for full in files:
 rel=full.removeprefix('ambush_loop/');p=STAGE/rel
 if rel.endswith('.blend'):omitted.append(rel);continue
 expected=subprocess.check_output(['git','show',SOURCE+':'+full],cwd=REPO)
 assert p.is_file() and p.read_bytes()==expected,rel
 checked.append({'path':rel,'bytes':len(expected),'sha256':sha(p)})
assert omitted==['ArtSource/v2/yard_kit.blend']
old_storage=[]
for folder in ['Default/Local Storage','Default/IndexedDB']:
 for p in sorted((OLD/folder).rglob('*')):
  if p.is_file():old_storage.append({'path':str(p.relative_to(OLD)),'bytes':p.stat().st_size,'sha256':sha(p)})
save('old-campaign-storage-before.json',{'profile':str(OLD),'read_only':True,'files':old_storage})
base=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005')
bridge=(base/'event_log_observer.gd').read_text()
bridge=bridge.replace('# External QA stage only. Declared one-time cold history setup, then read-only RPC; no direct runtime player commands.','# Final fresh campaign: external read-only observer. No cold fixture or mutation RPC.')
bridge=bridge.replace('\tcall_deferred("_cold_fixture")\n','')
a=bridge.index('func _cold_fixture()');b=bridge.index('func _presented()',a);bridge=bridge[:a]+bridge[b:]
assert not any(x in bridge for x in ['mark_tutorial_seen(', 'change_scene_to_file(', '_on_replay_pressed(', 'm.phase =', 'settings.pending_level_id ='])
(STAGE/'qa').mkdir(exist_ok=False)
(R/'observer.gd').write_text(bridge);shutil.copy2(R/'observer.gd',STAGE/'qa/final_observer.gd')
project=STAGE/'project.godot';original=project.read_text()
assert 'FreshObserver' not in original
project.write_text(original.replace('[autoload]','[autoload]\n\nFreshObserver="*res://qa/final_observer.gd"',1))
driver=(base/'driver_core.py').read_text().replace('1ec3198e9c0db367af96fc264604c5a286003b5e',SOURCE)
driver=driver.replace("self.producer_active=False;producer_wall=time.monotonic()-self.level_start;self.capture(self.level+'_won')\n  record=self.archive(self.level);record['producer_wall']=producer_wall", "self.producer_active=False;producer_wall=time.monotonic()-self.level_start\n  record=self.archive(self.level);record['producer_wall']=producer_wall\n  seal_checkpoint(self,self.level+'_natural_WON_before_consumer',record)\n  self.capture(self.level+'_won')")
assert 'seal_checkpoint(self' in driver
(R/'driver_core.py').write_text(driver)
(R/'progress.py').write_text((base/'driver_whole_full_fingerprints.py').read_text().replace('1ec3198e9c0db367af96fc264604c5a286003b5e',SOURCE))
spec=json.loads((base/'spec.json').read_text())
save('spec.json',{'candidate':{'source':SOURCE,'game_tree':TREE},'missions':spec['missions'],'profile':str(PROFILE),'old_profile':str(OLD),'origin':'http://127.0.0.1:12915/index.html','seed':False,'single_engine':True,'whole':'separate bounded consumers after original bin sealed; no new producer rerun','tool_positive':'only actual current-writer event and saved confirmation; absent = UNRUN'})
controller=(base/'browser_controller.py').read_text().replace(str(base),str(R)).replace(str(OLD),str(PROFILE)).replace("Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/radio-observer-qa-20261005')","Path('/workspace/pr15-web-artifacts/b74f1fc2f190f574cd0c31aba04e495829337214/final-fresh13-qa-20261005')").replace('12815','12915').replace('RADIO_','FINAL_FRESH_').replace('1ec3198e9c0db367af96fc264604c5a286003b5e',SOURCE)
(R/'browser_controller.py').write_text(controller)
module=ast.parse(Path('/tmp/pr15-web-controls/fresh-native-dab-20261005/prepare_fixture.py').read_text())
fn=next(x for x in module.body if isinstance(x,ast.FunctionDef) and x.name=='entries')
(R/'pck_reader.py').write_text('import struct\n'+ast.unparse(fn)+'\n')
save('baseline.json',{'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':SOURCE,'head_at_prepare':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),'game_tree':TREE,'stage':str(STAGE),'profile':str(PROFILE),'profile_initially_absent':True,'production_files':checked,'omitted_nonruntime':omitted,'observer_sha256':sha(R/'observer.gd'),'old_profile_untouched':str(OLD),'scope':'original complete Title source; only external readonly autoload/project registration; cached assets copied, no generator/Blender/asset import rerun'})
for p in R.glob('*.py'):compile(p.read_bytes(),str(p),'exec')
print(json.dumps({'actual_exit':0,'source':SOURCE,'tree':TREE,'checked':len(checked),'observer_sha256':sha(R/'observer.gd'),'fresh_profile_absent':True,'old_storage_files':len(old_storage)}))
