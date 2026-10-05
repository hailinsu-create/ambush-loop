assert len(context.pages)==1 and page.url==URL
assert d.state()['phase']==3 and d.state()['attempt']==radio_record['attempt']
assert d.rpc('fingerprints')['record_sha256']==radio_record['sha256']
assert packet1['status']==packet2['status']=='PASS'
producer=json.loads((BASE/'radio-producer.json').read_text())
assert d.state()['settings']['configs']==producer['state']['settings']['configs']
d.producer_active=False
(BASE/'radio-before-boundary-fingerprints.json').write_text(json.dumps(d.rpc('fingerprints'),ensure_ascii=False,indent=2)+'\n')
(BASE/'radio-before-boundary-browser.json').write_text(json.dumps(page.evaluate('window.pr15TrustedInputs'),ensure_ascii=False,indent=2)+'\n')
original_reload=reload_original
def reload_with_proof(driver,expected,label,reopen=False):
    fp=driver.rpc('fingerprints')
    (BASE/(label+'-engine-before-reload.json')).write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
    (BASE/(label+'-browser-before-reload.json')).write_text(json.dumps(driver.page.evaluate('window.pr15TrustedInputs'),ensure_ascii=False,indent=2)+'\n')
    assert len(context.pages)==1
    return original_reload(driver,expected,label,reopen)
reload_original=reload_with_proof
expected=plan['expected_after_natural_win'];assert_progress(d.state(),expected)
d.click('continue');assert d.state()['modal']['credits']
before_scroll=d.capture('radio_credits_open');c=d.rpc('controls')['credits_scroll'];x,y,w,h=c['rect']
assert before_scroll['credits_scroll']['max']>before_scroll['credits_scroll']['page'],before_scroll['credits_scroll']
wheel_point=d.coords([x+w/2,y+h/2]);d.page.mouse.move(*wheel_point);d.page.mouse.wheel(0,600);d.settle()
after_scroll=d.capture('radio_credits_scrolled')
assert after_scroll['modal']['credits'] and after_scroll['credits_scroll']['vertical']>before_scroll['credits_scroll']['vertical']
assert after_scroll['settings']['configs']==before_scroll['settings']['configs']
(BASE/'radio-credits-scroll-proof.json').write_text(json.dumps({'status':'PASS','before':before_scroll,'after':after_scroll,'wheel_css':wheel_point,'wheel_delta_y':600,'scope':'original WON Continue, actual trusted wheel, readonly existing ScrollContainer vertical/max/page, no forced scroll value'},ensure_ascii=False,indent=2)+'\n')
d.click('credits_back');d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original credits -> safe Title',120)
original_title_rows(d,expected,'radio_complete')
reload_original(d,expected,'radio_complete_reload')
reload_original(d,expected,'radio_complete_reopen',True)
final_state=d.state();assert final_state['scene']=='res://scenes/title.tscn'
assert_progress(final_state,expected);assert final_state['continue_disabled'] and not final_state['fixture_ready']
d.capture('radio_complete_saved_safe_title')
final_fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert all(row['isTrusted'] for row in trusted) and len(context.pages)==1
(BASE/'radio-boundary-final-fingerprints.json').write_text(json.dumps(final_fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'radio-boundary-final-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
(BASE/'profile-after-radio.json').write_text(json.dumps({'status':'PASS','state':final_state,'public_checkpoint':json.loads(checkpoint),'public_checkpoint_sha256':hashlib.sha256(checkpoint.encode()).hexdigest(),'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','profile':str(PROFILE),'url':URL,'whole_status':'PASS_ORIGINAL_PRODUCER_RECORD_1x_2x','rate_wall_ratio':packet1['input_to_terminal_callback_wall']/packet2['input_to_terminal_callback_wall'],'scope':'original radio WON record whole1x/2x, original credits open and actual scroll, six cleared/unlocked complete and disabled Continue, exact full cfg and public checkpoint reload/limited same profile reopen, safe Title'},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'RADIO_PROGRESS_END':utc(),'status':'PASS','complete':True,'cleared':[m['id'] for m in final_state['settings']['missions'] if m['cleared']],'whole':'PASS','owned_pages':len(context.pages),'credits_scroll_before':before_scroll['credits_scroll'],'credits_scroll_after':after_scroll['credits_scroll']}),flush=True)
