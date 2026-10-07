exec((ROOT/'driver_whole_full_fingerprints.py').read_text(),globals())
assert d.state()['phase']==3 and len(context.pages)==1 and not d.state()['fixture_ready']
packet2=whole(d,depot_record,2)
fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert fp['record_sha256']==depot_record['sha256'] and all(row['isTrusted'] for row in trusted)
(BASE/'depot-whole-2x-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'depot-whole-2x-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
assert not errors and not [row for row in console if row['type']=='error' or 'SCRIPT ERROR:' in row['text'] or 'GL_INVALID' in row['text'] or 'INVALID_OPERATION' in row['text']]
