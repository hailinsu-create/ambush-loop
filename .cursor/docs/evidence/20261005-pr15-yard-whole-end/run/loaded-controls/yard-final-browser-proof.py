assert len(context.pages)==1 and page.url==URL
final=d.rpc('fingerprints');final['state']=d.state();final['public_checkpoint']=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
initial=json.loads((BASE/'initial-paired-WON-full-fingerprint.json').read_text())
assert final['record_sha256']==record['sha256'] and final['state']['phase']==3
assert final['state']['settings']['configs']==initial['state']['settings']['configs'] and final['public_checkpoint']==initial['public_checkpoint']
assert not final['record_validation']['failures']
trusted=page.evaluate('window.pr15TrustedInputs');assert all(x['isTrusted'] for x in trusted);assert len(trusted)==len(final['inputs'])
assert not errors and not [c for c in console if c['type']=='error'],(errors,console)
assert not [c for c in console if 'SCRIPT ERROR:' in c['text'] or c['text'].startswith('ERROR:')]
final['trusted_inputs']=trusted
final['console']=console;final['page_errors']=errors
with (BASE/'final-browser-proof.json').open('x') as f:json.dump(final,f,ensure_ascii=False,indent=2)
print(json.dumps({'YARD_BROWSER_FINAL':'PASS','original_record_unchanged':True,'paired_cfg_checkpoint_exact':True,'browser_inputs':len(trusted),'engine_inputs':len(final['inputs']),'console_error':0,'page_error':0,'scope':'original cold paired yard consumer whole1/2; no new producer'}),flush=True)
