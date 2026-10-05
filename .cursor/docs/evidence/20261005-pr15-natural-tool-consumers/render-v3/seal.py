from pathlib import Path
import json,gzip,hashlib,datetime
D=Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-natural-tool-consumers');D.mkdir(parents=True,exist_ok=False)
roots=[('admission-v1',Path('/tmp/pr15-natural-tool-originals-20261005')),('render-v2',Path('/tmp/pr15-natural-tool-render-v2-20261005')),('render-v3',Path('/tmp/pr15-natural-tool-render-v3-20261005'))]
items=[];artifacts={}
for prefix,root in roots:
 for p in sorted(root.rglob('*')):
  if not p.is_file() or any(part in ['ambush_test_runs','parse-isolation'] for part in p.parts) or p.suffix=='.bin':continue
  rel=prefix+'/'+p.relative_to(root).as_posix();raw=p.read_bytes();sha=hashlib.sha256(raw).hexdigest()
  if len(raw)>150000 and p.suffix=='.json':dest=rel+'.gz';blob=gzip.compress(raw,compresslevel=9,mtime=0);enc='gzip lossless';assert gzip.decompress(blob)==raw
  else:dest=rel;blob=raw;enc='original bytes'
  q=D/dest;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(blob);assert q.read_bytes()==blob
  artifacts[dest]={'path':dest,'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()};items.append({'original_path':rel,'original_bytes':len(raw),'original_sha256':sha,'artifact':dest,'encoding':enc})
receipt={'runtime_source':'b74f1fc2f190f574cd0c31aba04e495829337214','runtime_tree':'1e8af45ee23098f763acc139b56f8f7e0f41665a','pure_runtime_stage':'1ec products byte-equal to b74','initial_positive_mine_gate':'NOT_RUN_REQUIRED_MINE_FIELDS_ABSENT','admission':json.loads((roots[0][1]/'admission-receipt.json').read_text()),'admission_window_end':json.loads((roots[0][1]/'budget-end.json').read_text()),'consumer_window_end':json.loads((roots[2][1]/'compat-render-end.json').read_text()),'case_summary':[json.loads((roots[2][1]/name/'summary.json').read_text()) for name in ['warehouse-mine','railcut-repack']],'all_11_original_PNG_viewed':True,'scope':'old natural producer/current consumer; mine neutral compatibility plus victim120HP facts, repack fire/reload_contact/newfire; not final natural producer, positive mine cue, all-art/hand contact/LOD, source switch, whole/Web/A3/device acceptance','failures_retained':'v1 exit1/E1/S4 missing preload; v2 exit1/E1/S2 checkpoint type; v3 first check-only actual0/E4/S0 default-home XDG omission; isolated same-script check-only0/E0/S0; assertions/product unchanged'}
raw=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode();(D/'receipt.json').write_bytes(raw);artifacts['receipt.json']={'path':'receipt.json','bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
(D/'manifest.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'original_files':items,'artifacts':list(artifacts.values()),'artifact_files':len(artifacts),'artifact_bytes':sum(x['bytes'] for x in artifacts.values()),'all_bytes_SHA_checked':True,'gzip_roundtrip_exact':True,'original_raw_bins_not_duplicated':'refer original gzip paths and full raw SHA in admission-v1/decompression.json'},ensure_ascii=False,indent=2))
print(json.dumps({'actual_exit':0,'files':len(artifacts),'bytes':sum(x['bytes'] for x in artifacts.values()),'original_mappings':len(items),'PNG':sum(x.endswith('.png') for x in artifacts)},ensure_ascii=False))
