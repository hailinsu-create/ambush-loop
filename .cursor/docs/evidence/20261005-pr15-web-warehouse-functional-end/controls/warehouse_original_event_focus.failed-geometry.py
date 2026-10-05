assert len(context.pages)==1
assert warehouse_whole_1['status']=='PASS' and warehouse_whole_2['status']=='PASS'
assert d.state()['phase']==3
baseline=d.rpc('fingerprints')
assert baseline['record_sha256']==warehouse_record['sha256']
d.click('replay')
if d.state()['replay']['playing']:d.click('pause')
if not d.state()['event_log_open']:d.click('log')
focus_results=[]
for wave,ratios in [(0,[0.66,0.70,0.78]),(1,[0.92,0.94,0.96])]:
 found=None
 for ratio in ratios:
  c=d.rpc('controls')['scrub'];x,y,w,h=c['rect']
  d.page.mouse.click(*d.coords([x+w*ratio,y+h/2]));d.settle()
  controls=d.rpc('controls')
  candidates=[(k,v) for k,v in controls.items() if k.startswith('event_row:') and v['visible'] and v['event'].get('type')=='fire' and v['event'].get('wave_id')==wave]
  d.log('original event row candidates',wave=wave,ratio=ratio,controls={k:v for k,v in controls.items() if k.startswith('event_row:')},state=d.state())
  if candidates:
   found=candidates[-1];break
 assert found,('no original visible fire row',wave)
 key,c=found;ev=c['event'];assert ev['attempt_id']==warehouse_record['attempt']
 assert ev['event_id']==f"{ev['attempt_id']}:{wave}:{ev['seq']}"
 assert c['readonly_hit_index']==int(key.split(':')[1])
 d.click(key);s=d.state();fp=d.rpc('fingerprints')
 assert s['phase']==4 and not s['replay']['playing']
 assert s['replay']['tick']==ev['playback_tick'],(s['replay'],ev)
 assert s['focus_actor']==ev['actor_id'] and s['focus_type']=='fire' and s['event_ring_visible']
 assert s['view']['attempt']==warehouse_record['attempt'] and s['view']['wave']==wave and s['view']['tick']==ev['playback_tick']
 assert fp['domain']==baseline['domain'] and fp['record_sha256']==warehouse_record['sha256']
 assert not fp['frame_checks']['failures'] and not fp['record_validation']['failures']
 d.capture('warehouse_wave'+str(wave)+'_original_event_focus')
 focus_results.append({'wave':wave,'selected_control':c,'state':s,'frame_checks':fp['frame_checks'],'record_unchanged':True,'domain_unchanged':True})
d.key('Space');assert d.state()['phase']==3
packet={'status':'PASS','scope':'original UI seek/log/visible event row click on both original waves, separate from whole; no focus_latest/set_tick callback','record_sha256':warehouse_record['sha256'],'results':focus_results}
(BASE/'warehouse-original-event-focus.json').write_text(json.dumps(packet,ensure_ascii=False,indent=2)+'\n')
emit('WAREHOUSE_ORIGINAL_EVENT_FOCUS_END',status='PASS',waves=[r['wave'] for r in focus_results],record_sha256=warehouse_record['sha256'])
f=d.rpc('fingerprints');assert f['record_sha256']==warehouse_record['sha256']
(BASE/'warehouse-after-whole-focus-fingerprints.json').write_text(json.dumps(f,ensure_ascii=False,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs');assert all(r['isTrusted'] for r in trusted)
(BASE/'warehouse-after-whole-focus-trusted.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
