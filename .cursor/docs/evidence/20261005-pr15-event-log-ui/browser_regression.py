from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
import os,time,datetime,json,threading,traceback,hashlib,subprocess
BASE=Path('/tmp/pr15-web-controls/event-log-ui-20261005'); RUN=BASE/'browser-v2';RUN.mkdir()
SOURCE=json.loads((BASE/'qa-v2-export.json').read_text())['source'];EXPORT=Path('/workspace/pr15-web-artifacts')/SOURCE/'event-log-cold-qa-v2-20261005'
SHA='28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266'
PORT=12826
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*a,**kw):super().__init__(*a,directory=str(EXPORT),**kw)
 def log_message(self,fmt,*args):
  with (RUN/'http.log').open('a') as f:f.write(fmt%args+'\n')
server=ThreadingHTTPServer(('127.0.0.1',PORT),Handler);threading.Thread(target=server.serve_forever,daemon=True).start()
rows=[];checks=0;console=[];errors=[];start=time.monotonic();actual=1

def save(name,data):
 (RUN/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def log(label,**row):
 item={'label':label,'wall':time.monotonic()-start,**row};rows.append(item)
 with (RUN/'actions.jsonl').open('a') as f:f.write(json.dumps(item,ensure_ascii=False)+'\n')
 print(json.dumps({'label':label,'wall':item['wall']},ensure_ascii=False),flush=True)
def check(value,label):
 global checks
 checks+=1
 if not value:raise AssertionError(label)
class UI:
 def __init__(self,page,case):self.page=page;self.case=case;self.seq=0;self.cdp=page.context.new_cdp_session(page)
 def rpc(self,action):
  self.seq+=1;r={'id':self.seq,'action':action}
  value=self.page.evaluate('r=>{window.pr15Observer(JSON.stringify(r));return JSON.parse(window.pr15ObserverReply)}',r)
  check(value['id']==self.seq,'synchronous readonly response exact id');return value['value']
 def state(self):return self.rpc('state')
 def settle(self):
  first=self.state()['presents'];t=time.monotonic()
  while time.monotonic()-t<120:
   s=self.state()
   if s['presents']>=first+2:return s
   self.page.wait_for_timeout(100)
  raise TimeoutError('two original rendered frames cap120')
 def css(self,point):
  s=self.state();tr=s['screen_transform'];win=s['window_size'];c=self.page.locator('#canvas').bounding_box()
  x=tr[0][0]*point[0]+tr[1][0]*point[1]+tr[2][0];y=tr[0][1]*point[0]+tr[1][1]*point[1]+tr[2][1]
  return c['x']+x*c['width']/win[0],c['y']+y*c['height']/win[1]
 def click(self,point,touch=False):
  at=self.css(point)
  if touch:
   self.cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':at[0],'y':at[1],'id':7}]})
   self.cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
  else:self.page.mouse.click(*at)
  return self.settle()
 def control(self,key,touch=False):
  c=self.rpc('controls')[key];check(c['visible'] and not c['disabled'],key+' original visible enabled');x,y,w,h=c['rect'];return self.click([x+w/2,y+h/2],touch)
 def geometry(self):
  s=self.state();cs=self.rpc('controls');a=cs['event_list']['rect'];b=cs['camera_panel']['rect'];v=s['viewport']
  check(cs['event_list']['visible'] and cs['camera_panel']['visible'],'both panels visible')
  check(a[0]>=v[0] and a[1]>=v[1] and a[0]+a[2]<=v[0]+v[2]+.5 and a[1]+a[3]<=v[1]+v[3]+.5,'whole log fits usable viewport')
  check(a[0]+a[2]<=b[0] or b[0]+b[2]<=a[0] or a[1]+a[3]<=b[1] or b[1]+b[3]<=a[1],'log and camera disjoint')
  log(self.case+' geometry',state=s,controls=cs)
 def seek(self,ratio):
  c=self.rpc('controls')['scrub'];check(c['visible'] and not c['disabled'],'actual visible original slider');x,y,w,h=c['rect'];before=self.state();self.click([x+10+(w-20)*ratio,y+h/2]);s=self.state();log(self.case+' actual original slider',control=c,ratio=ratio,before=before,after=s);check(not s['replay']['playing'],'original slider pauses');return s
 def fire(self,wave):
  for turn in range(16):
   cs=self.rpc('controls');fire=[c for k,c in cs.items() if k.startswith('event_row:') and c['event']['type']=='fire' and c['event']['wave_id']==wave]
   check(bool(fire),'historical fire exists for expected wave')
   for c in fire:
    if c['visible']:return c
   area=cs['event_list']['rect'];target=fire[-1];y=target['rect'][1]+target['rect'][3]/2
   self.page.mouse.move(*self.css([area[0]+area[2]/2,area[1]+area[3]/2]));self.page.mouse.wheel(0,-40 if y<area[1] else 40);self.settle()
  raise TimeoutError('original list wheel reveal bounded16')
 def focus(self,wave,fraction,touch=False):
  c=self.fire(wave);point=c['fractions'][fraction];before=self.state();after=self.click(point,touch)
  check(after['replay']['tick']==c['event']['playback_tick'] and not after['replay']['playing'],'actual glyph point seeks exact historical event')
  check(after['focus_actor']==c['event']['actor_id'] and after['focus_type']=='fire' and after['event_ring_visible'],'actual glyph point focuses original actor3D ring')
  check(after['view']['yaw']==before['view']['yaw'] and after['view']['pitch']==before['view']['pitch'],'glyph input never rotates camera')
  check(after['view']['wave']==wave and after['view']['attempt']==c['event']['attempt_id'],'focus original wave/attempt')
  check(after['gui_hover'].endswith('/EventList') or touch,'real mouse hover reaches ItemList')
  check(after['view']['gesture']['contacts']==0 and after['view']['gesture']['pending_id']==-1,'touch release leaves no pending world input')
  log(self.case+' original glyph focus',touch=touch,fraction=fraction,event=c['event'],text=c['text'],glyph_width=c['text_width'],point=point,css=self.css(point),before=before,after=after)
 def capture(self,label):
  self.settle();p=RUN/(self.case+'_'+label+'.png');self.page.screenshot(path=str(p));log(self.case+' capture '+label,path=p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),state=self.state())

