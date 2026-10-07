assert len(context.pages)==1 and page.url==URL
state=d.state();assert state['attempt']=='1f32042b812907b6d833285e37ad9a5c' and state['level']=='depot' and state['phase']==5 and state['wave']==1 and state['waves_cleared']==2
start_checkpoint=json.loads((BASE/'depot-start-checkpoint.json').read_text());assert d.level_start==start_checkpoint['budget_started_wall']
d.producer_active=True;d.check_budget()
emit('DEPOT_RESUME_SAME_ATTEMPT',attempt=state['attempt'],phase=5,cleared=2,elapsed=time.monotonic()-d.level_start,budget=900,reason='original second wave naturally cleared before pause postcondition; retained original request actual1; no restart or budget reset')
(BASE/'depot-pause-race-pre-resume-state.json').write_text(json.dumps({'state':state,'fingerprints':d.rpc('fingerprints'),'elapsed_wall':time.monotonic()-d.level_start,'scope':'original naturally cleared second SWEEP checkpoint; partial copy_record_bytes refused natural-terminal guard; no bypass or reconstructed binary'},ensure_ascii=False,indent=2)+'\n')
d.check_budget();d.sweep(plan,1);d.click('alarm');state=d.state();assert state['phase']==3 and state['waves_cleared']==2
d.producer_active=False;producer_wall=time.monotonic()-d.level_start;assert producer_wall<900
d.capture('depot_won');depot_record=d.archive('depot');depot_record['producer_wall']=producer_wall
(BASE/'depot-producer.json').write_text(json.dumps({'status':'PASS','source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','record':depot_record,'state':d.state(),'method_negative':'produce-depot-natural actual1: second SWEEP preceded paused assertion; resumed same original attempt and original budget; wave1 paused-ALERT screenshot absent, do not claim pause checkpoint passed','partial_record':'UNAVAILABLE: original read-only copy API requires natural terminal; refusal retained actual1, no bypass'},indent=2)+'\n')
fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs');assert all(r['isTrusted'] for r in trusted)
(BASE/'depot-original-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n');(BASE/'depot-browser-trusted.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
emit('LEVEL_PRODUCER_END',level='depot',status='NATURAL_WON_SAME_ATTEMPT_WITH_RETAINED_METHOD_NEGATIVE',record=depot_record,original_request_exit=1,scope='same original budget; no second-wave paused checkpoint acceptance')
