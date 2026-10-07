from pathlib import Path
import json,time,hashlib,datetime
ROOT=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
exec((ROOT/'driver_core.py').read_text(),globals())
d=Driver(page,BASE)
selection=json.loads((ROOT/'selected-window.json').read_text())
def save(name,value):
 data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
 with (BASE/name).open('xb') as f:f.write(data)
def fingerprint():
 fp=d.rpc('fingerprints');fp['settings']=d.state()['settings'];fp['public_checkpoint']=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 assert not fp['record_validation']['failures'] and not fp['frame_checks'].get('failures',[])
 return fp
def same(a,b):
 for key in ['record_sha256','domain','settings','public_checkpoint']:assert a[key]==b[key],key
def position():
 s=d.state();assert s['phase']==4
 if s['replay']['playing']:d.key('p')
 d.key('-')
 c=d.rpc('controls')['scrub'];x,y,w,h=c['rect'];point=d.coords([x+w/2,y+h/2]);page.mouse.click(*point);d.settle()
 s=d.state();assert s['replay']['tick']==selection['tick'] and not s['replay']['playing'] and s['replay']['speed']==1,s['replay']
 # Remove GUI focus to prevent keyboard transport being consumed by slider.
 page.mouse.click(*d.coords([630,25]));d.settle()
 s=d.state();assert s['replay']['tick']==selection['tick'] and not s['replay']['playing']
 return s
def phase(label,enabled,seconds=20,warm=2):
 receipt=d.rpc('meter_begin',label=label,enabled=enabled,seconds=seconds,warm=warm)
 # No RPC, screenshots, filesystem or prints while timer window is active.
 page.wait_for_timeout((seconds+warm+1)*1000)
 status=d.rpc('meter_status');assert status['done'] and not status['active'] and not status['overflow'],status
 out=d.rpc('meter_result');save(label+'-raw.json',out)
 cols=out['columns'];rows=[dict(zip(cols,x)) for x in out['rows']]
 assert len(rows)>=12 if seconds==20 else len(rows)>=3
 assert all(x['view_tick']==x['tick'] for x in rows)
 assert all(x['presenter_calls']>0 for x in rows)
 assert not out['overflow'] and len(out['posts'])>=12 if seconds==20 else len(out['posts'])>=3
 if not enabled:assert all(x['root_us']==x['presenter_us']==0 for x in rows)
 return out,rows
def run(label,enabled):
 begin=time.monotonic();save(label+'-start.json',{'utc':utc(),'monotonic':begin,'enabled':enabled,'cap_s':90})
 position();before=fingerprint();save(label+'-before-full.json',before)
 static0=d.rpc('canonical');save(label+'-static-canonical-before.json',static0)
 out,rows=phase(label+'-static',enabled)
 assert all(x['root_calls']==0 and x['playing']==0 and x['tick']==selection['tick'] for x in rows)
 static1=d.rpc('canonical');assert static1==static0
 save(label+'-static-canonical-after.json',static1)
 # Paused canonical screenshot is outside collection; keep cursor identical.
 page.mouse.move(15,15);page.screenshot(path=str(BASE/(label+'-static.png')))
 d.key('p');assert d.state()['replay']['playing']
 advance,rows=phase(label+'-advance',enabled)
 assert all(x['root_calls']>0 and x['playing']==1 and x['tick']<selection['terminal'] for x in rows)
 assert all(rows[i]['tick']<rows[i+1]['tick'] for i in range(len(rows)-1))
 assert len({x['tick'] for x in rows})>=12
 if enabled:assert all(x['root_us']>0 and x['presenter_us']>0 for x in rows)
 d.key('p');assert not d.state()['replay']['playing']
 endpoint=d.rpc('canonical');save(label+'-advance-endpoint-canonical.json',endpoint)
 assert not endpoint['checks']['failures'] and endpoint['recorded_phase']==selection['recorded_phase']
 after=fingerprint();same(before,after);save(label+'-after-full.json',after)
 elapsed=time.monotonic()-begin
 assert elapsed<=90,elapsed
 save(label+'-end.json',{'utc':utc(),'wall_s':elapsed,'actual_exit':0,'static_rows':len(out['rows']),'advance_rows':len(advance['rows']),'record_domain_settings_checkpoint_exact':True})
 print(json.dumps({'HUD_RUN_END':label,'enabled':enabled,'wall_s':elapsed,'static_rows':len(out['rows']),'advance_rows':len(advance['rows'])}),flush=True)
