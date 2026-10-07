assert len(context.pages)==1 and page.url==URL
plan=spec['missions'][2];assert plan['level']=='pump'
d.producer_budget_started_at=time.monotonic();d.producer_active=True
d.click('title_continue')
state=d.wait(lambda x:x.get('level')=='pump' and x.get('phase')==0,'original Title Continue new pump SCOUT',120)
assert not state['fixture_ready'] and not state['modal']['tutorial'] and not state['modal']['handoff']
assert state['settings']['seen'].get('pump') and all(op['weapon']=='knife' for op in state['operators'])
assert state['waves_cleared']==0 and state['wave_count']==2
(BASE/'pump-start-checkpoint.json').write_text(json.dumps({'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','budget_started_wall':d.producer_budget_started_at,'state':state,'scope':'new original Continue knife-only pump attempt; tutorial already seen from original warehouse boundary; no seed/preview stitching','profile':str(PROFILE),'url':page.url},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'PUMP_PRODUCER_START':True,'attempt':state['attempt'],'phase':state['phase'],'wave_count':state['wave_count'],'tutorial':state['modal']['tutorial'],'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05'}),flush=True)
pump_record=d.mission(plan)
pump_fingerprints=d.rpc('fingerprints');pump_trusted=page.evaluate('window.pr15TrustedInputs')
assert all(row['isTrusted'] for row in pump_trusted) and len(context.pages)==1
(BASE/'pump-original-fingerprints.json').write_text(json.dumps(pump_fingerprints,ensure_ascii=False,indent=2)+'\n')
(BASE/'pump-browser-trusted.json').write_text(json.dumps(pump_trusted,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'PUMP_PRODUCER_ARCHIVED':True,'record':pump_record,'owned_pages':len(context.pages)}),flush=True)
