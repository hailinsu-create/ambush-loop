from pathlib import Path
import json,hashlib,subprocess,shutil,datetime,socket
ROOT=Path('/workspace/ambush-pr15');PREV=Path('/tmp/pr15-web-controls/depot-native-8532-20261005');BASE=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005');assert not BASE.exists();BASE.mkdir()
SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e';TREE='1e8af45ee23098f763acc139b56f8f7e0f41665a'
assert not subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain'],text=True).strip()
assert subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD:ambush_loop'],text=True).strip()==TREE
proof=json.loads(Path('/tmp/pr15-web-controls/replay-save-classification-20261005/fixed-stage-proof.json').read_text());pins=[]
for p in proof['pins']:
 f=ROOT/p['path'];row={'path':p['path'],'git_blob':subprocess.check_output(['git','-C',str(ROOT),'hash-object',str(f)],text=True).strip(),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()};assert row['git_blob']==p['blob'] and row['bytes']==p['bytes'] and row['sha256']==p['sha256'];pins.append(row)
for n in ['20261005-pr15-web-depot-producer','20261005-pr15-web-depot-functional-end','20261005-pr15-replay-save-boundary']:
 d=ROOT/'.cursor/docs/evidence'/n;m=json.loads((d/'manifest.json').read_text())
 for p in m['files']:
  blob=(d/p['path']).read_bytes();assert len(blob)==p['bytes'] and hashlib.sha256(blob).hexdigest()==p['sha256']
profile=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert profile.is_dir() and not (profile/'SingletonLock').exists() and not (profile/'SingletonLock').is_symlink()
for port in [12815,12816,12817]:
 s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
active=[x for x in subprocess.check_output(['ps','-eo','stat,comm,args'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])];assert not active,active
spec=json.loads((PREV/'spec.json').read_text());spec['candidate']={'source_sha':SOURCE,'game_tree':TREE};spec['source_strategy_pins']=pins
spec.update({'current_level':'radio','order':['radio'],'whole_scope':'original radio newly produced terminal record, original Replay UI; no cold history setup','site':'private version3 unchanged; candidate local source1ec explicitly separate','receipt_contract':'isolated runtime; exclusive-create request/loaded script/receipt/vault hash; independent labels','status':'PREPARED_UNRUN','short_wave_pause':'phase checked after trusted input; actual natural SWEEP without paused checkpoint is explicitly classified, never false ALER T screenshot','original_profile_expected_checkpoint':'14052356db56d3ebc0f87c3a6825999bc70ae1ea9db03415bdea62e57db36d77'})
(BASE/'spec.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n');shutil.copyfile(PREV/'run/profile-after-depot.json',BASE/'expected-profile-before.json')
for name in ['driver_core.py','driver_whole_and_progress.py','driver_whole_full_fingerprints.py']:
 s=(PREV/name).read_text().replace('8532c4c3084d1a5672bbe28dc96e1c02522a8f05',SOURCE);(BASE/name).write_text(s)
p=BASE/'driver_core.py';s=p.read_text();old="""   self.click('alarm');s=self.state();assert s['phase']==1 and s['wave']==wave
   emit('WAVE_START',level=self.level,wave=wave,attempt=s['attempt'])
   self.click('pause');assert self.state()['sim']['paused'];self.capture(self.level+'_wave'+str(wave)+'_alert');self.click('pause')
   self.wait(lambda x:x['phase']==5,'natural ALERT -> SWEEP',300)"""
new="""   self.click('alarm');s=self.state();assert s['phase'] in [1,5] and s['wave']==wave
   emit('WAVE_START',level=self.level,wave=wave,attempt=s['attempt'],observed_phase=s['phase'])
   if s['phase']==1:
    self.click('pause');paused_state=self.state()
    if paused_state['phase']==1:
     assert paused_state['sim']['paused'];self.capture(self.level+'_wave'+str(wave)+'_paused_alert');self.click('pause')
    else:
     assert paused_state['phase']==5 and paused_state['waves_cleared']==wave+1
     self.log('short wave naturally cleared before pause checkpoint; paused ALERT not observed',state=paused_state,wave=wave)
   else:
    assert s['waves_cleared']==wave+1
    self.log('short wave naturally cleared before ALERT checkpoint; paused ALERT not observed',state=s,wave=wave)
   self.wait(lambda x:x['phase']==5,'natural ALERT -> SWEEP',300)"""
