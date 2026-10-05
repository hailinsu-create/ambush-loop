from pathlib import Path
import struct,hashlib,json
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
def read(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 base=struct.unpack_from('<Q',b,24)[0];d=struct.unpack_from('<Q',b,32)[0];n=struct.unpack_from('<I',b,d)[0];p=d+4;out={}
 for i in range(n):
  length=struct.unpack_from('<I',b,p)[0];p+=4;name=b[p:p+length].rstrip(b'\0').decode();p+=length
  offset,size=struct.unpack_from('<QQ',b,p);p+=16;md5=b[p:p+16];p+=16;flags=struct.unpack_from('<I',b,p)[0];p+=4
  payload=b[base+offset:base+offset+size];assert len(payload)==size and hashlib.md5(payload).digest()==md5
  out[name]={'bytes':size,'sha256':hashlib.sha256(payload).hexdigest(),'md5_verified':True}
 return out
old=read(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/hud-segment-qa-20261005/index.pck'))
new=read(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/hud-subsegment-qa-20261005/index.pck'))
add=sorted(new.keys()-old.keys());remove=sorted(old.keys()-new.keys());changed=[k for k in sorted(old.keys()&new.keys()) if old[k]!=new[k]]
allow={'scripts/main.gdc','scripts/touch_hud.gdc','qa/event_log_observer.gdc','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'}
result={'old_count':len(old),'new_count':len(new),'added':add,'removed':remove,'changed':changed,'unexpected':[k for k in changed if k not in allow],'all_payload_md5_verified':True,'scope':'vs sealed HUD QA; only three declared compiled scripts and engine metadata permitted; production payloads/assets unchanged','actual_exit':0 if not add and not remove and not [k for k in changed if k not in allow] else 1,'changed_entries':{k:{'old':old[k],'new':new[k]} for k in changed}}
(R/'pck-payload-audit-v2.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='changed_entries'}));assert result['actual_exit']==0
