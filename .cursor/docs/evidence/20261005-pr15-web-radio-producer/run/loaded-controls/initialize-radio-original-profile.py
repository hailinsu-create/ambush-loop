from pathlib import Path
ROOT=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005')
exec((ROOT/'driver_core.py').read_text(),globals());exec((ROOT/'driver_whole_and_progress.py').read_text(),globals())
spec=json.loads((ROOT/'spec.json').read_text());plan=spec['missions'][5];assert plan['level']=='radio'
d=Driver(page,BASE)
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=120000)
state=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'preserved original Title radio source1ec',120)
prior=json.loads((ROOT/'expected-profile-before.json').read_text())
assert page.url==URL and not state['fixture_ready'] and len(context.pages)==1
assert state['settings']['configs']==prior['state']['settings']['configs']
for key in ['muted','music_volume','sfx_volume','force_touch_hud','quality','seen','next','complete','missions']:assert state['settings'][key]==prior['state']['settings'][key],key
checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
assert hashlib.sha256(checkpoint.encode()).hexdigest()==prior['public_checkpoint_sha256'] and json.loads(checkpoint)['schema']==1
assert_progress(state,spec['missions'][4]['expected_after_natural_win'])
assert state['settings']['next']=='radio' and state['settings']['seen']['radio']
d.capture('radio_before_continue_title')
(BASE/'profile-before.json').write_text(json.dumps({'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','state':state,'cfg_text_and_sha_exact':True,'public_checkpoint_exact':True,'public_checkpoint_sha256':prior['public_checkpoint_sha256'],'single_page':len(context.pages),'url':page.url,'fixture_ready':False,'seed':False},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'RADIO_PROFILE_CHECK':'PASS','actual_exit':0,'next':state['settings']['next'],'seen_radio':True,'owned_pages':len(context.pages),'producer':'NOT_STARTED'}),flush=True)
