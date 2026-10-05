from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json,sys,datetime,threading,traceback,os,time,hashlib,signal
R=Path('/tmp/pr15-web-controls/replay-touch-abba-95daa-20261005');OUT=R/'run'
ART=Path('/workspace/pr15-web-artifacts/95daa05d0ccfc4e6bd357060b1f34c2a863c2041/touch-abba-qa-20261005')
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(path,value):
 blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode();path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(blob)
 return hashlib.sha256(blob).hexdigest()
def event(kind,**fields):
 value={'kind':kind,'utc':utc(),**fields}
 with (OUT/'controller-events.jsonl').open('a') as f:f.write(json.dumps(value,ensure_ascii=False)+'\n')
 print(json.dumps(value,ensure_ascii=False),flush=True)
budget=json.loads((R/'budget-start.json').read_text());remaining=600-(time.monotonic()-budget['monotonic']);assert remaining>0
def alarm(signum,frame):raise TimeoutError('ABBA overall600 cap reached')
signal.signal(signal.SIGALRM,alarm);signal.setitimer(signal.ITIMER_REAL,remaining)
OUT.mkdir(exist_ok=False);life={'window_start':utc(),'pid':os.getpid(),'contexts':[],'cap_s':600};clean=False
try:
 with sync_playwright() as owner:
  for number,side in [(1,'A'),(2,'B'),(3,'B'),(4,'A')]:
   label=f'run{number}-{side}';base=OUT/label;(base/'loaded-controls').mkdir(parents=True)
   profile=Path('/workspace/.ambush-loop-env/web-touch-abba-95daa-20261005-'+label);assert not profile.exists()
   export=ART/side;url='http://127.0.0.1:12815/index.html?fixture=yard'
   class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(export),**kw)
    def do_GET(self):
     if self.path=='/favicon.ico':self.path='/index.icon.png'
     return super().do_GET()
    def end_headers(self):self.send_header('Cache-Control','no-store');super().end_headers()
    def log_message(self,fmt,*args):
     with (base/'http.log').open('a') as f:f.write(utc()+' '+fmt%args+'\n')
   server=ThreadingHTTPServer(('127.0.0.1',12815),Handler);threading.Thread(target=server.serve_forever,daemon=True).start()
   context=None;packet={'label':label,'side':side,'start':utc(),'profile':str(profile),'export':str(export),'fresh_context':True};console=[];errors=[]
   save(OUT/'requests'/(label+'.json'),packet);event('REQUEST_START',**packet)
   try:
    context=owner.chromium.launch_persistent_context(str(profile),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
    pages=list(context.pages);assert all(p.url=='about:blank' for p in pages)
    page=pages[0]
    for extra in pages[1:]:extra.close()
    cdp=context.new_cdp_session(page);cdp.send('Network.enable');cdp.send('Network.setCacheDisabled',{'cacheDisabled':True})
    context.add_init_script("window.pr15TrustedInputs=[];for(const n of ['keydown','keyup','mousedown','mouseup','wheel','touchstart','touchend','touchcancel'])document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
    page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'wall':time.monotonic()}));page.on('pageerror',lambda e:errors.append(str(e)))
    script=R/(label+'.py');loaded=script.read_bytes();(base/'loaded-controls'/(label+'.py')).write_bytes(loaded);packet['loaded_script_sha256']=hashlib.sha256(loaded).hexdigest()
    env={'__builtins__':__builtins__,'context':context,'page':page,'cdp':cdp,'console':console,'errors':errors,'BASE':base,'PROFILE':profile,'EXPORT':export,'URL':url,'os':os}
    exec(compile(loaded,str(script),'exec'),env);packet['actual_exit']=0
   except Exception as e:packet.update(actual_exit=1,exception=str(e),traceback=traceback.format_exc())
   finally:
    if context:context.close()
    server.shutdown();server.server_close();packet.update(end=utc(),console=console,page_errors=errors,clean_context_end=context is not None)
    digest=save(OUT/'receipts'/(label+'.json'),packet);save(OUT/'receipt-vault'/(label+'.json'),packet);save(OUT/'receipt-vault'/(label+'.seal.json'),{'sha256':digest,'scope':'original exclusive-created immediate copy'})
    life['contexts'].append({k:packet[k] for k in ['label','start','end','actual_exit','profile','clean_context_end']});event('REQUEST_END',label=label,actual_exit=packet['actual_exit'],exception=packet.get('exception'))
   assert packet['actual_exit']==0 and not errors
 clean=True
finally:
 signal.setitimer(signal.ITIMER_REAL,0);life.update(engine_end=utc(),clean_context_end=clean,total_budget_wall_s=time.monotonic()-budget['monotonic']);save(OUT/'engine-window-lifecycle.json',life);event('ABBA_ENGINE_END',**life)
