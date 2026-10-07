from pathlib import Path
import json,hashlib,re,struct,datetime
ROOT=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005');SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e';OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'radio-observer-qa-20261005'
def entries(path):
    b=path.read_bytes(); assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
    base=struct.unpack_from('<Q',b,24)[0]; pos=struct.unpack_from('<Q',b,32)[0]; count=struct.unpack_from('<I',b,pos)[0]; pos+=4; out={}; payload={}
    for _ in range(count):
        n=struct.unpack_from('<I',b,pos)[0];pos+=4;name=b[pos:pos+n].rstrip(b'\0').decode();pos+=n
        off,size=struct.unpack_from('<QQ',b,pos);pos+=16;md5=b[pos:pos+16];pos+=16;flags=struct.unpack_from('<I',b,pos)[0];pos+=4;assert flags==0
        content=b[base+off:base+off+size];assert len(content)==size and hashlib.md5(content).digest()==md5
        out[name]={'bytes':size,'sha256':hashlib.sha256(content).hexdigest()};payload[name]=content
    return out,payload

old,old_payload=entries(OUT.parent/'event-log-cold-qa-v2-20261005/index.pck');new,new_payload=entries(OUT/'index.pck')
delta={'added':sorted(set(new)-set(old)),'removed':sorted(set(old)-set(new)),'changed':sorted(k for k in set(old)&set(new) if old[k]!=new[k])}
assert not delta['added'] and not delta['removed'],delta
assert all('event_log_observer' in k or k.endswith('.godot/global_script_class_cache.cfg') or k.endswith('.godot/uid_cache.bin') for k in delta['changed']),delta
class_key=next(k for k in new_payload if k.endswith('.godot/global_script_class_cache.cfg'))
def blocks(payload):return sorted(re.findall(r'\{[^{}]*\}',payload[class_key].decode(),re.S))
assert blocks(old_payload)==blocks(new_payload)
report={'source':SOURCE,'all_payload_md5_verified':True,'qa_vs_fixed_qa':delta,'complete_class_blocks_equal':True,'class_blocks':len(blocks(new_payload)),'asset_payloads_unchanged':True,'production_bit_identical':False,'actual_exit':0,'scope':'corrected pure payload audit after actual export0; original wrapper key-prefix KeyError1 retained, no new engine/export','old':old,'new':new}
with (ROOT/'radio-payload-audit.json').open('x') as f:json.dump(report,f,indent=2)
print(json.dumps({k:v for k,v in report.items() if k not in ['old','new']}),flush=True)
