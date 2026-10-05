from pathlib import Path
import json,hashlib,gzip,subprocess,datetime
R=Path('/tmp/pr15-replay-first-draw-20261005')
D=Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-replay-first-draw')
D.mkdir(parents=True,exist_ok=False)
items=[];blobs={}
for p in sorted(R.rglob('*')):
 if not p.is_file() or 'ambush_test_runs' in p.parts:continue
 rel=p.relative_to(R).as_posix();raw=p.read_bytes();h=hashlib.sha256(raw).hexdigest()
 if p.suffix=='.png':
  dest='images/'+h+'.png';blob=raw;encoding='original PNG, content-addressed exact deduplication'
 elif p.suffix=='.json' and len(raw)>150000:
  dest=rel+'.gz';blob=gzip.compress(raw,compresslevel=9,mtime=0);encoding='gzip lossless original JSON';assert gzip.decompress(blob)==raw
 else:dest=rel;blob=raw;encoding='original bytes'
 out=D/dest;out.parent.mkdir(parents=True,exist_ok=True)
 if not out.exists():out.write_bytes(blob)
 assert out.read_bytes()==blob
 blobs[dest]={'path':dest,'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()}
 items.append({'original_path':rel,'original_bytes':len(raw),'original_sha256':h,'artifact':dest,'encoding':encoding})
analysis=json.loads((R/'analysis.json').read_text());end=json.loads((R/'window-end.json').read_text())
receipt={'source_A':'1ec3198e9c0db367af96fc264604c5a286003b5e','source_B':'95daa05d0ccfc4e6bd357060b1f34c2a863c2041','window_end':end,'rows':len(analysis['rows']),'UI_nodes_each':455,'UI_different_nodes':sum(len(x['UI_different_nodes']) for x in analysis['rows']),'PNG_pairs':sum('pixels' in x for x in analysis['rows']),'changed_pixels':sum(x.get('pixels',{}).get('changed',0) for x in analysis['rows']),'strict_complete_AB_equal':False,'full_raw_differences':sum(x['full_difference_count'] for x in analysis['rows']),'scope':'native llvmpipe/synthetic GUI/fixed-fps60 consumer fixture, no post-setup refresh; 29 cross-process raw domain/synchronous utility scope differences retained; not ordinary fresh victory, Web first draw, fullsmoke, performance, or independent QA acceptance','parent_QA_status':'handoff received; original b3be packet location not yet supplied; original E6/E3 layout failures stay open','decision':'withdraw sole unaccepted touch candidate; restore main bytes and game tree to 1ec; no visible regression claimed'}
blob=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode();(D/'receipt.json').write_bytes(blob);blobs['receipt.json']={'path':'receipt.json','bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()}
(D/'manifest.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'original_files':items,'artifacts':list(blobs.values()),'artifact_files':len(blobs),'artifact_bytes':sum(x['bytes'] for x in blobs.values()),'original_bytes_SHA_verified':True,'gzip_roundtrip_exact':True,'all_PNG_original_bytes_preserved_by_explicit_digest_mapping':True},ensure_ascii=False,indent=2))
print(json.dumps({'actual_exit':0,'original_files':len(items),'artifacts':len(blobs),'bytes':sum(x['bytes'] for x in blobs.values()),'unique_original_png':sum(x.endswith('.png') for x in blobs),'gzip_roundtrip':True,'PNG_pairs':receipt['PNG_pairs']}))
