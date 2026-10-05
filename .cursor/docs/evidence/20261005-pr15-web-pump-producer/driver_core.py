from pathlib import Path
import time, json, datetime, uuid, math, hashlib, base64
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def emit(kind,**fields):print(json.dumps({'kind':kind,'utc':utc(),**fields},ensure_ascii=False),flush=True)
class Driver:
 def __init__(self,page,base):
  self.page=page;self.base=base;self.rows=[];self.seq=0;self.level=None;self.level_start=None;self.producer_active=False;self.last_state=None
 def rpc(self,action,**args):
  self.seq+=1;request={'id':self.seq,'action':action,**args}
  packet=self.page.evaluate("""(r)=>{window.pr15Observer(JSON.stringify(r));try{const v=JSON.parse(window.pr15ObserverReply);return v.id===r.id?v:null}catch{return null}}""",request)
  if packet is None:
   self.page.wait_for_function('(id)=>{try{return JSON.parse(window.pr15ObserverReply).id===id}catch{return false}}',arg=self.seq,timeout=120000,polling=25)
   packet=json.loads(self.page.evaluate('window.pr15ObserverReply'))
  assert packet['id']==self.seq
  reply=packet['value']
  if isinstance(reply,dict) and reply.get('error'):raise RuntimeError(reply['error'])
  return reply
 def state(self):
  self.last_state=self.rpc('state');return self.last_state
 def check_budget(self):
  if self.producer_active and time.monotonic()-self.level_start>900:raise TimeoutError('level producer wall cap900 reached')
 def log(self,label,**row):
  item={'label':label,'wall':time.monotonic(),'utc':utc(),**row};self.rows.append(item)
  with (self.base/'driver-actions.jsonl').open('a') as f:f.write(json.dumps(item,ensure_ascii=False)+'\n')
 def wait(self,predicate,label,seconds=120):
  start=time.monotonic();last=None;last_logged=start
  while time.monotonic()-start<seconds:
   self.check_budget();last=self.state()
   if time.monotonic()-last_logged>=5:
    self.log("observed "+label,elapsed_wall=time.monotonic()-start,state=last);last_logged=time.monotonic()
   if predicate(last):self.log(label,wait_wall=time.monotonic()-start,state=last);return last
   if last.get('phase')==2 and 'natural' in label:raise RuntimeError('natural FAILED '+last.get('fail_reason',''))
   self.page.wait_for_timeout(250)
  self.log(label+' TIMEOUT',wait_wall=time.monotonic()-start,state=last)
  raise TimeoutError(label+' wall cap '+str(seconds))
 def settle(self):
  s=self.state();return self.wait(lambda x:x['presents']>=s['presents']+2,'two real presents',120)
 def capture(self,label):
  self.settle();s=self.state();p=self.base/(label+'.png');self.page.screenshot(path=str(p))
  self.log('capture '+label,path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),state=s)
  return s
 def coords(self,point):
  state=self.state();box=self.page.locator('#canvas').bounding_box();tr=state['screen_transform'];win=state['window_size']
  assert box
  sx=tr[0][0]*point[0]+tr[1][0]*point[1]+tr[2][0];sy=tr[0][1]*point[0]+tr[1][1]*point[1]+tr[2][1]
  return box['x']+sx*box['width']/win[0],box['y']+sy*box['height']/win[1]
 def click(self,key):
  self.check_budget();c=self.rpc('controls').get(key);assert c and not c.get('missing') and c['visible'] and not c['disabled'],(key,c)
  x,y,w,h=c['rect'];assert w>0 and h>0 and x>=0 and y>=0 and x+w<=1281 and y+h<=721,(key,c)
  point=self.coords([x+w/2,y+h/2]);before=self.last_state;self.page.mouse.click(*point)
  self.log('trusted control '+key,control=c,css=point,before=before,cached_before=True);self.settle()
 def key(self,key,settle=True):
  self.check_budget();before=self.last_state;self.page.keyboard.press(key)
  self.log('trusted key '+key,before=before,cached_before=True)
  if settle:self.settle()
 def world(self,pos,height,label,wanted=''):
  self.check_budget()
  action_start=time.monotonic()
  for turn in range(13):
   if time.monotonic()-action_start>120:raise TimeoutError(label+" original world action cap120")
   target=self.rpc('project_targets',pos=pos,height=height);pick=target['pick']
   reachable=target['in_viewport'] and not target['over_ui']
   if wanted:
    reachable=reachable and pick.get('kind')==wanted
    if wanted!='ground':reachable=reachable and math.dist(pos,pick.get('pos',[math.inf,math.inf]))<1
    else:reachable=reachable and all(p.get('kind')=='ground' for p in target['neighbors'])
   if reachable:break
   self.log('camera original UI reveal '+label,turn=turn,target=target)
   if turn<12:self.click('camera_clockwise')
  assert reachable,(label,target)
  point=self.coords(target['screen']);before=self.state();self.page.mouse.click(*point)
  self.log('trusted world '+label,target=target,css=point,before=before);self.settle()
 def select(self,index):
  self.key(str(index+1));s=self.state();assert s['selected']==s['operators'][index]['id'];return s
 def tool(self,wanted):
  for _ in range(4):
   if self.state()['tool']==wanted:break
   self.click('tool')
  assert self.state()['tool']==wanted
 def collect(self,family,index):
  s=self.select(index);stash=next((x for x in s['stashes'] if x['family']==family and not x['collected']),None);assert stash,(family,s['stashes'])
  self.world(stash['pos'],0.55,'stash_'+stash['kind'],'stashes')
  s=self.wait(lambda x:all(a['id']!=stash['id'] or a['collected'] for a in x['stashes']),'natural stash '+family,120)
  if family in ['rifle','mg','scout']:assert s['operators'][index]['family']==family
 def tutorial(self):
  for page_index in range(10):
   s=self.state()
   if not s['modal']['tutorial']:break
   self.capture(s['level']+'_tutorial_'+str(s['modal']['tutorial_page']))
   self.click('tutorial_next')
  s=self.state();assert not s['modal']['tutorial'] and s['settings']['seen'].get(s['level'])
  assert all(o['weapon']=='knife' for o in s['operators'])
 def deploy(self,plan):
  for i in range(3):
   s=self.select(i);cover=s['covers'][plan['cover_array_indices_by_operator'][i]]
   if s['operators'][i]['slot']!=cover['id']:self.world(cover['pos'],0.08,'cover_'+str(cover['id']),'covers')
   self.wait(lambda x:x['operators'][i]['slot']==cover['id'],'natural mount cover',120)
   target=plan['facing_degrees_by_operator'][i];quantum=8 if s['operators'][i]['role']==1 else 15
   tolerance=quantum/2+0.01
   for _ in range(6):
    s=self.state();diff=(target-s['operators'][i]['facing']+180)%360-180
    if abs(diff)<=tolerance:break
    count=min(4,max(1,round(abs(diff)/quantum)))
    for _ in range(count):self.key('d' if diff>0 else 'a',settle=False)
    self.settle()
    self.log('original facing key batch confirmed',count=count,operator=i,state=self.state())
   assert abs((target-self.state()['operators'][i]['facing']+180)%360-180)<=tolerance
 def mine(self,cell):
  self.select(0);self.tool(0);at=[(cell[0]+0.5)*32,(cell[1]+0.5)*32];near=[at[0]+32,at[1]]
  self.world(near,0.02,'walk_mine_range','ground')
  self.wait(lambda s:not s['operators'][0]['moving'] and math.dist(s['operators'][0]['pos'],at)<=64,'natural mine range',120)
  self.tool(1);before=self.state();self.world(at,0.02,'place_carried_mine','ground');after=self.state()
  assert after['operators'][0]['mines']==before['operators'][0]['mines']-1 and after['mines_count']==before['mines_count']+1
  self.tool(0)
 def sweep(self,plan,wave):
  assert self.state()['phase']==5
  for _ in range(20):
   s=self.state();loot=next((x for x in s['loot'] if not x['collected']),None)
   if loot is None:break
   self.select(plan['sweep_loot_operator']);self.tool(0);before=self.state();self.world(loot['pos'],0.12,'loot_'+loot['kind'])
   self.wait(lambda x:all(a['id']!=loot['id'] or a['collected'] for a in x['loot']),'natural SWEEP pickup',120)
   self.wait(lambda x:not next(o for o in x['operators'] if o['id']==x['selected'])['moving'],'natural SWEEP walk done',120)
   self.log('original loot collected',loot=loot,before=before,after=self.state())
  if wave==0:
   index=plan['first_sweep_authored_ammo_operator']
   if index is not None:self.collect('ammo',index)
   if plan['first_sweep_mine_cell'] is not None:self.collect('mine',0);self.mine(plan['first_sweep_mine_cell'])
  self.capture(plan['level']+'_wave'+str(wave)+'_sweep')
  if wave+1<plan['wave_count']:self.deploy(plan)
 def archive(self,label):
  first=self.rpc('copy_record_bytes',offset=0,count=1048576);meta=first['meta'];buf=base64.b64decode(first['chunk_base64'])
  while len(buf)<meta['bytes']:
   part=self.rpc('copy_record_bytes',offset=len(buf),count=1048576);assert part['meta']==meta and part['offset']==len(buf);buf+=base64.b64decode(part['chunk_base64'])
  assert len(buf)==meta['bytes'] and hashlib.sha256(buf).hexdigest()==meta['sha256']
  path=self.base/(label+'-record.bin');assert not path.exists();path.write_bytes(buf)
  assert not meta['validation']['failures'],meta
  self.log('archive original record',path=str(path),meta=meta)
  return {**meta,'path':str(path)}
 def mission(self,plan):
  self.level=plan['level'];self.level_start=getattr(self,"producer_budget_started_at",time.monotonic());self.producer_active=True
  s=self.state();emit('LEVEL_START',level=self.level,source='8532c4c3084d1a5672bbe28dc96e1c02522a8f05',attempt=s['attempt'],wave_count=s['wave_count'],phase=s['phase'])
  s=self.state();assert s['level']==self.level and s['phase']==0 and not any(s['modal'][x] for x in ['pause','tutorial','backpack','handoff','credits'])
  assert all(o['weapon']=='knife' for o in s['operators'])
  for item in plan['collect']:self.collect(item['family'],item['operator_index'])
  self.deploy(plan)
  if plan['ammo_pack_operator'] is not None:
   self.select(plan['ammo_pack_operator']);self.click('pack');assert self.state()['operators'][plan['ammo_pack_operator']]['has_ammo_pack']
  if self.level=='railcut':
   self.select(0);self.key('i');assert self.state()['modal']['backpack']
   if self.state()['operators'][0]['auto_grenade']:self.click('backpack_auto')
   assert not self.state()['operators'][0]['auto_grenade'];self.click('backpack_close')
  if self.level=='warehouse':self.select(1);self.key('f')
  if plan['scout_mine_cell'] is not None:self.mine(plan['scout_mine_cell']);self.deploy(plan)
  self.capture(self.level+'_armed_scout')
  for wave in range(plan['wave_count']):
   self.click('alarm');s=self.state();assert s['phase']==1 and s['wave']==wave
   emit('WAVE_START',level=self.level,wave=wave,attempt=s['attempt'])
   self.click('pause');assert self.state()['sim']['paused'];self.capture(self.level+'_wave'+str(wave)+'_alert');self.click('pause')
   self.wait(lambda x:x['phase']==5,'natural ALERT -> SWEEP',300)
   s=self.state();emit('WAVE_END',level=self.level,wave=wave,status='SWEEP',attempt=s['attempt'],tick=s['sim']['tick'],log=s['log'])
   self.sweep(plan,wave)
  self.click('alarm');s=self.state();assert s['phase']==3 and s['waves_cleared']==plan['wave_count']
  self.producer_active=False;producer_wall=time.monotonic()-self.level_start;self.capture(self.level+'_won')
  record=self.archive(self.level);record['producer_wall']=producer_wall
  (self.base/(self.level+'-producer.json')).write_text(json.dumps({'status':'PASS','source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','record':record,'state':self.state()},indent=2)+'\n')
  emit('LEVEL_PRODUCER_END',level=self.level,status='PASS',record=record)
  return record
