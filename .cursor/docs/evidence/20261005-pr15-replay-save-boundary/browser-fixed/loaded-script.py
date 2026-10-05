from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import os,json,datetime,time,threading,traceback,hashlib,socket,subprocess
ROOT=Path('/tmp/pr15-web-controls/replay-save-classification-20261005')
BASE=ROOT/'browser-fixed';BASE.mkdir(exist_ok=False)
EXPORT=Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/event-log-cold-qa-v2-20261005')
PROFILE=BASE/'owned-profile';URL='http://127.0.0.1:12817/index.html?fixture=warehouse&tick=10788&scale=1&touch=0'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(n,obj):
 blob=(json.dumps(obj,ensure_ascii=False,indent=2)+'\n').encode()
 with (BASE/n).open('xb') as f:f.write(blob)
 return hashlib.sha256(blob).hexdigest()
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT),**kw)
 def end_headers(self):self.send_header('Cache-Control','no-store');super().end_headers()
 def log_message(self,fmt,*args):
  with (BASE/'http.log').open('a') as f:f.write(now()+' '+fmt%args+'\n')
receipt={'start':now(),'pid':os.getpid(),'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','url':URL,'profile':str(PROFILE),'browser':'Chromium/Playwright, Browser plugin not available','scope':'declared cold warehouse setup; first Space settlement classified separately; thereafter original trusted replay/M/pause Title route, no original activity profile'}
save('request.json',receipt);(BASE/'loaded-script.py').write_bytes(Path(__file__).read_bytes())
console=[];errors=[];server=None;ctx=None;owner=None;actual=1;states={}
try:
 for port in [12815,12816,12817]:
  s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
 active=[x for x in subprocess.check_output(['ps','-eo','stat,comm,args'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])];assert not active,active
 owner=sync_playwright().start()
 if True:
  ctx=owner.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
  assert len(ctx.pages)==1;page=ctx.pages[0];page.goto('about:blank')
  server=ThreadingHTTPServer(('127.0.0.1',12817),H);threading.Thread(target=server.serve_forever,daemon=True).start()
  page.on('console',lambda m:console.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:errors.append(str(e)))
  ctx.add_init_script("window.pr15TrustedInputs=[];for(const n of ['keydown','keyup','mousedown','mouseup','wheel'])document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
  exec(Path('/tmp/pr15-web-controls/depot-native-8532-20261005/driver_core.py').read_text(),globals());d=Driver(page,BASE)
  page.goto(URL,wait_until='domcontentloaded',timeout=120000);page.wait_for_function('typeof window.pr15Observer==="function"',timeout=120000)
  states['cold']=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==4,'cold warehouse history setup',120);assert page.url==URL and 'Ambush' in page.title()
  d.capture('cold_history_before_first_space');cold_checkpoint=page.evaluate("localStorage.getItem('ambush-loop.config.v1')");save('cold-before.json',{'state':states['cold'],'checkpoint':cold_checkpoint})
  d.key('Space');states['settled']=d.wait(lambda x:x.get('phase')==3,'first original WON settlement',120);assert states['settled']['settings']['next']=='pump'
  save('settled-original-WON.json',{'state':states['settled'],'checkpoint':page.evaluate("localStorage.getItem('ambush-loop.config.v1')")});d.capture('settled_WON_before_history')
  d.click('replay');states['replay']=d.wait(lambda x:x.get('phase')==4,'original replay after settled WON',120)
  before_M=d.state();d.key('m');states['mute']=d.state();assert states['mute']['phase']==4 and states['mute']['settings']['next']=='pump'
  assert before_M['settings']['missions']==states['mute']['settings']['missions'] and before_M['settings']['complete']==states['mute']['settings']['complete'];assert before_M['settings']['muted']!=states['mute']['settings']['muted'];d.capture('replay_M_preserved_pointer');save('after-M.json',{'state':states['mute'],'checkpoint':page.evaluate("localStorage.getItem('ambush-loop.config.v1')")})
  d.key('Escape');assert d.state()['modal']['pause'];d.capture('original_settings_before_title');d.click('pause_title')
  states['title']=d.wait(lambda x:x['scene']=='res://scenes/title.tscn','original Title after M',120);assert states['title']['settings']['next']=='pump';d.capture('Title_correct_continue_pointer')
  save('original-Title-after-M.json',{'state':states['title'],'checkpoint':page.evaluate("localStorage.getItem('ambush-loop.config.v1')")})
  d.click('title_continue');states['correct_continue']=d.wait(lambda x:x.get('level')=='pump' and x.get('phase')==0,'original Continue actually enters correct pump',120);d.tutorial();d.capture('Continue_correct_pump_SCOUT')
  d.key('Escape');d.click('pause_title');states['final']=d.wait(lambda x:x['scene']=='res://scenes/title.tscn','safe isolated Title END',120)
  inputs=page.evaluate('window.pr15TrustedInputs');save('trusted-inputs.json',inputs);assert inputs and all(i['isTrusted'] for i in inputs);assert not errors and not any(x['type']=='error' for x in console)
  save('result.json',{'status':'PASS_FIXED_WON_REPLAY_M_CONTINUE','states':states,'console':console,'page_errors':errors,'trusted_input_count':len(inputs),'first_cold_Space_scope':'unsettled fixture victory side effect, not itself product bug','ordinary_route':'settled WON → original Replay → M → original settings → Title → original Continue pump','no_fresh_producer':True});actual=0
except BaseException as ex:receipt.update({'exception':str(ex),'traceback':traceback.format_exc()})
finally:
 if ctx is not None:ctx.close()
 if owner is not None:owner.stop()
 if server is not None:server.shutdown();server.server_close()
 receipt.update({'end':now(),'actual_exit':actual,'console':console,'page_errors':errors,'browser_closed':ctx is not None,'server_closed':server is not None})
 h=save('receipt.json',receipt);save('receipt-vault.json',receipt);print(json.dumps({'actual_exit':actual,'sha256':h,'receipt':receipt,'states':{k:(v.get('phase'),v['settings']['next']) for k,v in states.items()}},ensure_ascii=False),flush=True)
raise SystemExit(actual)
