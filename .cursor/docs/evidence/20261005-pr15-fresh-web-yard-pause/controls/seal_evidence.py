from pathlib import Path
import shutil,hashlib,json,datetime
BASE=Path('/tmp/pr15-web-controls/fresh-native-dab-20261005')
OUT=Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause')
assert not OUT.exists();OUT.mkdir(parents=True)
for p in sorted(BASE.iterdir()):
 if p.is_file() and p.suffix in ['.py','.gd','.json','.log','.md']:
  dest=OUT/'controls'/p.name;dest.parent.mkdir(exist_ok=True);shutil.copy2(p,dest)
for p in sorted((BASE/'run').iterdir()):
 if p.is_file() and p.suffix in ['.py','.json','.jsonl','.log','.png','.bin']:
  dest=OUT/'run'/p.name;dest.parent.mkdir(exist_ok=True);shutil.copy2(p,dest)
rows=[]
for p in sorted(OUT.rglob('*')):
 if not p.is_file():continue
 rel=str(p.relative_to(OUT));assert not rel.endswith(('.pck','.wasm','.blend','.glb','.tpz'))
 source=BASE/(p.relative_to(OUT).parts[-1]) if rel.startswith('controls/') else BASE/'run'/p.name
 assert p.read_bytes()==source.read_bytes()
 rows.append({'path':rel,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
manifest={'status':'PAUSED_USER_REQUEST','sealed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_sha':'dab870595175eed37a6d2a012bc69a76062d48b0','game_tree':'4f49a7c9cb5a789fbb570bceb947eab7df2eb54a','scope':'one actually started fresh Web yard packet only; ordinary input two natural waves/WON and Title unlock reload/reopen','file_count':len(rows),'total_bytes':sum(x['bytes'] for x in rows),'original_record_included':True,'browser_profiles_binaries_credentials_not_included':True,'files':rows}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({k:v for k,v in manifest.items() if k!='files'}))
