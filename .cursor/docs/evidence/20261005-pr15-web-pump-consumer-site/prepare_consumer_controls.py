from pathlib import Path
BASE=Path('/tmp/pr15-web-controls/pump-native-8532-20261005')
text=(BASE/'browser_controller.py').read_text().replace("BASE=Path('/tmp/pr15-web-controls/pump-native-8532-20261005/run')","BASE=Path('/tmp/pr15-web-controls/pump-native-8532-20261005/consumer-run')")
text=text.replace("PROFILE=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert PROFILE.is_dir()","PROFILE=Path('/workspace/.ambush-loop-env/web-pump-cold-consumer-20261005');assert not PROFILE.exists()")
text=text.replace('event-log-cold-qa-v2-20261005','pump-cold-consumer-20261005').replace('http://127.0.0.1:12815/index.html','http://127.0.0.1:12816/index.html?fixture=pump').replace("('127.0.0.1',12815)","('127.0.0.1',12816)")
text=text.replace('PUMP_SINGLE_BROWSER_READY source8532 preserved profile/origin no fixture query; Browser plugin not available; Playwright1.62.0','PUMP_COLD_CONSUMER_READY source8532 originalrecord-a0e5 disposable profile queryfixturepump; Browser plugin not available; Playwright1.62.0').replace('PUMP_SINGLE_BROWSER_END','PUMP_COLD_CONSUMER_END')
(BASE/'consumer_controller.py').write_text(text)
text='''from pathlib import Path
import json,hashlib,time
ROOT=Path('/tmp/pr15-web-controls/pump-native-8532-20261005')
exec((ROOT/'driver_core.py').read_text(),globals())
exec((ROOT/'driver_whole_and_progress.py').read_text(),globals())
d=Driver(page,BASE)
record=json.loads((ROOT/'run/pump-producer.json').read_text())['record']
assert record['sha256']=='a0e5b232a001671ead8156e97e29f902796f81cd7669d925d66045064d5709cf'
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=120000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'one-time isolated pump history ready',120)
assert s['level']=='pump' and s['attempt']==record['attempt'] and len(context.pages)==1
fp=d.rpc('fingerprints');assert fp['record_sha256']==record['sha256'] and not fp['record_validation']['failures']
(BASE/'consumer-start.json').write_text(json.dumps({'state':s,'record_sha256':fp['record_sha256'],'declared_cold_setup':True,'fresh_victory':False,'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','profile':str(PROFILE),'url':URL,'campaign_profile_not_used':True},ensure_ascii=False,indent=2)+'\\n')
print('PUMP_COLD_READY archived original source record; original Replay click pending',flush=True)
'''
(BASE/'consumer_initialize.py').write_text(text)
for rate in [1,2]:
 text=f'''packet{rate}=whole(d,record,{rate})
fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert len(context.pages)==1 and all(row['isTrusted'] for row in trusted)
(BASE/'pump-whole-{rate}x-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\\n')
(BASE/'pump-whole-{rate}x-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\\n')
assert not errors and not any(row['type']=='error' for row in console),(errors,[row for row in console if row['type']=='error'])
'''
 (BASE/f'consumer_whole_{rate}x.py').write_text(text)
print('consumer controls prepared; no engine launched')
