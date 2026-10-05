from pathlib import Path
import json,copy,sys,hashlib
R=Path('/tmp/pr15-final-fresh13-1ec-20261005');level=sys.argv[1]
spec=json.loads((R/'spec.json').read_text());plan=copy.deepcopy(next(x for x in spec['missions'] if x['level']==level));index=next(i for i,x in enumerate(spec['missions']) if x['level']==level)
assert index>0
previous=spec['missions'][index-1]['level'];prior_folder='run' if previous=='yard' else previous+'-run'
prior=R/prior_folder/(previous+'_packet_final_Title-checkpoint.json');assert prior.is_file()
if level=='warehouse':
 plan['collect'].append({'family':'mine','operator_index':0});plan['scout_mine_cell']=[13,5];plan['first_sweep_mine_cell']=None
out=R/(level+'-plan.json');assert not out.exists();out.write_text(json.dumps({'candidate':spec['candidate'],'original_profile_checkpoint':str(prior),'plan':plan,'scope':'legitimate original UI inputs only; no seeded tool/win/sim state; coverage only after saved actual events'},indent=2)+'\n')
next_progress=R/'progress_next.py'
if not next_progress.exists():next_progress.write_text((R/'progress.py').read_text().replace('PASS_PRODUCER_WHOLE_PROGRESS','PASS_PRODUCER_PROGRESS_WHOLE_UNRUN'))
initialize=(R/'initialize.py').read_text();initialize=initialize[:initialize.index('page.goto(URL,')].replace("'progress.py'","'progress_next.py'")
initialize+=f'''packet=json.loads((R/'{level}-plan.json').read_text());plan=packet['plan']
prior=json.loads(Path(packet['original_profile_checkpoint']).read_text())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'same frozen original Title {level}',120)
assert not s['fixture_ready'] and s['settings']['configs']==prior['state']['settings']['configs']
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==prior['public_checkpoint']
assert s['settings']['next']=='{level}' and not s['settings']['complete']
seal_checkpoint(d,'{level}_preserved_Title_before_Continue');d.capture('{level}_preserved_Title')
d.click('title_continue')
s=d.wait(lambda x:x.get('level')=='{level}' and x.get('phase')==0,'original Continue fresh knife {level}',120)
assert not s['modal']['tutorial'] and all(o['weapon']=='knife' for o in s['operators'])
seal_checkpoint(d,'{level}_new_attempt_knife_SCOUT');d.capture('{level}_knife_SCOUT')
emit('NEXT_ENTRY_END',level='{level}',status='PASS_EXACT_PRIOR_CHECKPOINT',state=d.state())
'''
(R/('initialize_'+level+'.py')).write_text(initialize)
(R/('produce_'+level+'.py')).write_text(f"try:\n {level}_record=d.mission(plan)\nexcept Exception:\n if d.state().get('phase')==2:\n  failed_record=d.archive('{level}-failed-attempt')\n  seal_checkpoint(d,'{level}_natural_FAILED',failed_record)\n raise\nassert {level}_record['reason']=='win' and not {level}_record['validation']['failures']\nemit('NEXT_PRODUCER_END',record={level}_record,whole='UNRUN')\n")
finish=f'''assert d.state()['phase']==3 and {level}_record['level']=='{level}'
boundary(d,plan)
if plan['next_level'] is not None:
 assert d.state()['level']==plan['next_level'] and d.state()['phase']==0 and all(o['weapon']=='knife' for o in d.state()['operators'])
 seal_checkpoint(d,'{level}_next_preview_continue_SCOUT')
 d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
 d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original next SCOUT -> Title',120)
seal_checkpoint(d,'{level}_packet_final_Title')
fp=d.rpc('fingerprints');(BASE/'{level}-input-fingerprints.json').write_text(json.dumps(fp,indent=2)+'\\n')
trusted=page.evaluate('window.pr15TrustedInputs');assert trusted and all(x['isTrusted'] for x in trusted)
(BASE/'{level}-current-context-trusted.json').write_text(json.dumps(trusted,indent=2)+'\\n')
(BASE/'console-final.json').write_text(json.dumps({{'console':console,'errors':errors}},indent=2)+'\\n')
emit('NEXT_PACKET_FUNCTION_END',level='{level}',status='PASS_NATURAL_PRODUCER_CHECKPOINT',record={level}_record,whole='UNRUN',next_producer='NOT_STARTED')
'''
(R/('finish_'+level+'.py')).write_text(finish)
controller=(R/'browser_controller.py').read_text().replace("OUT=CONTROL_ROOT/'run'",f"OUT=CONTROL_ROOT/'{level}-run'")
(R/('browser_controller_'+level+'.py')).write_text(controller)
runner=(R/'run_yard.py').read_text().replace('yard',level).replace("R/'run/receipts'",f"R/'{level}-run/receipts'")
runner=runner.replace("assert not Path(json.loads((R/'spec.json').read_text())['profile']).exists()","assert Path(json.loads((R/'spec.json').read_text())['profile']).exists()")
runner=runner.replace("'profile_initially_absent':True","'profile_preserved':True").replace("str(R/'browser_controller.py')",f"str(R/'browser_controller_{level}.py')").replace("'initialize.py'",f"'initialize_{level}.py'")
runner=runner.replace("('fresh-title-", "('preserved-title-")
if level=='radio':runner=runner.replace('natural-two-waves','natural-three-waves')
(R/('run_'+level+'.py')).write_text(runner)
for p in [R/('initialize_'+level+'.py'),R/('produce_'+level+'.py'),R/('finish_'+level+'.py'),R/('browser_controller_'+level+'.py'),R/('run_'+level+'.py')]:compile(p.read_bytes(),str(p),'exec')
proof={'level':level,'candidate':spec['candidate'],'prior_checkpoint':str(prior),'prior_sha256':hashlib.sha256(prior.read_bytes()).hexdigest(),'plan_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'runtime_started':False,'PCK_unchanged':True,'whole':'UNRUN'}
(R/(level+'-prepare.json')).write_text(json.dumps(proof,indent=2)+'\n');print(json.dumps(proof))
