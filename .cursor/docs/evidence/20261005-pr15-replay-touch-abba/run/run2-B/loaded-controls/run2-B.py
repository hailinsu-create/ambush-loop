from pathlib import Path
CONTROL_ROOT=Path('/tmp/pr15-web-controls/replay-touch-abba-95daa-20261005')
for helper_name in ['driver_core.py','measurement_core.py']:
 helper=(CONTROL_ROOT/helper_name).read_bytes()
 with (BASE/'loaded-controls'/helper_name).open('xb') as f:f.write(helper)
exec(compile((CONTROL_ROOT/'measurement_core.py').read_bytes(),str(CONTROL_ROOT/'measurement_core.py'),'exec'),globals())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'paired yard WON ready',60)
assert len(context.pages)==1 and s['attempt']==selection['attempt']
d.click('replay');position()
run('run2-B',False)
d.key('Space');assert d.state()['phase']==3
fp=fingerprint();same(json.loads((BASE/'run2-B-before-full.json').read_text()),fp);save('post-WON-full-fingerprint.json',fp)
inputs=d.rpc('fingerprints')['inputs'];trusted=page.evaluate('window.pr15TrustedInputs')
save('final-input-proof.json',{'engine_inputs':inputs,'DOM_inputs':trusted,'DOM_all_isTrusted':all(x['isTrusted'] for x in trusted),'single_page':len(context.pages)==1,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors})
assert all(x['isTrusted'] for x in trusted) and not errors and not [x for x in console if x['type']=='error']
print(json.dumps({'ABBA_FINAL_PROOF':'run2-B','engine_inputs':len(inputs),'DOM_inputs':len(trusted)}),flush=True)
