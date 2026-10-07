from pathlib import Path
ROOT=Path('/tmp/pr15-web-controls/yard-consumer-1ec-20261005')
exec((ROOT/'driver_core.py').read_text(),globals())
d=Driver(page,BASE)
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=120000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'paired yard original WON consumer ready',120)
record=json.loads((ROOT/'original-producer-meta.json').read_text())['record']
assert s['level']=='yard' and s['attempt']==record['attempt'] and s['log']['playback_terminal']==record['terminal'] and len(context.pages)==1
paired=json.loads((ROOT/'paired-original-settings.json').read_text());assert s['settings']['configs']==paired
assert s['settings']['next']=='warehouse' and [m['id'] for m in s['settings']['missions'] if m['cleared']]==['yard']
fp=d.rpc('fingerprints');assert fp['record_sha256']==record['sha256'] and not fp['record_validation']['failures']
fp['state']=s;fp['public_checkpoint']=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
(BASE/'initial-paired-WON-full-fingerprint.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
d.capture('yard_initial_paired_WON')
print(json.dumps({'YARD_CONSUMER_INITIAL':'PASS','producer_source':'dab870595175eed37a6d2a012bc69a76062d48b0','consumer_source':'1ec3198e9c0db367af96fc264604c5a286003b5e','fixture':True,'cfg_exact':True,'single_page':1,'record':record['sha256']}),flush=True)
