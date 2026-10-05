exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_core.py').read_text(),globals())
exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_whole_and_progress.py').read_text(),globals())
spec=json.loads(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/spec.json').read_text())
d=Driver(page,BASE)
page.goto(URL,wait_until='load')
page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
assert page.title()=='Ambush Loop (DEBUG)'
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'resumed original Title',120)
prior=json.loads(Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause/run/yard_stop_reopen-after-reload.json').read_text())['state']
assert s['settings']['configs']==prior['settings']['configs'] and s['settings']['seen']==prior['settings']['seen']
assert_progress(s,spec['missions'][0]['expected_after_natural_win'])
d.capture('resumed_title_yard_clear')
d.click('title_continue')
s=d.wait(lambda x:x.get('level')=='warehouse' and x.get('phase')==0,'original Continue warehouse',120)
assert s['modal']['tutorial'] and not s['modal']['handoff']
warehouse_entry_attempt=s['attempt']
d.tutorial();d.capture('warehouse_fresh_knife_scout')
assert d.state()['attempt']==warehouse_entry_attempt
emit('WAREHOUSE_ENTRY_END',attempt=warehouse_entry_attempt,status='PASS_ORIGINAL_CONTINUE_FROM_YARD_CHECKPOINT',yard_handoff_scope='not observed: earlier legitimate Title checkpoint discarded live yard')
