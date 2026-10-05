assert d.state()['phase']==3
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
s=d.wait(lambda s:s['scene']=='res://scenes/title.tscn','late excluded original return Title',120)
assert_progress(s,spec['missions'][1]['expected_after_natural_win'])
f=d.rpc('fingerprints');assert not f['inputs'][-1].get('echo',False)
(BASE/'title-before-read-fix.json').write_text(json.dumps({'state':s,'public_checkpoint':page.evaluate("localStorage.getItem('ambush-loop.config.v1')"),'late_record':late_warehouse_record,'status':'LATE_WIN_PROGRESS_PRESERVED_NOT_PRODUCER_PASS'},indent=2)+'\n')
latencies=[]
for _ in range(10):
 start=time.monotonic();q=d.rpc('state');latencies.append(time.monotonic()-start)
 assert q['settings']['configs']==s['settings']['configs'] and q['input_count']==s['input_count']
(BASE/'deferred-read-control.json').write_text(json.dumps({'samples':10,'latency_wall_s':latencies,'config_unchanged':True,'no_game_input':True,'scope':'QA API latency only, no device FPS acceptance'},indent=2)+'\n')
emit('WAREHOUSE_DEFERRED_PACKET_END',late_record=late_warehouse_record,read_latency_wall_s=latencies,next='close owned browser before serial synchronous-reader fixture export')
