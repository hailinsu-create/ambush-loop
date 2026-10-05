from pathlib import Path
import json,hashlib,gzip,datetime,sys,subprocess,socket
R=Path('/tmp/pr15-final-fresh13-1ec-20261005');level=sys.argv[1]
REPO=Path('/workspace/ambush-pr15');D=REPO/'.cursor/docs/evidence'/('20261005-pr15-final-fresh13-'+level)
assert not D.exists();D.mkdir(parents=True)
end=json.loads((R/(level+'-window-end.json')).read_text());assert end['actual_exit']==0 and end['all_steps_passed']
before=json.loads((R/'old-campaign-storage-before-v3.json').read_text());old=Path(before['profile'])
assert all((old/x['path']).stat().st_size==x['bytes'] and hashlib.sha256((old/x['path']).read_bytes()).hexdigest()==x['sha256'] for x in before['files'])
live=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])];assert not live,live
s=socket.socket();assert s.connect_ex(('127.0.0.1',12915))!=0;s.close()
proof={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'old_storage_files':len(before['files']),'old_storage_exact':True,'live_engines':0,'port12915_closed':True}
(R/(level+'-post-END-safety.json')).write_text(json.dumps(proof,indent=2)+'\n')
names=['prepare_next.py','prepare_audit_next.py','seal_next.py','progress_next.py','record_audit.gd','utility_audit.gd','audit_warehouse_utility.py',level+'-plan.json',level+'-prepare.json','initialize_'+level+'.py','produce_'+level+'.py','finish_'+level+'.py','browser_controller_'+level+'.py','run_'+level+'.py','audit_'+level+'.py']
names += [p.name for p in R.iterdir() if p.is_file() and p.name.startswith(level+'-')]
sources=sorted({R/name for name in names if (R/name).is_file()})
sources += [p for p in sorted((R/(level+'-run')).rglob('*')) if p.is_file() and p.suffix in ['.json','.jsonl','.png','.bin','.log','.py']]
rows=[]
for p in sources:
 data=p.read_bytes();rel=p.relative_to(R);compressed=p.suffix=='.bin' or (len(data)>262144 and p.suffix!='.png')
 q=D/(str(rel)+('.gz' if compressed else ''));q.parent.mkdir(parents=True,exist_ok=True);saved=gzip.compress(data,mtime=0) if compressed else data
 with q.open('xb') as f:f.write(saved)
 assert (gzip.decompress(q.read_bytes()) if compressed else q.read_bytes())==data
 rows.append({'original_path':str(p),'original_bytes':len(data),'original_sha256':hashlib.sha256(data).hexdigest(),'artifact':str(q.relative_to(D)),'artifact_bytes':len(saved),'artifact_sha256':hashlib.sha256(saved).hexdigest(),'gzip_lossless':compressed})
manifest={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'level':level,'source':end['source'],'shared_base_commit':'c9e47776b67ca42d239c10786251452f005a8cfc','shared_evidence':'../20261005-pr15-final-fresh13-yard/manifest.json','PCK_sha256':'7cf3bd3c7646c3de14c7b1a34b3ec7e6e41afac54ee1ff0b2895d5d25be94631','files':rows,'artifacts':len(rows),'artifact_bytes':sum(x['artifact_bytes'] for x in rows),'scope':'per-level original records, exclusive requests/receipts/loaded controls, whole UNRUN; shared final candidate/import/readonly observer proof referenced, not duplicated'}
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
for row in rows:
 q=D/row['artifact'];assert q.stat().st_size==row['artifact_bytes'] and hashlib.sha256(q.read_bytes()).hexdigest()==row['artifact_sha256']
print(json.dumps({k:v for k,v in manifest.items() if k!='files'}))
