from pathlib import Path
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json, sys, datetime, threading, traceback, os, time
BASE=Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/run');BASE.mkdir(exist_ok=False)
PROFILE=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert PROFILE.is_dir()
EXPORT=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/fresh-native-resume-qa-20261005')
URL='http://127.0.0.1:12815/index.html'
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT),**kw)
 def log_message(self,fmt,*args):
  with (BASE/'http.log').open('a') as f:f.write(datetime.datetime.now(datetime.timezone.utc).isoformat()+' '+fmt%args+'\n')
server=ThreadingHTTPServer(('127.0.0.1',12815),H);threading.Thread(target=server.serve_forever,daemon=True).start()
console=[];errors=[]
with sync_playwright() as pw:
 context=pw.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
 page=context.pages[0]
 page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'wall':time.monotonic()}))
 page.on('pageerror',lambda e:errors.append(str(e)))
 context.add_init_script("""window.pr15TrustedInputs=[]; for (const name of ['keydown','keyup','mousedown','mouseup','wheel']) document.addEventListener(name,e=>window.pr15TrustedInputs.push({name,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);""")
 print('RESUME_BROWSER_READY owned preserved profile/server; Browser plugin not available; Playwright 1.62.0',flush=True)
 for line in sys.stdin:
  r=json.loads(line);label=r['label'];assert '/' not in label
  receipt={'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':os.getpid(),'request':r}
  try:
   if r.get('close'):break
   exec(Path(r['script']).read_text(),globals());receipt['actual_exit']=0
  except Exception as e:receipt.update({'actual_exit':1,'exception':str(e),'traceback':traceback.format_exc()})
  receipt.update({'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'console':console[:],'page_errors':errors[:]})
  (BASE/(label+'.json')).write_text(json.dumps(receipt,indent=2)+'\n')
  print(json.dumps({'label':label,'actual_exit':receipt['actual_exit'],'exception':receipt.get('exception')}),flush=True)
 context.close()
server.shutdown();server.server_close();print('RESUME_BROWSER_END',flush=True)
