exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_core.py').read_text(),globals())
exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_whole_and_progress.py').read_text(),globals())
spec=json.loads(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/spec.json').read_text())
d=Driver(page,BASE)
page.goto(URL,wait_until='load');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
assert page.title()=='Ambush Loop (DEBUG)'
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'sync reader resumed original Title',120)
assert len(context.pages)==1
prior={'public_checkpoint':page.evaluate("localStorage.getItem('ambush-loop.config.v1')")}
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==prior['public_checkpoint']
assert_progress(s,spec['missions'][1]['expected_after_natural_win'])
latencies=[];frames=[]
for _ in range(10):
 start=time.monotonic();q=d.rpc('state');latencies.append(time.monotonic()-start);frames.append(q['engine_frames'])
 assert q['settings']['configs']==s['settings']['configs'] and q['input_count']==s['input_count']
(BASE/'sync-read-control.json').write_text(json.dumps({'latency_wall_s':latencies,'engine_frames':frames,'no_game_input':True,'cfg_unchanged':True,'scope':'QA API latency only, no manual process/tick and not FPS acceptance'},indent=2)+'\n')
print(json.dumps({'SYNC_READ_CONTROL':latencies,'engine_frames':frames}),flush=True)
d.click('title_start');d.click('mission_row:warehouse');d.capture('warehouse_sync_brief');d.click('brief_go')
s=d.wait(lambda s:s.get('level')=='warehouse' and s.get('phase')==0,'original mission replay warehouse SCOUT',120)
assert not s['modal']['tutorial'] and all(o['weapon']=='knife' for o in s['operators'])
assert s['attempt'] not in ['1c9e6cb757ca36a5f3950bf67d6acb0e','d8ba862ce497eb87f8d3fde463a5d35b']
d.capture('warehouse_sync_knife_scout')
emit('WAREHOUSE_SYNC_ENTRY_END',attempt=s['attempt'],scope='original mission replay after multi-tab environment correction; independent one-page regression; previous natural records/capFAIL not erased')
