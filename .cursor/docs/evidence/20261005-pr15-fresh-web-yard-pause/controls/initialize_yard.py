exec(Path('/tmp/pr15-web-controls/fresh-native-dab-20261005/driver_core.py').read_text(),globals())
d=Driver(page,BASE)
campaign_start=time.monotonic()
emit('CAMPAIGN_START',source='dab870595175eed37a6d2a012bc69a76062d48b0',url=URL,profile=str(PROFILE),scope='fresh original trusted inputs; source-derived strategy, not stranger playtest')
page.goto(URL,wait_until='load')
page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
assert page.title()=='Ambush Loop (DEBUG)'
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'original Title ready',120)
assert not s['settings']['has_progress'] and not s['settings']['complete'] and not s['settings']['seen']
assert [x['id'] for x in s['settings']['missions'] if x['unlocked']]==['yard']
assert not any(x['cleared'] for x in s['settings']['missions'])
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')") is None
d.capture('fresh_title')
d.click('title_start');assert d.state()['mission_select'];d.capture('fresh_mission_rows')
d.click('mission_row:yard');assert d.state()['briefing'] and d.state()['pending']=='yard';d.capture('yard_brief')
d.click('brief_go')
s=d.wait(lambda x:x.get('level')=='yard' and x.get('modal',{}).get('tutorial'),'ordinary original SCOUT tutorial',120)
assert s['phase']==0 and all(o['weapon']=='knife' for o in s['operators'])
d.tutorial();d.capture('yard_fresh_knife_scout')
spec=json.loads(Path('/workspace/ambush-pr15/.cursor/docs/AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json').read_text())
emit('YARD_ENTRY_END',status='PASS',state=d.state(),trusted_input_trace=page.evaluate('window.pr15TrustedInputs'))
