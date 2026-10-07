from pathlib import Path
import subprocess,os,json,hashlib,shutil,datetime,re,struct
BASE=Path('/tmp/pr15-web-controls/pump-native-8532-20261005')
SOURCE='8532c4c3084d1a5672bbe28dc96e1c02522a8f05'
STAGE=Path('/workspace/pr15-pump-consumer-stage-20261005')
PROD=Path('/workspace/pr15-web-stage-event-log-20261005')
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'pump-cold-consumer-20261005'
assert not STAGE.exists() and not OUT.exists()
assert subprocess.check_output(['git','-C','/workspace/ambush-pr15','rev-parse','HEAD:ambush_loop'],text=True).strip()=='45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85'
shutil.copytree(PROD,STAGE);OUT.mkdir()
assert not list(STAGE.rglob('*.blend'))
raw=BASE/'run/pump-record.bin';raw_sha=hashlib.sha256(raw.read_bytes()).hexdigest()
assert raw_sha=='a0e5b232a001671ead8156e97e29f902796f81cd7669d925d66045064d5709cf'
bridge=Path('/workspace/pr15-event-log-qa-stage-v2-20261005/qa/event_log_observer.gd').read_text()
start=bridge.index('func _cold_fixture()');end=bridge.index('\nfunc _presented()',start)
fixture='''func _cold_fixture() -> void:
	# Isolated historical pump consumer. Exactly one cold setup; never a fresh win.
	var params: Dictionary = JSON.parse_string(JavaScriptBridge.eval("JSON.stringify(Object.fromEntries(new URLSearchParams(location.search)))"))
	if str(params.get("fixture", "")) != "pump": return
	var path := "res://qa/pump-record.bin"
	assert(FileAccess.get_sha256(path) == "RECORD_SHA")
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var history := BattleLog.new()
	for field: String in RECORD_FIELDS: history.set(field, raw[field])
	var settings = get_node("/root/GameSettings")
	settings.pending_level_id = "pump"
	settings.mark_tutorial_seen("pump") # only disposable consumer profile
	get_tree().change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	for _i in 6: await get_tree().process_frame
	var m = get_tree().current_scene
	m.battle_log = history
	m.phase = m.Phase.WON # history input staging only, never a new victory
	m.result_panel.visible = true
	m.result_label.text = "历史 pump 原记录 · 隔离回放验收"
	m.replay_button.visible = true
	m._update_hud()
	for _i in 6: await get_tree().process_frame
	fixture_ready = true
'''.replace('RECORD_SHA',raw_sha)
bridge=bridge[:start]+fixture+bridge[end:]
(STAGE/'qa').mkdir();(STAGE/'qa/event_log_observer.gd').write_text(bridge)
shutil.copy2(raw,STAGE/'qa/pump-record.bin');(BASE/'pump-consumer-observer.gd').write_text(bridge)
p=STAGE/'project.godot';p.write_text(p.read_text().replace('[autoload]','[autoload]\n\nEventLogObserver="*res://qa/event_log_observer.gd"',1))
p=STAGE/'export_presets.cfg';p.write_text(p.read_text().replace('include_filter="','include_filter="qa/*.bin,'))
oldbase=Path('/tmp/pr15-web-controls/event-log-ui-20261005/exports')
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(oldbase/'isolated-data'),'XDG_CONFIG_HOME':str(oldbase/'isolated-config'),'XDG_CACHE_HOME':str(oldbase/'isolated-cache')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
meta={'source':SOURCE,'game_tree':'45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85','stage':str(STAGE),'output':str(OUT),'argv':argv,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'one declared cold original-history setup in disposable consumer profile, then read-only RPC and original Replay/pause/speed/Home/resume natural terminal; no gameplay source edits, no asset generation, no record reconstruction','bridge_sha256':hashlib.sha256(bridge.encode()).hexdigest(),'record_sha256':raw_sha}
with (BASE/'pump-consumer-export.log').open('wb') as log:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=60)
t=(BASE/'pump-consumer-export.log').read_text(errors='replace')
meta.update({'actual_exit':r.returncode,'ERROR':len(re.findall('^ERROR:',t,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',t,re.M)),'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':[{'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.iterdir()) if p.is_file()]})
(BASE/'pump-consumer-export.json').write_text(json.dumps(meta,indent=2)+'\n')
assert meta['actual_exit']==meta['ERROR']==meta['SCRIPT_ERROR']==0,meta
def entries(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 file_base=struct.unpack_from('<Q',b,24)[0];directory=struct.unpack_from('<Q',b,32)[0];count=struct.unpack_from('<I',b,directory)[0];p=directory+4;out={}
 for _ in range(count):
  size=struct.unpack_from('<I',b,p)[0];p+=4;name=b[p:p+size].rstrip(b'\0').decode();p+=size
  offset,nbytes=struct.unpack_from('<QQ',b,p);p+=16;md5=b[p:p+16];p+=16;flags=struct.unpack_from('<I',b,p)[0];p+=4
  payload=b[file_base+offset:file_base+offset+nbytes]
  assert flags==0 and len(payload)==nbytes and hashlib.md5(payload).digest()==md5 and name not in out,name
  out[name]=payload
 return out
old=entries(Path('/workspace/pr15-web-artifacts')/SOURCE/'debug/index.pck');new=entries(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in set(old)&set(new) if old[k]!=new[k])
classname='.godot/global_script_class_cache.cfg'
def classes(b):
 out={}
 for block in re.findall(r'\{.*?\}',b.decode(),re.S):
  name=re.search(r'"class": &"([^"]+)"',block).group(1);assert name not in out;out[name]=block
 return out
assert classes(old[classname])==classes(new[classname])
assert not removed and set(added)=={'qa/event_log_observer.gd.remap','qa/event_log_observer.gdc','qa/pump-record.bin'}
assert set(changed)<={'project.binary','.godot/uid_cache.bin',classname},changed
audit={'source':SOURCE,'actual_exit':0,'production_pck_sha256':hashlib.sha256((Path('/workspace/pr15-web-artifacts')/SOURCE/'debug/index.pck').read_bytes()).hexdigest(),'consumer_pck_sha256':hashlib.sha256((OUT/'index.pck').read_bytes()).hexdigest(),'all_payload_md5_verified':True,'added':added,'changed':changed,'removed':removed,'class_raw_blocks_equal':True,'class_count':len(classes(old[classname])),'class_difference':'ordering only; all complete per-class blocks equal','production_payloads_unchanged_except_declared_metadata':True,'payloads':{k:{'bytes':len(v),'sha256':hashlib.sha256(v).hexdigest()} for k,v in new.items()}}
(BASE/'pump-consumer-payload-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps({'export_exit':meta['actual_exit'],'ERROR':meta['ERROR'],'SCRIPT_ERROR':meta['SCRIPT_ERROR'],'pck_bytes':(OUT/'index.pck').stat().st_size,'pck_sha256':audit['consumer_pck_sha256'],'added':added,'changed':changed,'class_count':audit['class_count'],'scope':meta['scope']}),flush=True)
