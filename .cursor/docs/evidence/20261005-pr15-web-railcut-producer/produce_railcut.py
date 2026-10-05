assert len(context.pages)==1 and page.url==URL
assert d.state()['scene']=='res://scenes/title.tscn'
d.producer_budget_started_at=time.monotonic();d.level_start=d.producer_budget_started_at;d.producer_active=True
try:
 d.click('title_continue')
 state=d.wait(lambda x:x.get('level')=='railcut' and x.get('phase')==0,'original Title Continue new railcut SCOUT',120)
 assert not state['fixture_ready'] and not state['modal']['tutorial'] and not state['modal']['handoff']
 assert state['settings']['seen'].get('railcut') and all(op['weapon']=='knife' for op in state['operators'])
 assert state['waves_cleared']==0 and state['wave_count']==2
 (BASE/'railcut-start-checkpoint.json').write_text(json.dumps({'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','budget_started_wall':d.producer_budget_started_at,'state':state,'scope':'new original Continue knife-only railcut attempt; tutorial naturally seen from pump boundary; no seed/preview stitching','profile':str(PROFILE),'url':page.url},ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'RAILCUT_PRODUCER_START':utc(),'attempt':state['attempt'],'phase':state['phase'],'wave_count':state['wave_count'],'tutorial':False,'budget':900}),flush=True)
 railcut_record=d.mission(plan)
 fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
 assert all(row['isTrusted'] for row in trusted) and len(context.pages)==1
 (BASE/'railcut-original-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
 (BASE/'railcut-browser-trusted.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'RAILCUT_PRODUCER_ARCHIVED':True,'record':railcut_record,'owned_pages':len(context.pages)}),flush=True)
except Exception as error:
 d.producer_active=False
 state=d.state();fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
 (BASE/'railcut-producer-failure-checkpoint.json').write_text(json.dumps({'state':state,'exception':str(error),'elapsed_wall':time.monotonic()-d.producer_budget_started_at,'fingerprints':fp,'browser_inputs':trusted,'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','scope':'failure preserved, no source/policy/tick/phase mutation'},ensure_ascii=False,indent=2)+'\n')
 d.capture('railcut_failure_'+state.get('attempt','title'))
 if state.get('phase') in [2,3]:d.archive('railcut-failure-'+state['attempt'])
 print(json.dumps({'RAILCUT_PRODUCER_FAIL':utc(),'attempt':state.get('attempt'),'phase':state.get('phase'),'exception':str(error),'elapsed_wall':time.monotonic()-d.producer_budget_started_at}),flush=True)
 raise
