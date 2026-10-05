def whole(d,record,rate):
 level=record['level'];emit('WHOLE_START',level=level,rate=rate,attempt=record['attempt'],record_sha256=record['sha256'])
 assert d.state()['phase']==3
 d.click('replay');s=d.state();assert s['phase']==4 and s['replay']['speed']==2
 if s['replay']['playing']:d.click('pause')
 if d.state()['replay']['speed']!=rate:d.click('speed')
 slider=d.rpc('controls')['scrub'];x,y,w,h=slider['rect'];point=d.coords([x+1,y+h/2]);d.page.mouse.click(*point);d.page.keyboard.press('Home');d.settle()
 s=d.state();assert s['replay']['tick']==0 and not s['replay']['playing'] and s['replay']['speed']==rate,s['replay']
 before=d.rpc('fingerprints');assert before['record_sha256']==record['sha256'] and not before['frame_checks']['failures'],before['frame_checks']
 row_start=len(before['replay_rows']);input_start=len(before['inputs'])
 start=time.monotonic();d.click('pause')
 deadline=max(180,6*(record['terminal']/60)/rate+30)
 s=d.wait(lambda x:x['replay']['tick']==record['terminal'] and not x['replay']['playing'],'natural whole terminal',deadline)
 after=d.rpc('fingerprints');rows=after['replay_rows'][row_start:];inputs=after['inputs'][input_start:]
 first_playing=next((r for r in rows if r['playing']),None)
 terminal=next((r for r in rows if r['tick']==record['terminal'] and not r['playing']),None)
 actual_press=next((r for r in inputs if r.get('kind')=='mouse' and r.get('pressed')),None)
 assert terminal and first_playing and actual_press
 callback_wall=(terminal['us']-actual_press['us'])/1e6
 assert all(r['view_tick']==r['tick'] for r in rows)
 assert after['record_sha256']==record['sha256'] and after['domain']==before['domain']
 assert not after['frame_checks']['failures'] and not after['record_validation']['failures']
 elapsed=time.monotonic()-start
 packet={'status':'PASS','level':level,'rate':rate,'attempt':record['attempt'],'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','record_sha256':record['sha256'],'terminal_tick':record['terminal'],'record_duration':record['terminal']/60,'deadline_wall':deadline,'controller_total_wall':elapsed,'input_to_terminal_callback_wall':callback_wall,'record_unchanged':True,'domain_unchanged':True,'observer_rows':rows,'actual_input_rows':inputs,'frame_checks':after['frame_checks'],'scope':'original ReplayButton/pause/speed/scrub/Home/resume; natural terminal; software WebGL, not frame budget acceptance'}
 (d.base/(level+'-whole-'+str(rate)+'x.json')).write_text(json.dumps(packet,indent=2)+'\n')
 d.capture(level+'_whole_'+str(rate)+'x_terminal')
 # UI-only scrub and original event lists are separate from whole accounting.
 d.key('ArrowLeft');assert not d.state()['replay']['playing']
 d.key('ArrowRight');assert not d.state()['replay']['playing']
 d.key('Space');assert d.state()['phase']==3
 emit('WHOLE_END',**{k:v for k,v in packet.items() if k not in ['observer_rows','actual_input_rows','frame_checks']})
 return packet

def assert_progress(s,expected):
 gs=s['settings'];missions=gs['missions']
 assert [m['id'] for m in missions if m['cleared']]==expected['cleared'],gs
 assert [m['id'] for m in missions if m['unlocked']]==expected['unlocked'],gs
 assert gs['complete']==expected['complete']
 if expected['continue_level'] is not None:assert gs['has_progress'] and gs['next']==expected['continue_level']
 else:assert not gs['has_progress']

def original_title_rows(d,expected,label):
 s=d.state();assert s['scene']=='res://scenes/title.tscn';assert_progress(s,expected)
 d.click('title_start');assert d.state()['mission_select']
 controls=d.rpc('controls')
 for mission in s['settings']['missions']:
  c=controls['mission_row:'+mission['id']];assert c['visible'] and c['disabled']==(not mission['unlocked'])
 d.capture(label+'_mission_rows')
 d.key('Escape');assert not d.state()['mission_select']
 assert d.rpc('controls')['title_continue']['disabled']==(expected['continue_level'] is None)
 return d.state()