try:
 with sync_playwright() as pw:
  browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
  for case,viewport,scale,touch,mobile in [('desktop',{'width':1280,'height':720},1,False,False),('scale200',{'width':1280,'height':720},2,True,False),('phone_landscape',{'width':915,'height':412},2,True,True)]:
   ctx=browser.new_context(viewport=viewport,device_scale_factor=1,has_touch=True,is_mobile=mobile)
   ctx.add_init_script("window.pr15TrustedInputs=[]; for(const n of ['keydown','keyup','mousedown','mouseup','wheel','touchstart','touchend','touchcancel']) document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
   page=ctx.new_page();check(len(ctx.pages)==1,'single owned engine page')
   page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'case':case}));page.on('pageerror',lambda e:errors.append({'case':case,'error':str(e)}))
   page.goto(f'http://127.0.0.1:{PORT}/index.html?fixture=warehouse&tick=10788&scale={scale}&touch={int(touch)}',wait_until='domcontentloaded',timeout=120000)
   page.wait_for_function('()=>typeof window.pr15Observer==="function"',timeout=120000)
   ui=UI(page,case);t=time.monotonic()
   while not ui.state().get('fixture_ready'):
    if time.monotonic()-t>120:raise TimeoutError('declared cold fixture ready cap120')
    page.wait_for_timeout(100)
   ui.settle();log(case+' page identity',url=page.url,title=page.title(),canvas=page.locator('#canvas').bounding_box());check('/index.html?fixture=warehouse' in page.url and bool(page.title()),'correct page identity');before=ui.rpc('fingerprints');check(before['record_sha256']==SHA,'original record hash before inputs')
   if not ui.rpc('controls')['camera_panel']['visible']:ui.control('camera_toggle',touch)
   ui.geometry()
   for fraction in range(3):ui.focus(0,fraction,touch=False)
   if touch:
    for fraction in range(3):ui.focus(0,fraction,touch=True)
   ui.capture('wave0_focus')
   # Both camera and log remain open; actual original camera command works.
   old=ui.state();new=ui.control('camera_clockwise',touch)
   check(new['view']['yaw']!=old['view']['yaw'],'original camera still rotates with log visible')
   check(new['replay']['tick']==old['replay']['tick'],'camera command never seeks log')
   ui.geometry();ui.seek(.945);check(ui.state()['view']['wave']==1,'original slider reaches second saved wave')
   for fraction in range(3):ui.focus(1,fraction,touch=touch)
   ui.capture('wave1_focus')
   # ItemList retains keyboard focus; ArrowDown selects in it without a world action.
   old=ui.state();page.keyboard.press('ArrowDown');new=ui.settle()
   check(new['replay']['tick']==old['replay']['tick'] and new['gui_focus'].endswith('/EventList'),'focused ItemList keyboard stays in original UI')
   # P remains the original replay shortcut after the ItemList navigation key.
   old=ui.state();page.keyboard.press('p');new=ui.settle();check(new['replay']['playing'],'original keyboard P starts replay')
   page.keyboard.press('p');new=ui.settle();check(not new['replay']['playing'],'original keyboard P pauses replay')
   if touch:
    # Cancel actual contact on log (press may select already); no outstanding camera/world gesture.
    c=ui.fire(1);at=ui.css(c['fractions'][1]);ui.cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':at[0],'y':at[1],'id':9}]});ui.cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});new=ui.settle()
    check(new['view']['gesture']['contacts']==0 and new['view']['gesture']['pending_id']==-1,'actual touchCancel clears UI contact lifecycle')
    # Real DOM focus loss/reset, then a fresh touch works.
    page.evaluate('()=>{const b=document.createElement("button");b.id="qaFocusSink";b.style.cssText="position:fixed;left:0;top:0;width:2px;height:2px";document.body.appendChild(b);b.focus()}')
    page.locator('#canvas').focus();ui.settle();ui.focus(1,1,touch=True)
   after=ui.rpc('fingerprints');check(after['record_sha256']==SHA,'original record hash after inputs');check(after['domain']==before['domain'],'simulation/domain never mutated')
   check(not after['record_validation']['failures'] and not after['frame_checks']['failures'],'original history and3D frame invariants')
   trusted=page.evaluate('window.pr15TrustedInputs');check(trusted and all(x['isTrusted'] for x in trusted),'all acceptance key/mouse/touch events browser trusted')
   save(case+'-fingerprints-before',before);save(case+'-fingerprints-after',after);save(case+'-trusted-inputs',trusted)
   log(case+' END',checks=checks,inputs=len(trusted),engine_inputs=len(after['inputs']),final=ui.state())
   ctx.close();check(not browser.contexts,'case engine ended before next context')
  check(not errors,'JS page errors zero')
  unexpected=[x for x in console if x['type']=='error' or 'SCRIPT ERROR:' in x['text'] or x['text'].startswith('ERROR:')]
  check(not unexpected,'Godot/console errors zero')
  browser.close();actual=0
except Exception as e:
 save('failure',{'exception':str(e),'traceback':traceback.format_exc()});print(traceback.format_exc(),flush=True)
finally:
 server.shutdown();server.server_close()
 save('result',{'source':SOURCE,'actual_exit':actual,'checks':checks,'wall':time.monotonic()-start,'scope':'cold original warehouse history consumer; actual browser UI only; narrow/mobile emulation not real device or performance; no fresh producer/whole acceptance','console':console,'page_errors':errors,'rows':len(rows),'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pid':os.getpid(),'single_page_each_case':True,'server_closed':True})
 print(json.dumps({'BROWSER_END':True,'actual_exit':actual,'checks':checks,'wall':time.monotonic()-start}),flush=True)
raise SystemExit(actual)
