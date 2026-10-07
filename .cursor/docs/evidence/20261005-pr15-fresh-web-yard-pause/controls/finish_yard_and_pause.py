# User stop: do not enter warehouse or start whole/new QA. Finish the live yard packet only.
exec(Path('/tmp/pr15-web-controls/fresh-native-dab-20261005/driver_whole_and_progress.py').read_text(),globals())
assert d.state()['phase']==3 and yard_record['level']=='yard'
expected=spec['missions'][0]['expected_after_natural_win']
assert_progress(d.state(),expected)
d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original yard WON -> Title',120)
original_title_rows(d,expected,'yard_stop_cleared')
observations=d.rpc('fingerprints')
(BASE/'yard-original-input-trace.json').write_text(json.dumps(observations,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs')
assert all(x['isTrusted'] for x in trusted)
(BASE/'yard-original-trusted-inputs.json').write_text(json.dumps(trusted,indent=2)+'\n')
reload_original(d,expected,'yard_stop_reload')
reload_original(d,expected,'yard_stop_reopen',True)
observations=d.rpc('fingerprints')
(BASE/'yard-final-title-input-trace.json').write_text(json.dumps(observations,indent=2)+'\n')
trusted=page.evaluate('window.pr15TrustedInputs')
assert all(x['isTrusted'] for x in trusted)
(BASE/'yard-stop-trusted-title-inputs.json').write_text(json.dumps(trusted,indent=2)+'\n')
s=d.capture('yard_stop_final_title')
assert s['scene']=='res://scenes/title.tscn' and s['settings']['next']=='warehouse'
emit('LEVEL_END',level='yard',status='PASS_PRODUCER_UNLOCK_RELOAD',record=yard_record,whole_1x='UNRUN_USER_STOP',whole_2x='UNRUN_USER_STOP',next_level_started=False)
emit('CAMPAIGN_PAUSE',reason='explicit user stop after currently started yard bounded packet',remaining_levels=[x['level'] for x in spec['missions'][1:]],state=s)
