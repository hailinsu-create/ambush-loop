from pathlib import Path
CONTROL_ROOT=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
exec((CONTROL_ROOT/'measurement_core.py').read_text(),globals())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'HUD paired yard WON ready',60)
assert len(context.pages)==1 and s['attempt']==selection['attempt']
d.click('replay');position()
before=fingerprint();save('p0-before-full.json',before)
canon0=d.rpc('canonical');save('p0-canonical-before.json',canon0)
page.mouse.move(15,15);page.screenshot(path=str(BASE/'p0-canonical-before.png'))
out,rows=phase('p0-positive-paused-negative',True,seconds=3,warm=0)
assert all(x['root_calls']==0 and x['root_us']==0 and x['presenter_us']>0 and x['tick']==selection['tick'] for x in rows)
canon1=d.rpc('canonical');assert canon1==canon0;save('p0-canonical-after.json',canon1)
page.screenshot(path=str(BASE/'p0-canonical-after.png'))
after=fingerprint();same(before,after);save('p0-after-full.json',after)
elapsed=time.monotonic()-json.loads((CONTROL_ROOT/'budget-start.json').read_text())['monotonic'];assert elapsed<=120,elapsed
gl=page.evaluate('''()=>{const c=document.createElement('canvas');const g=c.getContext('webgl2')||c.getContext('webgl');const e=g.getExtension('WEBGL_debug_renderer_info');return {vendor:e?g.getParameter(e.UNMASKED_VENDOR_WEBGL):g.getParameter(g.VENDOR),renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER),version:g.getParameter(g.VERSION)}}''')
save('p0-end.json',{'utc':utc(),'wall_from_budget_start_s':elapsed,'positive_presenter_samples':len(rows),'paused_root_calls':0,'buffer_fixed_capacity':out['capacity'],'reset_schema_passed':out['schema']==1,'canonical_exact':True,'full_fingerprints_exact':True,'webgl_identity':gl,'native_actual_guard':'selection-receipt.json; browser uses new isolated persistent profile, native XDG guard not falsely claimed as Web guard'})
print(json.dumps({'HUD_P0':'PASS','wall_s':elapsed,'samples':len(rows),'renderer':gl}),flush=True)
