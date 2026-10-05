assert len(context.pages)==1 and page.url==URL
state=d.state();assert state['scene']=='res://scenes/title.tscn' and not state.get('fixture_ready',False)
assert_progress(state,plan['expected_after_natural_win']);assert state['continue_disabled']
profile=json.loads((BASE/'profile-after-radio.json').read_text())
assert profile['status']=='PASS' and profile['state']['settings']['configs']==state['settings']['configs']
assert packet1['status']==packet2['status']=='PASS'
assert not errors and not [r for r in console if r['type']=='error']
assert not [r for r in console if 'GL_INVALID' in r['text'] or 'SCRIPT ERROR:' in r['text'] or 'ERROR:' in r['text']]
(BASE/'console-final.json').write_text(json.dumps({'console':console,'page_errors':errors},ensure_ascii=False,indent=2)+'\n')
browser_segments=[json.loads((BASE/n).read_text()) for n in ['radio_complete_reload-browser-before-reload.json','radio_complete_reopen-browser-before-reload.json','radio-boundary-final-browser.json']]
engine_segments=[json.loads((BASE/n).read_text())['inputs'] for n in ['radio_complete_reload-engine-before-reload.json','radio_complete_reopen-engine-before-reload.json','radio-boundary-final-fingerprints.json']]
assert all(r['isTrusted'] for seg in browser_segments for r in seg)
for label in ['initialize-radio-original-profile','produce-radio-natural','radio-whole-natural-1x','radio-whole-natural-2x','radio-credits-complete-reload-reopen']:
    receipt=json.loads((BASE/'receipts'/(label+'.json')).read_text());assert receipt['actual_exit']==0,label
proof={'status':'PASS','utc':utc(),'controller_pid':os.getpid(),'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','original_attempt':radio_record['attempt'],'original_record_sha256':radio_record['sha256'],'owned_pages':len(context.pages),'scene':state['scene'],'complete':True,'continue_disabled':True,'fixture_ready':False,'browser_trusted_segments':[len(s) for s in browser_segments],'engine_input_segments':[len(s) for s in engine_segments],'console_errors':0,'page_errors':0,'GL_invalid':0,'gpu_readpixels_warnings':len([r for r in console if 'ReadPixels' in r['text']]),'whole_1x_callback_wall':packet1['input_to_terminal_callback_wall'],'whole_2x_callback_wall':packet2['input_to_terminal_callback_wall'],'rate_wall_ratio':packet1['input_to_terminal_callback_wall']/packet2['input_to_terminal_callback_wall'],'scope':'original radio producer, same original record natural full whole1x/2x, actual credits scroll, exact full campaign saved reload/reopen, safe Title; browser END/pure native artifact audit separately required'}
(BASE/'radio-browser-final-proof.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print(json.dumps({'RADIO_BROWSER_PROOF':proof},ensure_ascii=False),flush=True)
