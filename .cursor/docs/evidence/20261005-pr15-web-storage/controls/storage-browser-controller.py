from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json,sys,datetime,threading,traceback,os,time
base=Path('/tmp/pr15-web-controls/storage-browser');base.mkdir(exist_ok=False)
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory='/workspace/pr15-storage-baseline-observer',**kw)
 def log_message(self,fmt,*args):
  with (base/'http.log').open('a') as f:f.write(datetime.datetime.now(datetime.timezone.utc).isoformat()+' '+fmt%args+'\n')
server=ThreadingHTTPServer(('127.0.0.1',12793),H);threading.Thread(target=server.serve_forever,daemon=True).start()
console=[];errors=[]
with sync_playwright() as pw:
 context=pw.chromium.launch_persistent_context('/workspace/.ambush-loop-env/web-browser-storage-20261005',executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
 page=context.pages[0];page.on('console',lambda m:console.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:errors.append(str(e)))
 print('STORAGE_BROWSER_READY owned profile/server, no shared browser',flush=True)
 for line in sys.stdin:
  r=json.loads(line);label=r['label'];assert '/' not in label
  receipt={'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':os.getpid(),'request':r}
  try:
   if r.get('close'):break
   exec(Path(r['script']).read_text(),globals());receipt['actual_exit']=0
  except Exception as e:receipt.update({'actual_exit':1,'exception':str(e),'traceback':traceback.format_exc()})
  receipt.update({'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'console':console[:],'page_errors':errors[:]});(base/(label+'.json')).write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'label':label,'actual_exit':receipt['actual_exit'],'exception':receipt.get('exception')}),flush=True)
 context.close()
server.shutdown();server.server_close();print('STORAGE_BROWSER_END',flush=True)
