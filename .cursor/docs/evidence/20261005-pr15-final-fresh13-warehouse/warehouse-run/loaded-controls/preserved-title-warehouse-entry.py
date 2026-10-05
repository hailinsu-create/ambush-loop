from pathlib import Path
R=Path('/tmp/pr15-final-fresh13-1ec-20261005')
import hashlib,json
for helper in ['driver_core.py','progress_next.py']:
 raw=(R/helper).read_bytes();p=BASE/'loaded-controls'/('actual-'+helper)
 assert not p.exists();p.write_bytes(raw)
 print(json.dumps({'HELPER_ACTUAL_LOAD':helper,'sha256':hashlib.sha256(raw).hexdigest()}),flush=True)
 exec(compile(raw,str(R/helper),'exec'),globals())
spec=json.loads((R/'spec.json').read_text());d=Driver(page,BASE)
def seal_checkpoint(d,label,record=None):
 s=d.state();raw=d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 packet={'utc':utc(),'source':spec['candidate'],'state':s,'full_fingerprints':d.rpc('fingerprints'),'browser_trusted_inputs':d.page.evaluate('window.pr15TrustedInputs'),'public_checkpoint':raw,'public_checkpoint_sha256':hashlib.sha256(raw.encode()).hexdigest() if raw is not None else None,'record':record}
 p=d.base/(label+'-checkpoint.json');assert not p.exists();p.write_text(json.dumps(packet,ensure_ascii=False,indent=2)+'\n')
 vault=d.base/'receipt-vault'/(label+'-checkpoint.json');vault.parent.mkdir(exist_ok=True);assert not vault.exists();vault.write_bytes(p.read_bytes())
 d.log('checkpoint sealed '+label,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),record_sha256=record['sha256'] if record else None)
 return packet
packet=json.loads((R/'warehouse-plan.json').read_text());plan=packet['plan']
prior=json.loads(Path(packet['original_profile_checkpoint']).read_text())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'same frozen original Title warehouse',120)
assert not s['fixture_ready'] and s['settings']['configs']==prior['state']['settings']['configs']
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==prior['public_checkpoint']
assert s['settings']['next']=='warehouse' and not s['settings']['complete']
seal_checkpoint(d,'warehouse_preserved_Title_before_Continue');d.capture('warehouse_preserved_Title')
d.click('title_continue')
s=d.wait(lambda x:x.get('level')=='warehouse' and x.get('phase')==0,'original Continue fresh knife warehouse',120)
assert not s['modal']['tutorial'] and all(o['weapon']=='knife' for o in s['operators'])
seal_checkpoint(d,'warehouse_new_attempt_knife_SCOUT');d.capture('warehouse_knife_SCOUT')
emit('NEXT_ENTRY_END',level='warehouse',status='PASS_EXACT_PRIOR_CHECKPOINT',state=d.state())
