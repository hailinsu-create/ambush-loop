from pathlib import Path
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json,sys,datetime,threading,traceback,os,hashlib
ROOT=Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005')
BASE=ROOT/'reopen-proof';BASE.mkdir(exist_ok=False)
PROFILE=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005')
EXPORT=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/fresh-native-sync-qa-20261005')
URL='http://127.0.0.1:12815/index.html'
assert PROFILE.is_dir()
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT),**kw)
 def log_message(self,fmt,*args):
  with (BASE/'http.log').open('a') as f:f.write(datetime.datetime.now(datetime.timezone.utc).isoformat()+' '+fmt%args+'\n')
server=ThreadingHTTPServer(('127.0.0.1',12815),H);threading.Thread(target=server.serve_forever,daemon=True).start()
receipt={'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':os.getpid(),'scope':'finite original Title reload after completed whole/boundary; no new producer, original preserved profile/origin and cfg/public checkpoint exact comparison'}
console=[];errors=[];exit_code=1
try:
 with sync_playwright() as browser_owner:
  context=browser_owner.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
  owned=list(context.pages);before_urls=[p.url for p in owned];assert all(u in [URL,'about:blank'] for u in before_urls)
  page=owned[0]
  for surplus in owned[1:]:surplus.close()
  assert len(context.pages)==1
  receipt['owned_pages_before']=before_urls;receipt['owned_pages_after']=[p.url for p in context.pages]
  page.on('console',lambda m:console.append({'type':m.type,'text':m.text}))
  page.on('pageerror',lambda e:errors.append(str(e)))
  context.add_init_script("window.pr15TrustedInputs=[];for(const name of ['keydown','keyup','mousedown','mouseup','wheel'])document.addEventListener(name,e=>window.pr15TrustedInputs.push({name,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
  exec((ROOT/'driver_core.progressive.py').read_text(),globals())
  exec((ROOT/'driver_whole_and_progress.py').read_text(),globals())
  spec=json.loads((ROOT/'spec.json').read_text());d=Driver(page,BASE)
  prior=json.loads((ROOT/'run-single/warehouse_final_reopen-before-reload.json').read_text())
  page.goto(URL,wait_until='load');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
  assert page.title()=='Ambush Loop (DEBUG)'
  state=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'original preserved profile final Title reopened',120)
  assert_progress(state,spec['missions'][1]['expected_after_natural_win'])
  assert state['settings']['configs']==prior['state']['settings']['configs']
  for key in ['muted','music_volume','sfx_volume','force_touch_hud','quality','seen']:assert state['settings'][key]==prior['state']['settings'][key],key
  checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
  assert checkpoint and hashlib.sha256(checkpoint.encode()).hexdigest()==prior['public_checkpoint_sha256']
  assert json.loads(checkpoint)==prior['public_checkpoint']
  state=original_title_rows(d,spec['missions'][1]['expected_after_natural_win'],'warehouse_final_reopen')
  d.capture('warehouse_final_reopened_title')
  fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs');assert all(r['isTrusted'] for r in trusted)
  (BASE/'final-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
  (BASE/'final-browser-trusted.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
  (BASE/'warehouse-final-reopen-proof.json').write_text(json.dumps({'status':'PASS','state':state,'cfg_text_and_sha_exact':True,'public_checkpoint_exact':True,'checkpoint_sha256':prior['public_checkpoint_sha256'],'owned_pages':len(context.pages),'no_new_producer_or_attempt':True},ensure_ascii=False,indent=2)+'\n')
  assert not errors and not [m for m in console if m['type']=='error']
  context.close();exit_code=0
except Exception as e:receipt.update({'exception':str(e),'traceback':traceback.format_exc()})
finally:
 server.shutdown();server.server_close();receipt.update({'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':exit_code,'console':console,'page_errors':errors})
 (BASE/'receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'FINITE_ORIGINAL_REOPEN_END':True,'actual_exit':exit_code,'exception':receipt.get('exception'),'scope':receipt['scope']}),flush=True)
sys.exit(exit_code)
