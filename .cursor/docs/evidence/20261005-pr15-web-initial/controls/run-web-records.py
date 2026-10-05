from pathlib import Path
from playwright.sync_api import sync_playwright
import json,datetime,hashlib,time,sys,traceback,argparse
p=argparse.ArgumentParser();p.add_argument('--levels',nargs='+',default=['yard']);p.add_argument('--whole',action='store_true');p.add_argument('--output',required=True);args=p.parse_args();out=Path(args.output);out.mkdir();base=Path('/tmp/pr15-web-controls');manifest=json.loads(Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261004-pr15-native-record3d/fixed-d9c-six-r/producer-manifest.json').read_text());records={x['level']:x for x in manifest['records']}
report={'source_sha':'843f55c3bc618706d1ddc7aa18d01223927233fc','fixture_sha256':hashlib.sha256((base/'web_qa_bridge-v2.gd').read_bytes()).hexdigest(),'producer_source':manifest['source_sha'],'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'External debug-stage bridge; original archived native records, actual browser full3D renderer and natural replay callbacks. Not new Web battles or normal player campaign wins. No device/GPU performance acceptance.','levels':[],'console':[],'page_errors':[],'checks':0,'failures':[]}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def verify(ok,label):
 report['checks']+=1
 if not ok:report['failures'].append(label);save();raise AssertionError(label)
with sync_playwright() as pw:
 try:
  browser=pw.chromium.connect_over_cdp('ws://127.0.0.1:45153/devtools/browser/2fe75df8-11af-437c-ae38-df82d05b1f7b');page=next(x for c in browser.contexts for x in c.pages if x.url.startswith('http://127.0.0.1:12787/'))
  page.on('console',lambda m:report['console'].append({'type':m.type,'text':m.text,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}));page.on('pageerror',lambda e:report['page_errors'].append(str(e)))
  def request(r):
   page.evaluate('(r)=>{window.pr15QAResult=null;window.pr15QA(JSON.stringify(r));}',r);page.wait_for_function("typeof window.pr15QAResult === 'string'",timeout=60000);return json.loads(page.evaluate('window.pr15QAResult'))
  def draw():page.evaluate("new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))")
  for level in args.levels:
   row=records[level];verify(hashlib.sha256(Path(row['path']).read_bytes()).hexdigest()==row['sha256'],level+' exact producer bytes before consumption')
   actual=page.evaluate("async level=>{const r=await fetch('/fixtures/'+level+'.bin');if(!r.ok)throw new Error('fixture HTTP '+r.status);const b=await r.arrayBuffer();const h=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',b)),v=>v.toString(16).padStart(2,'0')).join('');engine.copyToFS('/tmp/native-record.bin',new Uint8Array(b));return {bytes:b.byteLength,sha256:h};}",level)
   verify(actual['bytes']==row['bytes'] and actual['sha256']==row['sha256'],level+' browser consumed exact producer bytes')
   loaded=request({'action':'load_record','level':level});verify(loaded['attempt']==row['attempt'] and loaded['max_tick']==row['playback_terminal_tick'],level+' original identity/clock');entry={'level':level,'loaded':loaded,'seeks':[],'whole':[]};report['levels'].append(entry);save()
   for reverse in [False,True]:
    for s in list(reversed(loaded['selected'])) if reverse else loaded['selected']:
     result=request({'action':'seek','tick':s['tick']});report['checks']+=result['checks'];verify(not result['failures'],level+' saved frame fields/actual roots/20bones: '+str(result['failures']));entry['seeks'].append({'requested':s,'reverse':reverse,'result':result});draw()
     if not reverse:page.screenshot(path=str(out/f'{level}-wave{s["wave"]}-phase{s["phase"]}.png'))
     save()
   focus=request({'action':'focus','type':'fire'});entry['focus']=focus;verify(focus['focused'],level+' original fire event focus');draw();page.screenshot(path=str(out/(level+'-event-focus.png')));save()
   if args.whole:
    for rate in [1,2]:
     start=time.monotonic();request({'action':'whole','rate':rate});deadline=start+max(180,row['playback_terminal_tick']/60/rate*10+30);last_log=start
     while True:
      state=request({'action':'state'})
      if not state['monitor']:break
      verify(time.monotonic()<deadline,level+f' whole{rate}x deadline')
      if time.monotonic()-last_log>=20:print(json.dumps({'progress':level,'rate':rate,'tick':state['replay_tick'],'max':state['replay_max'],'wall_s':round(time.monotonic()-start,2)}),flush=True);last_log=time.monotonic()
      page.wait_for_timeout(1000)
     result=request({'action':'whole_result'});entry['whole'].append({'rate':rate,'result':result});save();verify(result['terminal_reached'],level+f' whole{rate}x original terminal');verify(result['source_unchanged'],level+f' whole{rate}x source unmodified');verify(result['live_sim_unchanged'],level+f' whole{rate}x live sim unmodified');verify(not result['rate_failures'],level+f' whole{rate}x callback rate: '+str(result['rate_failures'][:4]));verify(all(x['view_tick']==x['tick'] for x in result['rows']),level+f' whole{rate}x actual 3D frame matches clock');draw();page.screenshot(path=str(out/f'{level}-whole{rate}x-terminal.png'));save();print(json.dumps({'complete':level,'rate':rate,'natural_rows':len(result['rows']),'terminal':result['state']['replay_tick'],'source_unchanged':result['source_unchanged'],'observed_wall_s':result['rows'][-1]['us']/1e6 if result['rows'] else None}),flush=True)
   print(json.dumps({'level_complete':level,'seeks':len(entry['seeks']),'checks':report['checks']}),flush=True)
  verify(not report['page_errors'],'no browser JS errors in fixture epoch');verify(not [x for x in report['console'] if x['text'].startswith(('ERROR:','SCRIPT ERROR:'))],'no Godot runtime errors in fixture epoch');report['actual_exit']=0
 except Exception as e:
  report['actual_exit']=1;report['exception']={'type':type(e).__name__,'reason':str(e),'traceback':traceback.format_exc()};print(json.dumps({'actual_exit':1,'error':str(e)}),flush=True)
 finally:report['end']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
print(json.dumps({'actual_exit':report['actual_exit'],'checks':report['checks'],'failures':len(report['failures']),'report':str(out/'report.json')}),flush=True);sys.exit(report['actual_exit'])
