from pathlib import Path
import json,re,struct,hashlib,shutil
BASE=Path('/tmp/pr15-web-controls/event-log-ui-20261005');ROOT=Path('/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05')
def payload(path,name):
 b=path.read_bytes();base=struct.unpack_from('<Q',b,24)[0];p=struct.unpack_from('<Q',b,32)[0];n=struct.unpack_from('<I',b,p)[0];p+=4
 for _ in range(n):
  size=struct.unpack_from('<I',b,p)[0];p+=4;k=b[p:p+size].rstrip(b'\0').decode();p+=size;o,z=struct.unpack_from('<QQ',b,p);p+=36
  if k==name:return b[base+o:base+o+z]
 raise KeyError(name)
def classes(b):
 text=b.decode();blocks=re.findall(r'\{.*?\}',text,re.S);out={}
 for block in blocks:
  name=re.search(r'"class": &"([^"]+)"',block).group(1);assert name not in out;out[name]=block
 return out
name='.godot/global_script_class_cache.cfg';old=payload(ROOT/'debug/index.pck',name);new=payload(ROOT/'event-log-cold-qa-v2-20261005/index.pck',name)
a=classes(old);b=classes(new);assert a==b
shutil.copy2(BASE/'qa-v2-payload-audit.json',BASE/'qa-v2-payload-audit-initial-negative.json')
audit=json.loads((BASE/'qa-v2-payload-audit.json').read_text());assert audit['unexpected_changed']==[name]
receipt={'initial_audit_runner_actual_exit':1,'engine_export_actual_exit':0,'acceptance_actual_exit':0,'all_payload_md5_verified':True,'class_cache_difference':'order only; complete per-class raw blocks equal; no class/base/path/icon/flags differences','class_count':len(a),'production_class_sha256':hashlib.sha256(old).hexdigest(),'qa_class_sha256':hashlib.sha256(new).hexdigest(),'added':audit['added'],'changed':audit['changed'],'removed':audit['removed'],'production_source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','scope':'metadata ordering explicitly accepted with structural proof, payload is not bit-identical'}
(BASE/'qa-v2-payload-acceptance.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt))
