ROOT=Path('/tmp/pr15-web-controls/pump-native-8532-20261005')
exec((ROOT/'driver_core.py').read_text(),globals());exec((ROOT/'driver_whole_and_progress.py').read_text(),globals())
spec=json.loads((ROOT/'spec.json').read_text());d=Driver(page,BASE)
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=120000)
state=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'preserved profile Title source8532',120)
prior=json.loads((ROOT/'expected-profile-before.json').read_text())
assert page.url==URL and not state['fixture_ready']
assert state['settings']['configs']==prior['state']['settings']['configs']
for key in ['muted','music_volume','sfx_volume','force_touch_hud','quality','seen','next','complete','missions']:assert state['settings'][key]==prior['state']['settings'][key],key
checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
assert hashlib.sha256(checkpoint.encode()).hexdigest()==prior['checkpoint_sha256']
assert json.loads(checkpoint)['schema']==1
assert_progress(state,spec['missions'][1]['expected_after_natural_win'])
d.capture('pump_before_continue_title')
(BASE/'profile-before.json').write_text(json.dumps({'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','state':state,'cfg_text_and_sha_exact':True,'public_checkpoint_exact':True,'public_checkpoint_sha256':prior['checkpoint_sha256'],'single_page':len(context.pages),'url':page.url,'fixture_ready':state['fixture_ready'],'seed':False},ensure_ascii=False,indent=2)+'\n')
print('PUMP_PROFILE_CHECK actual0 exact cfg/checkpoint/nextpump/seenpump; Continue pending producer',flush=True)
