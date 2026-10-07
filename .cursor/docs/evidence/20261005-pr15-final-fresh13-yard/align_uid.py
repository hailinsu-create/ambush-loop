from pathlib import Path
import json,struct,hashlib,re
R=Path('/tmp/pr15-final-fresh13-1ec-20261005');B=json.loads((R/'baseline.json').read_text());S=Path(B['stage'])
def read(p):
 d=p.read_bytes();base=struct.unpack_from('<Q',d,24)[0];a=struct.unpack_from('<Q',d,32)[0];n=struct.unpack_from('<I',d,a)[0];a+=4;o={}
 for _ in range(n):
  z=struct.unpack_from('<I',d,a)[0];a+=4;k=d[a:a+z].rstrip(b'\0').decode();a+=z;x,l=struct.unpack_from('<QQ',d,a);a+=16;md5=d[a:a+16];a+=20;v=d[base+x:base+x+l];assert hashlib.md5(v).digest()==md5;o[k]=v
 return o
old=read(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/debug/index.pck'))
new=read(Path('/workspace/pr15-web-artifacts/b74f1fc2f190f574cd0c31aba04e495829337214/final-fresh13-qa-20261005/index.pck'))
rows=[];writes=[]
for k in sorted(old.keys()&new.keys()):
 if not k.endswith('.import') or old[k]==new[k]:continue
 a=old[k].rstrip(b'\0');b=new[k].rstrip(b'\0')
 assert re.sub(rb'^uid=.*\n',b'',a,flags=re.M)==re.sub(rb'^uid=.*\n',b'',b,flags=re.M),k
 uid=re.findall(rb'^uid=.*$',a,re.M);assert len(uid)==1
 prior=(S/k).read_bytes();result,count=re.subn(rb'^uid=.*$',lambda m:uid[0],prior,flags=re.M);assert count==1
 assert re.sub(rb'^uid=.*$',b'',prior,flags=re.M)==re.sub(rb'^uid=.*$',b'',result,flags=re.M)
 rows.append({'path':k,'only_export_uid_diff':True,'stage_before':hashlib.sha256(prior).hexdigest(),'stage_aligned':hashlib.sha256(result).hexdigest()});writes.append((S/k,result))
assert len(rows)==45
key='.godot/global_script_class_cache.cfg';blocks=lambda b:sorted(re.findall(rb'\{[^{}]*\}',b,re.S));assert blocks(old[key])==blocks(new[key])
for p,value in writes:p.write_bytes(value)
(S/key).write_bytes(old[key].rstrip(b'\0'));(S/'.godot/uid_cache.bin').write_bytes(old['.godot/uid_cache.bin'])
(R/'uid-only-alignment.json').write_text(json.dumps({'existing_production_uid_copy_only':True,'no_asset_generation':True,'class_blocks_exact':True,'rows':rows},indent=2))
text=(R/'export.py').read_text().replace('final-fresh13-qa-20261005','final-fresh13-qa-aligned-v2-20261005').replace("'export-","'aligned-export-").replace("'export.log'","'aligned-export.log'").replace("'payload-audit.json'","'aligned-payload-audit.json'")
(R/'export_aligned.py').write_text(text)
p=R/'browser_controller.py';p.write_text(p.read_text().replace('final-fresh13-qa-20261005','final-fresh13-qa-aligned-v2-20261005'))
p=R/'run_yard.py';p.write_text(p.read_text().replace("R/'payload-audit.json'","R/'aligned-payload-audit.json'"))
print(json.dumps({'actual_exit':0,'only_UID_metadata':45,'class_blocks_exact':True,'asset_generation':False}))
