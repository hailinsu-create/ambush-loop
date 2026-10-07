from pathlib import Path
import struct, hashlib, json, re
BASE=Path('/tmp/pr15-web-controls/fresh-native-dab-20261005')
ART=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0')
def read(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 fb=struct.unpack_from('<Q',b,24)[0];d=struct.unpack_from('<Q',b,32)[0];n=struct.unpack_from('<I',b,d)[0];i=d+4;out={}
 for _ in range(n):
  z=struct.unpack_from('<I',b,i)[0];i+=4;k=b[i:i+z].rstrip(b'\0').decode();i+=z
  o,s=struct.unpack_from('<QQ',b,i);i+=16;md5=b[i:i+16];i+=16;flags=struct.unpack_from('<I',b,i)[0];i+=4
  payload=b[fb+o:fb+o+s];assert flags==0 and len(payload)==s and hashlib.md5(payload).digest()==md5
  out[k]=payload
 return out
old=read(ART/'debug/index.pck');new=read(ART/'fresh-native-qa-20261005/index.pck')
audit=json.loads((BASE/'pck-payload-audit.json').read_text())
details=[]
for name in audit['unexpected_changed']:
 assert name.endswith('.import')
 assert name.startswith(('art/audio_v2/','ui/fonts/'))
 a,b=old[name],new[name]
 pat=rb'^uid="uid://[a-z0-9]+"$'
 assert len(re.findall(pat,a,re.M))==len(re.findall(pat,b,re.M))==1
 assert re.sub(pat,b'uid="UID_ONLY"',a,flags=re.M)==re.sub(pat,b'uid="UID_ONLY"',b,flags=re.M),name
 target=re.search(rb'^path="res://(.*?)"$',a,re.M)[1].decode()
 assert target in old and old[target]==new[target],(name,target)
 details.append({'path':name,'old_uid':re.findall(pat,a,re.M)[0].decode(),'new_uid':re.findall(pat,b,re.M)[0].decode(),'target':target,'target_bytes':len(old[target]),'target_sha256':hashlib.sha256(old[target]).hexdigest()})
assert len(details)==47
same=[name for name in old if old[name]==new[name]]
out={'actual_exit':0,'fixture_gate':'PASS_WITH_EXPLICIT_UID_ONLY_METADATA_DIFFERENCES',
     'same_payloads':len(same),'new_observer_payloads':audit['added'],'registration_and_uid_cache': [x for x in audit['changed'] if x not in audit['unexpected_changed']],
     'uid_only_import_metadata':details,'all_47_referenced_resource_payloads_identical':True,
     'game_scripts_scenes_assets_equal_except_registered_metadata':True,
     'first_strict_audit_exit':1,'first_strict_audit_retained':True,
     'not_an_explanation_of_independent_PCK_32_or_96_bytes':True,
     'fixture_pck':audit['fixture_pck'],'bridge_sha256':hashlib.sha256((BASE/'readonly_campaign_bridge.gd').read_bytes()).hexdigest()}
(BASE/'fixture-identity-acceptance.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({k:v for k,v in out.items() if k!='uid_only_import_metadata'}))
