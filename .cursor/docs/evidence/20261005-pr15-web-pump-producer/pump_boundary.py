assert len(context.pages)==1 and page.url==URL
assert d.state()['phase']==3 and d.state()['attempt']==pump_record['attempt']
assert d.rpc('fingerprints')['record_sha256']==pump_record['sha256']
d.producer_active=False
exec((BASE.parent/'driver_whole_and_progress.py').read_text().replace('PASS_PRODUCER_WHOLE_PROGRESS','PASS_PRODUCER_PROGRESS_WHOLE_PENDING'),globals())
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
assert state['level']=='railcut' and state['phase']==0 and not state['fixture_ready']
assert not state['modal']['tutorial'] and state['settings']['seen'].get('railcut')
continued_attempt=state['attempt']
assert all(op['weapon']=='knife' for op in state['operators'])
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
d.wait(lambda s:s['scene']=='res://scenes/title.tscn','safe original Title after railcut reload check',120)
final_state=d.state();assert_progress(final_state,plan['expected_after_natural_win'])
d.capture('pump_saved_railcut_next_title')
final_fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert all(row['isTrusted'] for row in trusted) and len(context.pages)==1
(BASE/'pump-boundary-final-fingerprints.json').write_text(json.dumps(final_fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'pump-boundary-final-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
(BASE/'profile-after-pump.json').write_text(json.dumps({'status':'PASS','state':final_state,'public_checkpoint':json.loads(checkpoint),'public_checkpoint_sha256':hashlib.sha256(checkpoint.encode()).hexdigest(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','profile':str(PROFILE),'url':URL,'continued_knife_preview_attempt':continued_attempt,'whole_status':'PENDING_SEPARATE_COLD_CONSUMER','scope':'original save unlock handoff first railcut tutorial Title reload Continue no repeated tutorial safe return Title; no railcut producer'},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'PUMP_PROGRESS_END':'PASS','next':'railcut','cleared':[m['id'] for m in final_state['settings']['missions'] if m['cleared']],'whole':'PENDING','owned_pages':len(context.pages)}),flush=True)
