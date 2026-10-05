from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json,sys,datetime,threading,traceback,os,time
BASE=Path('/tmp/pr15-web-controls/railcut-native-8532-20261005/run');BASE.mkdir(exist_ok=False)
PROFILE=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert PROFILE.is_dir()
EXPORT=Path('/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-cold-qa-v2-20261005')
URL='http://127.0.0.1:12815/index.html'
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT),**kw)
 def end_headers(self):self.send_header('Cache-Control','no-store');super().end_headers()
 def log_message(self,fmt,*args):
  with (BASE/'http.log').open('a') as f:f.write(datetime.datetime.now(datetime.timezone.utc).isoformat()+' '+fmt%args+'\n')
console=[];errors=[];server=None
try:
 with sync_playwright() as browser_owner:
  context=browser_owner.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
  owned=list(context.pages);before=[p.url for p in owned];assert all(x in [URL,'about:blank'] for x in before),before
  page=owned[0]
  for surplus in owned[1:]:surplus.close()
  page.goto('about:blank');assert len(context.pages)==1
  cdp=context.new_cdp_session(page);cdp.send('Network.enable');cdp.send('Network.setCacheDisabled',{'cacheDisabled':True})
  server=ThreadingHTTPServer(('127.0.0.1',12815),H);threading.Thread(target=server.serve_forever,daemon=True).start()
  (BASE/'owned-pages-startup.json').write_text(json.dumps({'pid':os.getpid(),'before':before,'after':[p.url for p in context.pages],'closed_surplus':len(owned)-1,'server_started_only_after_single_blank_page':True,'cache_disabled_keeps_existing_storage':True},indent=2)+'\n')
  page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'wall':time.monotonic()}));page.on('pageerror',lambda e:errors.append(str(e)))
  context.add_init_script("window.pr15TrustedInputs=[];for(const n of ['keydown','keyup','mousedown','mouseup','wheel','touchstart','touchend','touchcancel'])document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
  print(json.dumps({'RAILCUT_ENGINE_START':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','owned_pages':len(context.pages),'url':URL,'profile':str(PROFILE),'fixture':False,'browser':'existing Playwright1.62.0/Chromium'}),flush=True)
  for line in sys.stdin:
   request=json.loads(line);label=request['label'];assert '/' not in label
   receipt={'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':os.getpid(),'request':request}
   try:
    if request.get('close'):break
    exec(Path(request['script']).read_text(),globals());receipt['actual_exit']=0
   except Exception as error:receipt.update({'actual_exit':1,'exception':str(error),'traceback':traceback.format_exc()})
   receipt.update({'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'console':console[:],'page_errors':errors[:]})
   (BASE/(label+'.json')).write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
   print(json.dumps({'label':label,'actual_exit':receipt['actual_exit'],'exception':receipt.get('exception')}),flush=True)
  context.close()
finally:
 if server is not None:server.shutdown();server.server_close()
 print(json.dumps({'RAILCUT_ENGINE_END':datetime.datetime.now(datetime.timezone.utc).isoformat()}),flush=True)
