assert d.state()['phase']==3 and len(context.pages)==1 and not d.state()['fixture_ready']
packet1=whole(d,railcut_record,1)
fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert fp['record_sha256']==railcut_record['sha256'] and all(row['isTrusted'] for row in trusted)
(BASE/'railcut-whole-1x-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'railcut-whole-1x-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
assert not errors and not [row for row in console if row['type']=='error' or 'SCRIPT ERROR:' in row['text'] or 'GL_INVALID' in row['text'] or 'INVALID_OPERATION' in row['text']]
