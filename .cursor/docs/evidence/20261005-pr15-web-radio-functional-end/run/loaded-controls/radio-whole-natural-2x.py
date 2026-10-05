whole_helper_path=ROOT/'driver_whole_full_fingerprints.py'
whole_helper_loaded=whole_helper_path.read_bytes();assert hashlib.sha256(whole_helper_loaded).hexdigest()=='95037cda1161d0183753f379656871b4b05648cbeb31971b5af16f1d833292d1'
with (BASE/'loaded-controls'/'radio-whole-2x-helper.py').open('xb') as helper_copy:helper_copy.write(whole_helper_loaded)
exec(compile(whole_helper_loaded,str(whole_helper_path),'exec'),globals())
assert len(context.pages)==1 and page.url==URL
packet2=whole(d,radio_record,2)
post_won_fp=d.rpc('fingerprints');post_won_fp['state']=d.state()
(BASE/'radio-whole-2x-post-WON-full-fingerprint.json').write_text(json.dumps(post_won_fp,ensure_ascii=False,indent=2)+'\n')
