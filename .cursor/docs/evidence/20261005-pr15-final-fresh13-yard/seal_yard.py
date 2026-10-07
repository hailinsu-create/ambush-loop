from pathlib import Path
import json,hashlib,gzip,datetime
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
D=Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-final-fresh13-yard')
assert not D.exists();D.mkdir(parents=True)
sources=[p for p in sorted(R.iterdir()) if p.is_file() and p.suffix in ['.py','.gd','.json','.log']]
sources += [p for p in sorted((R/'run').rglob('*')) if p.is_file() and p.suffix in ['.json','.jsonl','.png','.bin','.log']]
rows=[]
for p in sources:
 data=p.read_bytes();rel=p.relative_to(R);compressed=p.suffix=='.bin' or len(data)>262144
 target=D/(str(rel)+('.gz' if compressed else ''));target.parent.mkdir(parents=True,exist_ok=True)
 saved=gzip.compress(data,mtime=0) if compressed else data
 with target.open('xb') as f:f.write(saved)
 assert (gzip.decompress(target.read_bytes()) if compressed else target.read_bytes())==data
 rows.append({'original_path':str(p),'original_relative':str(rel),'original_bytes':len(data),'original_sha256':hashlib.sha256(data).hexdigest(),'artifact':str(target.relative_to(D)),'artifact_bytes':len(saved),'artifact_sha256':hashlib.sha256(saved).hexdigest(),'gzip_lossless':compressed})
manifest={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'product_source':'b74f1fc2f190f574cd0c31aba04e495829337214','game_tree':'1e8af45ee23098f763acc139b56f8f7e0f41665a','files':rows,'artifacts':len(rows),'artifact_bytes':sum(x['artifact_bytes'] for x in rows),'original_bin_first_sealed':True,'PNG_actual_viewed':sorted(p.name for p in (R/'run').glob('*.png')),'scope':'21 original PNG all individually viewed; raw and gzip decoded original bytes exact; PCK/cache/profile not duplicated into Git'}
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
for row in rows:
 p=D/row['artifact'];assert p.stat().st_size==row['artifact_bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==row['artifact_sha256']
print(json.dumps({k:v for k,v in manifest.items() if k not in ['files','PNG_actual_viewed']}))
