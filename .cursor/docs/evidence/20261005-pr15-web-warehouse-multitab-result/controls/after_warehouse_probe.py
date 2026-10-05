state=d.state();assert state['phase']==3
render=page.evaluate("""()=>{const gl=document.getElementById('canvas').getContext('webgl2');const e=gl.getExtension('WEBGL_debug_renderer_info');return {version:gl.getParameter(gl.VERSION),renderer:gl.getParameter(gl.RENDERER),vendor:gl.getParameter(gl.VENDOR),unmasked_renderer:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):null,unmasked_vendor:e?gl.getParameter(e.UNMASKED_VENDOR_WEBGL):null}}""")
f=d.rpc('fingerprints');assert f['record_sha256']==warehouse_record['sha256'] and not f['record_validation']['failures']
trusted=page.evaluate('window.pr15TrustedInputs');assert all(r['isTrusted'] for r in trusted)
(BASE/'warehouse-original-trusted-inputs.json').write_text(json.dumps(trusted,indent=2)+'\n')
(BASE/'warehouse-original-input-trace.json').write_text(json.dumps(f['inputs'],indent=2)+'\n')
(BASE/'warehouse-renderer.json').write_text(json.dumps(render,indent=2)+'\n')
print(json.dumps({'WAREHOUSE_POST_PRODUCER_READONLY':render,'trusted_inputs':len(trusted),'engine_inputs':len(f['inputs']),'record_unchanged':True}),flush=True)
