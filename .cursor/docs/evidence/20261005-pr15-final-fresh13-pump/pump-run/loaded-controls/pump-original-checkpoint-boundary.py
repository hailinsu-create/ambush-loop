assert d.state()['phase']==3 and pump_record['level']=='pump'
won=d.state();saved_checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
assert_progress(won,plan['expected_after_natural_win'])
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
s=d.wait(lambda x:x['scene']=='res://scenes/title.tscn','original WON pause -> Title then user pause',120)
assert_progress(s,plan['expected_after_natural_win'])
assert s['settings']['configs']==won['settings']['configs']
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==saved_checkpoint
assert not s['settings']['seen'].get('railcut',False)
seal_checkpoint(d,'pump_packet_final_Title');d.capture('pump_paused_final_Title')
fp=d.rpc('fingerprints');(BASE/'pump-input-fingerprints.json').write_text(json.dumps(fp,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs');assert trusted and all(x['isTrusted'] for x in trusted)
(BASE/'pump-current-context-trusted.json').write_text(json.dumps(trusted,indent=2)+'\n')
(BASE/'console-final.json').write_text(json.dumps({'console':console,'errors':errors},indent=2)+'\n')
emit('PAUSED_CURRENT_PACKET_END',level='pump',status='PASS_NATURAL_PRODUCER_SAVED_TITLE_USER_PAUSE',record=pump_record,whole='UNRUN',next_level_started=False,reload='UNRUN_USER_PAUSE',native_audit='UNRUN_USER_PAUSE')
