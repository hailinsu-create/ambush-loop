from pathlib import Path
CONTROL_ROOT=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
gate_start=time.monotonic()
helper=(CONTROL_ROOT/'measurement_core.py').read_bytes()
with (BASE/'loaded-controls'/'hud-p0-recovery-measurement-core.py').open('xb') as f:f.write(helper)
exec(compile(helper,str(CONTROL_ROOT/'measurement_core.py'),'exec'),globals())
previous=json.loads((BASE/'p0-positive-paused-negative-raw.json').read_text())
assert previous['enabled'] and previous['done'] and not previous['overflow']
prior_rows=[dict(zip(previous['columns'],x)) for x in previous['rows']]
assert len(prior_rows)>=3 and all(x['root_calls']==0 and x['presenter_us']>0 for x in prior_rows)
before=fingerprint();save('p0-recovery-before-full.json',before)
canonical=d.rpc('canonical');assert canonical==json.loads((BASE/'p0-canonical-before.json').read_text())
out,rows=phase('p0-recovery-OFF-reset',False,seconds=3,warm=0)
assert all(x['root_calls']==0 and x['root_us']==x['presenter_us']==0 and x['presenter_calls']>0 for x in rows)
assert d.rpc('canonical')==canonical
after=fingerprint();same(before,after);save('p0-recovery-after-full.json',after)
gl=page.evaluate('''()=>{const c=document.createElement('canvas');const g=c.getContext('webgl2')||c.getContext('webgl');const e=g.getExtension('WEBGL_debug_renderer_info');return {vendor:e?g.getParameter(e.UNMASKED_VENDOR_WEBGL):g.getParameter(g.VENDOR),renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER),version:g.getParameter(g.VERSION)}}''')
elapsed=time.monotonic()-gate_start;assert elapsed<=120
save('p0-recovery-end.json',{'utc':utc(),'wall_s':elapsed,'prior_ON_positive_samples':len(prior_rows),'OFF_reset_samples':len(rows),'canonical_exact':True,'full_fingerprints_exact':True,'webgl_identity':gl,'budget_not_reset':True,'original_p0_actual_exit':1,'original_p0_reason':'135.994285597s since overall budget start exceeded120; native+export+idle scheduling included; semantic checks passed but original gate not relabeled','scope':'bounded supplemental method gate before four runs; actual native Guard is selection receipt, Web uses new isolated persistent profile; buffer overflow runtime injection not performed'})
print(json.dumps({'HUD_P0_RECOVERY':'PASS','wall_s':elapsed,'renderer':gl}),flush=True)
