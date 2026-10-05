assert d.state()['phase']==3 and yard_record['level']=='yard'
boundary(d,spec['missions'][0])
assert d.state()['level']=='warehouse' and d.state()['phase']==0 and all(o['weapon']=='knife' for o in d.state()['operators'])
seal_checkpoint(d,'warehouse_preview_continue_SCOUT')
# Preserve only campaign checkpoint; next producer starts via original Continue in next bounded packet.
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original next SCOUT -> Title',120)
seal_checkpoint(d,'yard_packet_final_Title')
fp=d.rpc('fingerprints');(BASE/'yard-input-fingerprints.json').write_text(json.dumps(fp,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs');assert trusted and all(x['isTrusted'] for x in trusted)
(BASE/'yard-current-context-trusted.json').write_text(json.dumps(trusted,indent=2)+'\n')
(BASE/'console-final.json').write_text(json.dumps({'console':console,'errors':errors},indent=2)+'\n')
emit('FIRST_PACKET_FUNCTION_END',status='PASS_NATURAL_YARD_CHECKPOINT',record=yard_record,whole='UNRUN_SEPARATE_CONSUMER',next_producer='NOT_STARTED')
