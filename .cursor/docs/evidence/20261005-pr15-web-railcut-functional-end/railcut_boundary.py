assert len(context.pages)==1 and page.url==URL
assert d.state()['phase']==3 and d.state()['attempt']==railcut_record['attempt']
assert d.rpc('fingerprints')['record_sha256']==railcut_record['sha256']
assert packet1['status']==packet2['status']=='PASS'
producer=json.loads((BASE/'railcut-producer.json').read_text())
assert d.state()['settings']['configs']==producer['state']['settings']['configs']
d.producer_active=False
(BASE/'railcut-before-boundary-fingerprints.json').write_text(json.dumps(d.rpc('fingerprints'),ensure_ascii=False,indent=2)+'\n')
(BASE/'railcut-before-boundary-browser.json').write_text(json.dumps(page.evaluate('window.pr15TrustedInputs'),ensure_ascii=False,indent=2)+'\n')
original_reload=reload_original
def reload_with_proof(driver,expected,label,reopen=False):
 fp=driver.rpc('fingerprints')
 (BASE/(label+'-engine-before-reload.json')).write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
 (BASE/(label+'-browser-before-reload.json')).write_text(json.dumps(driver.page.evaluate('window.pr15TrustedInputs'),ensure_ascii=False,indent=2)+'\n')
 assert len(context.pages)==1
 return original_reload(driver,expected,label,reopen)
reload_original=reload_with_proof
boundary(d,plan)
state=d.state()
assert state['level']=='depot' and state['phase']==0 and not state['fixture_ready']
assert not state['modal']['tutorial'] and state['settings']['seen'].get('depot')
continued_attempt=state['attempt'];assert all(op['weapon']=='knife' for op in state['operators'])
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
d.wait(lambda s:s['scene']=='res://scenes/title.tscn','safe original Title after depot reload check',120)
final_state=d.state();assert_progress(final_state,plan['expected_after_natural_win'])
d.capture('railcut_saved_depot_next_title')
final_fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert all(row['isTrusted'] for row in trusted) and len(context.pages)==1
(BASE/'railcut-boundary-final-fingerprints.json').write_text(json.dumps(final_fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'railcut-boundary-final-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
(BASE/'profile-after-railcut.json').write_text(json.dumps({'status':'PASS','state':final_state,'public_checkpoint':json.loads(checkpoint),'public_checkpoint_sha256':hashlib.sha256(checkpoint.encode()).hexdigest(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','profile':str(PROFILE),'url':URL,'continued_knife_preview_attempt':continued_attempt,'whole_status':'PASS_ORIGINAL_PRODUCER_RECORD_1x_2x','rate_wall_ratio':packet1['input_to_terminal_callback_wall']/packet2['input_to_terminal_callback_wall'],'scope':'original railcut WON record whole1x/2x, then save unlock depot handoff first tutorial Title reload Continue no repeated tutorial safe return Title; no depot producer'},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'RAILCUT_PROGRESS_END':utc(),'status':'PASS','next':'depot','cleared':[m['id'] for m in final_state['settings']['missions'] if m['cleared']],'whole':'PASS','owned_pages':len(context.pages)}),flush=True)