def reload_original(d,expected,label,reopen=False):
 before=d.state();checkpoint=d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 assert checkpoint is not None
 payload=json.loads(checkpoint);assert payload['schema']==1
 path=d.base/(label+'-before-reload.json')
 path.write_text(json.dumps({'state':before,'public_checkpoint':payload,'public_checkpoint_sha256':hashlib.sha256(checkpoint.encode()).hexdigest()},ensure_ascii=False,indent=2)+'\n')
 emit('RELOAD_START',checkpoint=label,reopen=reopen)
 if reopen:reopen_same_profile(d)
 else:d.page.reload(wait_until='load')
 d.page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
 after=d.wait(lambda x:x['scene']=='res://scenes/title.tscn' and x['presents']>3,'reloaded original Title',120)
 assert_progress(after,expected)
 for key in ['muted','music_volume','sfx_volume','force_touch_hud','quality','seen']:
  assert after['settings'][key]==before['settings'][key],key
 for key,cfg in before['settings']['configs'].items():
  assert after['settings']['configs'][key]==cfg,(key,after['settings']['configs'][key],cfg)
 assert d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==checkpoint
 after=original_title_rows(d,expected,label+'_reloaded')
 (d.base/(label+'-after-reload.json')).write_text(json.dumps({'status':'PASS','state':after,'public_checkpoint_sha256':hashlib.sha256(checkpoint.encode()).hexdigest(),'reopen':reopen},ensure_ascii=False,indent=2)+'\n')
 emit('RELOAD_END',checkpoint=label,status='PASS',reopen=reopen,settings=after['settings'])
 return after

def boundary(d,plan):
 level=plan['level'];expected=plan['expected_after_natural_win'];assert_progress(d.state(),expected)
 if plan['next_level'] is None:
  d.click('continue');assert d.state()['modal']['credits'];d.capture('radio_credits_open')
  c=d.rpc('controls')['credits_scroll'];x,y,w,h=c['rect'];d.page.mouse.move(*d.coords([x+w/2,y+h/2]));d.page.mouse.wheel(0,600);d.settle();d.capture('radio_credits_scrolled')
  d.click('credits_back');d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original credits -> Title',120)
  original_title_rows(d,expected,'radio_complete');reload_original(d,expected,'radio_complete_reload');reload_original(d,expected,'radio_complete_reopen',True)
  emit('LEVEL_END',level=level,status='PASS_PRODUCER_WHOLE_PROGRESS',next_level=None,complete=True)
  return
 d.click('continue');s=d.state();assert s['level']==plan['next_level'] and s['phase']==0 and s['modal']['handoff']
 assert s['modal']['handoff_from']==level and s['modal']['handoff_to']==plan['next_level']
 preview=s['attempt'];d.capture(level+'_next_handoff');d.click('handoff_cta');d.tutorial();s=d.state()
 assert s['attempt']==preview and all(o['weapon']=='knife' for o in s['operators'])
 d.log('abandoned unarmed preview attempt',level=plan['next_level'],attempt=preview,reason='original next tutorial followed by legitimate Title/reload checkpoint')
 d.key('Escape');assert d.state()['modal']['pause'];d.click('pause_title')
 d.wait(lambda s:s['scene']=='res://scenes/title.tscn','original pause -> Title',120)
 original_title_rows(d,expected,level+'_cleared')
 reload_original(d,expected,level+'_reload')
 if level=='yard':reload_original(d,expected,'yard_reopen',True)
 d.click('title_continue')
 s=d.wait(lambda x:x.get('level')==plan['next_level'] and x.get('phase')==0,'original next Continue SCOUT',120)
 assert not s['modal']['tutorial'] and s['attempt']!=preview and all(o['weapon']=='knife' for o in s['operators'])
 d.capture(plan['next_level']+'_continued_knife_scout')
 emit('LEVEL_END',level=level,status='PASS_PRODUCER_WHOLE_PROGRESS',next_level=plan['next_level'],abandoned_preview_attempt=preview,next_attempt=s['attempt'])

def reopen_same_profile(d):
 global context,page
 context.close()
 context=browser_owner.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
 owned=list(context.pages);assert all(p.url in [URL,'about:blank'] for p in owned)
 page=owned[0]
 for surplus in owned[1:]:surplus.close()
 assert len(context.pages)==1
 d.page=page
 page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'wall':time.monotonic()}))
 page.on('pageerror',lambda e:errors.append(str(e)))
 context.add_init_script("window.pr15TrustedInputs=[]; for (const name of ['keydown','keyup','mousedown','mouseup','wheel']) document.addEventListener(name,e=>window.pr15TrustedInputs.push({name,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
 page.goto(URL,wait_until='load')
