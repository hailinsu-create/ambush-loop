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
before=fingerprint();save('p0-before-full.json',before);canonical=d.rpc('canonical')
static,rows=phase('p0-OFF-static',False,seconds=2,warm=0)
assert all(x['root_calls']==x['capture_calls']==0 and x['presenter_calls']>0 for x in rows)
d.key('p');advance,rows=phase('p0-OFF-advance',False,seconds=3,warm=0)
assert all(x['capture_calls']==x['hud_capture_calls']==8 and x['touch_calls']==2 and x['style_calls']==50 and x['touch_capture_calls']==2 for x in rows)
save('p0-positive-counts.json',{'rows':len(rows),'capture_counts':sorted(set(x['capture_calls'] for x in rows)),'touch_counts':sorted(set(x['touch_calls'] for x in rows)),'style_counts':sorted(set(x['style_calls'] for x in rows)),'timers_common_OFF':True})
d.key('p');position();after=fingerprint();same(before,after);assert d.rpc('canonical')==canonical
elapsed=time.monotonic()-json.loads((CONTROL_ROOT/'budget-start.json').read_text())['monotonic'];assert elapsed<=120,elapsed
gl=page.evaluate("""()=>{const g=document.createElement('canvas').getContext('webgl2');const e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER),version:g.getParameter(g.VERSION)}}""")
save('p0-end.json',{'actual_exit':0,'wall_s':elapsed,'renderer':gl,'common_OFF_counter_positive_static_negative_and_fingerprint_neutral':True,'original_timeout_and_mixed_overhead_retained':True})
print(json.dumps({'ABBA_P0':'PASS','wall_s':elapsed,'renderer':gl}),flush=True)
run('run1-A',False)
d.key('Space');assert d.state()['phase']==3
fp=fingerprint();same(json.loads((BASE/'run1-A-before-full.json').read_text()),fp);save('post-WON-full-fingerprint.json',fp)
inputs=d.rpc('fingerprints')['inputs'];trusted=page.evaluate('window.pr15TrustedInputs')
save('final-input-proof.json',{'engine_inputs':inputs,'DOM_inputs':trusted,'DOM_all_isTrusted':all(x['isTrusted'] for x in trusted),'single_page':len(context.pages)==1,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors})
assert all(x['isTrusted'] for x in trusted) and not errors and not [x for x in console if x['type']=='error']
print(json.dumps({'ABBA_FINAL_PROOF':'run1-A','engine_inputs':len(inputs),'DOM_inputs':len(trusted)}),flush=True)
