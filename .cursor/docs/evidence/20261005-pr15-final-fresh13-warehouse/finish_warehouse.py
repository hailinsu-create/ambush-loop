assert d.state()['phase']==3 and warehouse_record['level']=='warehouse'
boundary(d,plan)
if plan['next_level'] is not None:
 assert d.state()['level']==plan['next_level'] and d.state()['phase']==0 and all(o['weapon']=='knife' for o in d.state()['operators'])
 seal_checkpoint(d,'warehouse_next_preview_continue_SCOUT')
 d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
 d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original next SCOUT -> Title',120)
seal_checkpoint(d,'warehouse_packet_final_Title')
fp=d.rpc('fingerprints');(BASE/'warehouse-input-fingerprints.json').write_text(json.dumps(fp,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs');assert trusted and all(x['isTrusted'] for x in trusted)
(BASE/'warehouse-current-context-trusted.json').write_text(json.dumps(trusted,indent=2)+'\n')
(BASE/'console-final.json').write_text(json.dumps({'console':console,'errors':errors},indent=2)+'\n')
emit('NEXT_PACKET_FUNCTION_END',level='warehouse',status='PASS_NATURAL_PRODUCER_CHECKPOINT',record=warehouse_record,whole='UNRUN',next_producer='NOT_STARTED')
