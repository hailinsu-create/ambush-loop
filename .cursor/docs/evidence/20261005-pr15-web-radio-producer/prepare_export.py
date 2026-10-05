from pathlib import Path
import shutil,hashlib,json
root=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005');old=Path('/workspace/pr15-replay-save-qa-stage-1ec-20261005');stage=Path('/workspace/pr15-radio-observer-stage-1ec-20261005');assert not stage.exists()
shutil.copytree(old,stage)
p=stage/'qa/event_log_observer.gd';before=p.read_bytes();s=before.decode();target='\tfor stash in m.raid_stashes:';assert s.count(target)==1
s=s.replace(target,'\tvar credits_scroll: ScrollContainer = m.credits_overlay.find_child("CreditsScroll",true,false)\n\tif credits_scroll:\n\t\tout["credits_scroll"] = {"vertical":credits_scroll.scroll_vertical,"max":credits_scroll.get_v_scroll_bar().max_value,"page":credits_scroll.get_v_scroll_bar().page}\n'+target)
p.write_text(s)
changed=[]
for f in sorted(old.rglob('*')):
 if f.is_file():
  rel=f.relative_to(old);other=stage/rel
  assert other.is_file()
  if hashlib.sha256(f.read_bytes()).digest()!=hashlib.sha256(other.read_bytes()).digest():changed.append(str(rel))
assert changed==['qa/event_log_observer.gd'],changed
proof={'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','game_tree':'1e8af45ee23098f763acc139b56f8f7e0f41665a','stage':str(stage),'basis':str(old),'changed':changed,'before_sha256':hashlib.sha256(before).hexdigest(),'after_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':'readonly state observation of existing CreditsScroll vertical/max/page; no mutation RPC, no asset generator/import pipeline rerun','runtime_started':False}
(root/'radio-observer-stage-proof.json').write_text(json.dumps(proof,indent=2)+'\n');shutil.copy2(p,root/'event_log_observer.gd');shutil.copy2(Path(__file__),root/'prepare_export.py');print(json.dumps(proof),flush=True)
