from pathlib import Path
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import json,sys,datetime,threading,traceback,os,time,hashlib
CONTROL_ROOT=Path('/tmp/pr15-final-fresh13-1ec-20261005')
OUT=CONTROL_ROOT/'warehouse-run'
PROFILE_ROOT=Path('/workspace/.ambush-loop-env/web-final-fresh13-1ec-20261005')
EXPORT_ROOT=Path('/workspace/pr15-web-artifacts/b74f1fc2f190f574cd0c31aba04e495829337214/final-fresh13-qa-aligned-v2-20261005')
ORIGIN_URL='http://127.0.0.1:12915/index.html'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def exclusive(path, data):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(data)
def controller_emit(kind, **fields):
 row={'kind':kind,'utc':now(),**fields}
 with (OUT/'controller-events.jsonl').open('a') as f:f.write(json.dumps(row,ensure_ascii=False)+'\n')
 print(json.dumps(row,ensure_ascii=False),flush=True)
def persist_receipt(request_label, packet):
 data=(json.dumps(packet,ensure_ascii=False,indent=2)+'\n').encode()
 exclusive(OUT/'receipts'/(request_label+'.json'),data)
 exclusive(OUT/'receipt-vault'/(request_label+'.json'),data)
 exclusive(OUT/'receipt-vault'/(request_label+'.seal.json'),(json.dumps({'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'receipt':'receipts/'+request_label+'.json','scope':'original request receipt copied and hashed immediately; exclusive-create; never backfilled'},indent=2)+'\n').encode())
 controller_emit('REQUEST_END',label=request_label,actual_exit=packet['actual_exit'],exception=packet.get('exception'),receipt_sha256=hashlib.sha256(data).hexdigest())
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT_ROOT),**kw)
 def end_headers(self):self.send_header('Cache-Control','no-store');super().end_headers()
 def log_message(self,fmt,*args):
  with (OUT/'http.log').open('a') as f:f.write(now()+' '+fmt%args+'\n')
def main():
 OUT.mkdir(exist_ok=False);console_rows=[];page_errors=[];http_server=None;runtime={};close_request=None;clean_end=False
 def start_owned_http():
  nonlocal http_server
  assert http_server is None
  http_server=ThreadingHTTPServer(('127.0.0.1',12915),Handler);threading.Thread(target=http_server.serve_forever,daemon=True).start()
 def stop_owned_http():
  nonlocal http_server
  if http_server is not None:http_server.shutdown();http_server.server_close();http_server=None
 lifecycle={'window_start':now(),'source':'b74f1fc2f190f574cd0c31aba04e495829337214','pid':os.getpid(),'profile':str(PROFILE_ROOT),'url':ORIGIN_URL}
 controller_emit('FINAL_FRESH_WINDOW_START',**lifecycle)
 try:
  with sync_playwright() as owner:
   owned_context=owner.chromium.launch_persistent_context(str(PROFILE_ROOT),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
   owned_pages=list(owned_context.pages);before=[p.url for p in owned_pages];assert all(x in [ORIGIN_URL,'about:blank','chrome-error://chromewebdata/'] for x in before),before
   owned_page=owned_pages[0]
   for surplus in owned_pages[1:]:surplus.close()
   owned_page.goto('about:blank');assert len(owned_context.pages)==1
   owned_cdp=owned_context.new_cdp_session(owned_page);owned_cdp.send('Network.enable');owned_cdp.send('Network.setCacheDisabled',{'cacheDisabled':True})
   start_owned_http()
   exclusive(OUT/'owned-pages-startup.json',(json.dumps({'before':before,'after':[p.url for p in owned_context.pages],'closed_surplus':len(owned_pages)-1,'single_blank_before_server':True,'storage_preserved':True},indent=2)+'\n').encode())
   owned_page.on('console',lambda m:console_rows.append({'type':m.type,'text':m.text,'wall':time.monotonic()}));owned_page.on('pageerror',lambda e:page_errors.append(str(e)))
   owned_context.add_init_script("window.pr15TrustedInputs=[];for(const n of ['keydown','keyup','mousedown','mouseup','wheel','touchstart','touchend','touchcancel'])document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
   runtime={'__builtins__':__builtins__,'browser_owner':owner,'context':owned_context,'page':owned_page,'cdp':owned_cdp,'console':console_rows,'errors':page_errors,'BASE':OUT,'PROFILE':PROFILE_ROOT,'EXPORT':EXPORT_ROOT,'URL':ORIGIN_URL,'os':os,'start_owned_http':start_owned_http,'stop_owned_http':stop_owned_http}
   lifecycle['engine_start']=now();controller_emit('FINAL_FRESH_ENGINE_START',owned_pages=1,fixture=False,url=ORIGIN_URL)
   for line in sys.stdin:
    incoming=json.loads(line);request_label=incoming['label'];assert request_label and all(c.isalnum() or c in '-_' for c in request_label)
    assert not (OUT/'receipts'/(request_label+'.json')).exists() and not (OUT/'requests'/(request_label+'.json')).exists(), 'duplicate request label'
    request_receipt={'start':now(),'pid':os.getpid(),'request':incoming}
    exclusive(OUT/'requests'/(request_label+'.json'),(json.dumps(request_receipt,indent=2)+'\n').encode())
    if incoming.get('close'):close_request=(request_label,request_receipt);break
    script_path=Path(incoming['script']);assert script_path.parent==CONTROL_ROOT
    loaded=script_path.read_bytes();exclusive(OUT/'loaded-controls'/(request_label+'.py'),loaded);request_receipt['loaded_script_sha256']=hashlib.sha256(loaded).hexdigest()
    controller_emit('REQUEST_START',label=request_label,loaded_script_sha256=request_receipt['loaded_script_sha256'])
    try:
     exec(compile(loaded,str(script_path),'exec'),runtime);request_receipt['actual_exit']=0
    except Exception as problem:
     request_receipt.update({'actual_exit':1,'exception':str(problem),'traceback':traceback.format_exc()})
    request_receipt.update({'end':now(),'console':console_rows[:],'page_errors':page_errors[:]});persist_receipt(request_label,request_receipt)
   runtime['context'].close();clean_end=True
 finally:
  if http_server is not None:http_server.shutdown();http_server.server_close()
  lifecycle.update({'engine_end':now(),'clean_context_end':clean_end,'scope':'owned single persistent page/controller/server; actual PTY exit separately recorded'})
  exclusive(OUT/'engine-window-lifecycle.json',(json.dumps(lifecycle,indent=2)+'\n').encode());controller_emit('FINAL_FRESH_ENGINE_END',**lifecycle)
  if close_request:
   close_label,close_packet=close_request;close_packet.update({'actual_exit':0 if clean_end else 1,'end':lifecycle['engine_end'],'console':console_rows[:],'page_errors':page_errors[:]});persist_receipt(close_label,close_packet)
if __name__=='__main__':main()
