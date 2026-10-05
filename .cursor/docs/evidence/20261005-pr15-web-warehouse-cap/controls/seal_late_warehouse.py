d.producer_active=False
s=d.state();assert s['phase']==5 and s['wave']==1 and s['waves_cleared']==2
emit('WAREHOUSE_LATE_TERMINAL_START',scope='producer900 FAILED; original final SWEEP extraction solely to retain late original record, not budget PASS',attempt=s['attempt'])
d.click('alarm');s=d.state();assert s['phase']==3
late_warehouse_record=d.archive('warehouse-late-excluded');d.capture('warehouse_late_excluded_won')
f=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs');assert all(x['isTrusted'] for x in trusted)
(BASE/'warehouse-late-excluded-inputs.json').write_text(json.dumps({'engine':f['inputs'],'browser':trusted},indent=2)+'\n')
render=page.evaluate("""()=>{const gl=document.getElementById('canvas').getContext('webgl2');const e=gl.getExtension('WEBGL_debug_renderer_info');return {version:gl.getParameter(gl.VERSION),unmasked_renderer:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):null,unmasked_vendor:e?gl.getParameter(e.UNMASKED_VENDOR_WEBGL):null}}""")
(BASE/'renderer.json').write_text(json.dumps(render,indent=2)+'\n')
(BASE/'warehouse-late-excluded.json').write_text(json.dumps({'status':'FAIL_PRODUCER_WALL_CAP_LATE_ORIGINAL_WIN_EXCLUDED','record':late_warehouse_record,'state':s,'renderer':render},indent=2)+'\n')
emit('WAREHOUSE_LATE_TERMINAL_END',record=late_warehouse_record,renderer=render,accepted_producer=False)
