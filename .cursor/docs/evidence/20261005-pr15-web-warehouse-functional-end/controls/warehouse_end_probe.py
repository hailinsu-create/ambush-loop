assert len(context.pages)==1
s=d.state();assert s['level']=='pump' and s['phase']==0 and all(o['weapon']=='knife' for o in s['operators'])
assert_progress(s,spec['missions'][1]['expected_after_natural_win'])
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn','warehouse bounded package original pause -> Title',120)
assert_progress(s,spec['missions'][1]['expected_after_natural_win'])
reload_original(d,spec['missions'][1]['expected_after_natural_win'],'warehouse_final_reopen',True)
assert len(context.pages)==1
f=d.rpc('fingerprints')
trusted=page.evaluate('window.pr15TrustedInputs');assert all(r['isTrusted'] for r in trusted)
(BASE/'warehouse-final-input-trace.json').write_text(json.dumps(f['inputs'],indent=2)+'\n')
(BASE/'warehouse-final-trusted-inputs.json').write_text(json.dumps(trusted,indent=2)+'\n')
(BASE/'warehouse-end-state.json').write_text(json.dumps({'status':'BOUNDED_WAREHOUSE_FUNCTIONAL_END','state':d.state(),'owned_page_count':len(context.pages),'record_sha256':warehouse_record['sha256'],'whole1_wall':warehouse_whole_1['input_to_terminal_callback_wall'],'whole2_wall':warehouse_whole_2['input_to_terminal_callback_wall'],'scope':'original warehouse producer/whole1/whole2/event focus/next handoff/tutorial/Title rows/save/reload/reopen; no pump producer; realtime/frame budget unaccepted'},ensure_ascii=False,indent=2)+'\n')
emit('WAREHOUSE_BOUNDED_END_READY',scope='original Title after exact saved-cfg reload/reopen; ready owned close, no pump producer',next_level='pump',record_sha256=warehouse_record['sha256'])