assert s.count(old)==1;s=s.replace(old,new);p.write_text(s)
s=(PREV/'initialize.py').read_text().replace(str(PREV),str(BASE)).replace('8532c4c3084d1a5672bbe28dc96e1c02522a8f05',SOURCE).replace("plan=spec['missions'][4]","plan=spec['missions'][5]").replace("plan['level']=='depot'","plan['level']=='radio'").replace('Title depot','Title radio').replace("spec['missions'][3]['expected_after_natural_win']","spec['missions'][4]['expected_after_natural_win']").replace("['next']=='depot'","['next']=='radio'").replace("['seen']['depot']","['seen']['radio']").replace('DEPOT_PROFILE_CHECK','RADIO_PROFILE_CHECK').replace('seen_depot','seen_radio')
(BASE/'initialize.py').write_text(s)
s=(PREV/'produce_depot.py').read_text().replace('depot','radio').replace('DEPOT','RADIO').replace('8532c4c3084d1a5672bbe28dc96e1c02522a8f05',SOURCE).replace("state['wave_count']==2","state['wave_count']==3")
(BASE/'produce_radio.py').write_text(s)
for rate in [1,2]:
 (BASE/f'whole_radio_{rate}x.py').write_text(f"assert len(context.pages)==1 and page.url==URL\npacket{rate}=whole(d,radio_record,{rate})\n(BASE/'radio-whole-{rate}x-post-WON-full-fingerprint.json').write_text(json.dumps(d.rpc('fingerprints'),ensure_ascii=False,indent=2)+'\\n')\n")
s=(PREV/'browser_controller.py').read_text().replace(str(PREV),str(BASE)).replace('8532c4c3084d1a5672bbe28dc96e1c02522a8f05',SOURCE).replace('event-log-cold-qa-v2-20261005','radio-observer-qa-20261005').replace('DEPOT','RADIO')
needle=" lifecycle={'window_start':now(),'source':"
pos=s.index(needle);s=s[:pos]+""" def start_owned_http():
  nonlocal http_server
  assert http_server is None
  http_server=ThreadingHTTPServer(('127.0.0.1',12815),Handler);threading.Thread(target=http_server.serve_forever,daemon=True).start()
 def stop_owned_http():
  nonlocal http_server
  if http_server is not None:http_server.shutdown();http_server.server_close();http_server=None
"""+s[pos:]
s=s.replace("   http_server=ThreadingHTTPServer(('127.0.0.1',12815),Handler);threading.Thread(target=http_server.serve_forever,daemon=True).start()","   start_owned_http()")
s=s.replace("'os':os}","'os':os,'start_owned_http':start_owned_http,'stop_owned_http':stop_owned_http}")
(BASE/'browser_controller.py').write_text(s)
s=(BASE/'driver_whole_full_fingerprints.py').read_text();pos=s.index('def reopen_same_profile(d):')
s=s[:pos]+'''def reopen_same_profile(d):
 global context,page
 context.close();stop_owned_http()
 context=browser_owner.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},device_scale_factor=1,args=['--no-sandbox','--disable-dev-shm-usage','--disable-breakpad'])
 owned=list(context.pages);before_urls=[p.url for p in owned];assert all(x in [URL,'about:blank','chrome-error://chromewebdata/'] for x in before_urls)
 page=owned[0]
 for surplus in owned[1:]:surplus.close()
 page.goto('about:blank');assert len(context.pages)==1;d.page=page
 cdp_reopen=context.new_cdp_session(page);cdp_reopen.send('Network.enable');cdp_reopen.send('Network.setCacheDisabled',{'cacheDisabled':True})
 page.on('console',lambda m:console.append({'type':m.type,'text':m.text,'wall':time.monotonic()}));page.on('pageerror',lambda e:errors.append(str(e)))
 context.add_init_script("window.pr15TrustedInputs=[];for(const n of ['keydown','keyup','mousedown','mouseup','wheel','touchstart','touchend','touchcancel'])document.addEventListener(n,e=>window.pr15TrustedInputs.push({name:n,isTrusted:e.isTrusted,code:e.code||'',button:e.button,t:performance.now()}),true);")
 (d.base/'limited-reopen-owned-pages.json').write_text(json.dumps({'before':before_urls,'after':[p.url for p in context.pages],'closed_surplus':len(owned)-1,'http_paused_until_single_blank':True,'storage_not_seeded':True},indent=2)+'\\n')
 start_owned_http();page.goto(URL,wait_until='load')
'''
(BASE/'driver_whole_full_fingerprints.py').write_text(s)
pre={'actual_exit':0,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':SOURCE,'game_tree':TREE,'pins':pins,'prior_evidence_size_SHA_exact':'depot59+75 / replaySave100','profile':str(profile),'expected_public_checkpoint':'14052356db56d3ebc0f87c3a6825999bc70ae1ea9db03415bdea62e57db36d77','live_engines':active,'ports_closed':True,'profile_lock_absent':True,'runtime_started':False,'radio_export_status':'UNRUN'}
(BASE/'preflight.json').write_text(json.dumps(pre,indent=2)+'\n');shutil.copyfile(Path(__file__),BASE/'prepare_controls.py');print(json.dumps({k:v for k,v in pre.items() if k!='pins'}))
