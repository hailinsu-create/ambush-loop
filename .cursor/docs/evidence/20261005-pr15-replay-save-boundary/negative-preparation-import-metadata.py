from pathlib import Path
import shutil,subprocess,json,hashlib
ROOT=Path('/workspace/ambush-pr15');BASE=Path('/tmp/pr15-web-controls/replay-save-classification-20261005')
STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005');assert not STAGE.exists()
SOURCE=subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip();assert SOURCE=='1ec3198e9c0db367af96fc264604c5a286003b5e'
shutil.copytree('/workspace/pr15-web-stage-event-log-20261005',STAGE)
for name in ['scripts/main.gd','scripts/replay_progress_save_test.gd','scripts/run_isolated_test.sh','scripts/run_isolated_test.ps1']:
 shutil.copy2(ROOT/'ambush_loop'/name,STAGE/name)
files=subprocess.check_output(['git','-C',str(ROOT),'ls-files','ambush_loop'],text=True).splitlines();checked=[];excluded=[]
for name in files:
 rel=Path(name).relative_to('ambush_loop');p=STAGE/rel;expected=ROOT/name
 if expected.suffix=='.blend':excluded.append(name);continue
 assert p.exists() and p.read_bytes()==expected.read_bytes(),name
 checked.append({'path':name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
prior=json.loads((Path('/tmp/pr15-web-controls/depot-native-8532-20261005')/'preflight.json').read_text())['pins'];pins=[]
for pin in prior:
 p=ROOT/pin['path'];pins.append({'path':pin['path'],'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'blob':subprocess.check_output(['git','-C',str(ROOT),'rev-parse',SOURCE+':'+pin['path']],text=True).strip()})
result={'source':SOURCE,'game_tree':subprocess.check_output(['git','-C',str(ROOT),'rev-parse',SOURCE+':ambush_loop'],text=True).strip(),'stage':str(STAGE),'checked':checked,'excluded_author_blend':excluded,'pins':pins,'scope':'copied existing imported production stage; only main/targeted test/runner files replaced from fixed Git; no generator/GLB/atlas/Blender execution'}
(BASE/'fixed-stage-proof.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'source':SOURCE,'game_tree':result['game_tree'],'checked_files':len(checked),'excluded_blend':len(excluded),'stage':str(STAGE)}))
