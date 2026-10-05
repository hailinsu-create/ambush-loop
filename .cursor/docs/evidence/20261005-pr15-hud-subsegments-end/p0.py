from pathlib import Path
CONTROL_ROOT=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
for helper_name in ['driver_core.py','measurement_core.py']:
 helper=(CONTROL_ROOT/helper_name).read_bytes()
 with (BASE/'loaded-controls'/('sub-P0-'+helper_name)).open('xb') as f:f.write(helper)
exec(compile((CONTROL_ROOT/'measurement_core.py').read_bytes(),str(CONTROL_ROOT/'measurement_core.py'),'exec'),globals())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'sub paired yard WON ready',60)
assert len(context.pages)==1 and s['attempt']==selection['attempt']
d.click('replay');position();before=fingerprint();save('p0-before-full.json',before)
canonical=d.rpc('canonical');save('p0-canonical.json',canonical)
static,rows=phase('p0-ON-static',True,seconds=2,warm=0)
assert all(x['root_calls']==x['capture_calls']==0 and x['presenter_us']>0 for x in rows)
d.key('p');advance,rows=phase('p0-ON-advance',True,seconds=3,warm=0)
assert all(x['hud_capture_calls']>0 and x['hud_capture_us']>0 and x['touch_calls']>0 and x['style_calls']>0 for x in rows)
save('p0-positive-counts.json',{'rows':len(rows),'capture_counts':sorted(set(x['capture_calls'] for x in rows)),'hud_capture_counts':sorted(set(x['hud_capture_calls'] for x in rows)),'touch_counts':sorted(set(x['touch_calls'] for x in rows)),'style_counts':sorted(set(x['style_calls'] for x in rows))})
d.key('p');position()
off,rows=phase('p0-OFF-reset',False,seconds=2,warm=0)
assert all(x['root_calls']==x['capture_calls']==0 and x['capture_us']==x['touch_us']==x['style_us']==0 and x['presenter_calls']>0 for x in rows)
assert d.rpc('canonical')==canonical
after=fingerprint();same(before,after);save('p0-after-full.json',after)
elapsed=time.monotonic()-json.loads((CONTROL_ROOT/'budget-start.json').read_text())['monotonic'];assert elapsed<=120,elapsed
gl=page.evaluate('''()=>{const c=document.createElement('canvas');const g=c.getContext('webgl2');const e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER),version:g.getParameter(g.VERSION)}}''')
save('p0-end.json',{'actual_exit':0,'wall_s':elapsed,'schema':off['schema'],'positive_negative_reset_neutrality':True,'renderer':gl,'original_prior_P0_timeout_kept':'44a034 evidence','OFF_ON_prior_mixed_overhead_kept':'44a034 evidence'})
print(json.dumps({'SUB_P0':'PASS','wall_s':elapsed,'renderer':gl}),flush=True)
