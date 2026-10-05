d.key('Space');assert d.state()['phase']==3
fp=fingerprint();same(json.loads((BASE/'p0-before-full.json').read_text()),fp);save('post-WON-full-fingerprint.json',fp)
inputs=d.rpc('fingerprints')['inputs'];trusted=page.evaluate('window.pr15TrustedInputs')
save('final-input-proof.json',{'engine_inputs':inputs,'DOM_inputs':trusted,'DOM_all_isTrusted':all(x['isTrusted'] for x in trusted),'single_page':len(context.pages)==1,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors})
assert all(x['isTrusted'] for x in trusted) and not errors and not [x for x in console if x['type']=='error']
print(json.dumps({'HUD_FINAL_PROOF':'PASS','engine_inputs':len(inputs),'DOM_inputs':len(trusted)}),flush=True)
