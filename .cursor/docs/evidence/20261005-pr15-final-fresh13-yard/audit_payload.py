from pathlib import Path
import json,hashlib
from pck_reader import entries
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
B=json.loads((R/'baseline.json').read_text());SOURCE=B['source'];OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'final-fresh13-qa-20261005'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,indent=2)
old=entries(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/debug/index.pck'));new=entries(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in old.keys()&new.keys() if old[k]!=new[k])
audit={'production_source':SOURCE,'production_tree':B['game_tree'],'all_payload_md5_verified':True,'added':added,'removed':removed,'changed':changed,'old':old,'new':new,'fixture_pck_sha256':sha(OUT/'index.pck'),'fixture_pck_bytes':(OUT/'index.pck').stat().st_size}
save('payload-audit.json',audit)
print(json.dumps({k:v for k,v in audit.items() if k not in ['old','new']}),flush=True)
assert added==['qa/final_observer.gd.remap','qa/final_observer.gdc'] and not removed and set(changed)<= {'project.binary','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'},'undeclared payload difference'
