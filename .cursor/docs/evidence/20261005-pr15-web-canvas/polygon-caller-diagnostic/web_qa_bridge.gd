extends Node
# External debug-stage fixture. Never present in the release game or Site.
const Space := preload("res://scripts/presentation/world_space.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Groups := preload("res://scripts/presentation/view_state.gd")
var callback: JavaScriptObject
var source: BattleLog
var source_level := ""
var source_original_hash := ""
var monitor := false
var monitor_ticks := 0.0
var monitor_start := 0
var monitor_rows: Array = []
var monitor_failures: Array = []
var original_state: Array = []

func _ready() -> void:
	assert(OS.has_feature("web") and OS.is_debug_build())
	process_priority = 10000
	get_tree().node_added.connect(_observe_polygon)
	callback = JavaScriptBridge.create_callback(_receive)
	JavaScriptBridge.get_interface("window").pr15QA = callback

func _receive(args: Array) -> void:
	var request: Variant = JSON.parse_string(str(args[0]))
	_dispatch.call_deferred(request)

func _reply(value: Dictionary) -> void:
	JavaScriptBridge.get_interface("window").pr15QAResult = JSON.stringify(value)

func _fingerprint() -> String:
	if source == null: return ""
	var fields := {}
	for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
		fields[key] = source.get(key)
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes(fields))
	return h.finish().hex_encode()

func _state() -> Dictionary:
	var m = get_tree().current_scene
	var out := {"scene":m.scene_file_path,"debug_fixture":true,"source_level":source_level,"monitor":monitor,"monitor_rows":monitor_rows.size(),"monitor_failures":monitor_failures}
	if not "phase" in m: return out
	out.merge({"phase":int(m.phase),"sim_tick":m.sim.tick,"sim_paused":m.sim.paused,"replay_tick":m.replay.scrub_tick,"replay_playing":m.replay.playing,"replay_speed":m.replay.speed,"replay_max":m.replay.max_tick(),"backpack_open":m.backpack_panel.is_open(),"suspended":m._presentation_suspended,"wave":m.wave_index()})
	if m.presentation_3d != null:
		var v=m.presentation_3d
		out.merge({"touch_contacts":v.gestures.contacts.size(),"suppressed_contacts":v.gestures.suppressed_contacts.size(),"pending_touch":v.gestures.pending_id,"middle_down":v.gestures.middle_down,"frame_attempt":v.frame.get("attempt_id",""),"frame_level":v.frame.get("level_id",""),"frame_wave":v.frame.get("wave_id",-1),"frame_tick":v.frame.get("playback_tick",-1),"frame_seq":v.frame.get("frame_seq",-1),"camera_yaw":v.rig.yaw_deg})
	return out

func _assert_frame() -> Dictionary:
	var m=get_tree().current_scene
	var v=m.presentation_3d
	var record:Dictionary=m.replay.snapshot_at_or_before(m.replay.scrub_tick)
	var f:Dictionary=v.frame
	var failures:Array=[]
	var checks:=0
	var conditions := [[f.attempt_id==source.attempt_id,"attempt"],[f.level_id==source_level,"level"],[f.wave_id==record.wave_id,"wave"],[f.frame_seq==record.frame_seq,"frame_seq"],[f.playback_tick==m.replay.scrub_tick,"global_clock"],[f.recorded_phase==record.data.phase,"phase"],[f.events==source.events.filter(func(e:Dictionary)->bool:return m.replay.playback_time(e)<=m.replay.scrub_tick),"event_cutoff"]]
	for c in conditions:
		checks+=1
		if not c[0]:failures.append(c[1])
	for group in Groups.GROUPS:
		var expected:Array=record.data.get(group,[])
		checks+=1
		if f[group].size()!=expected.size():failures.append(group+" count")
		for item:Dictionary in expected:
			var matches:Array=f[group].filter(func(x:Dictionary)->bool:return x.id==item.id)
			checks+=1
			if matches.size()!=1:failures.append(group+" identity");continue
			for key in item:
				checks+=1
				if matches[0].get(key)!=item[key]:failures.append(group+":"+str(item.id)+":"+str(key))
			if group not in ["ops","enemies","sentries"]:continue
			var proxy=v.actors.get(group+":"+str(item.id))
			checks+=1
			if proxy==null:failures.append(group+" missing3D");continue
			var body=proxy.get_node("Body")
			checks+=2
			if not proxy.position.is_equal_approx(Space.logic_to_world(item.pos)):failures.append(group+" root")
			if not body is Actor or body.skeleton.get_bone_count()!=20:failures.append(group+" imported20bones")
	return {"checks":checks,"failures":failures,"state":_state()}

func _dispatch(r:Dictionary) -> void:
	var m=get_tree().current_scene
	match str(r.action):
		"state":_reply(_state())
		"load_record":
			monitor=false
			source_level=str(r.level)
			var raw:Variant=bytes_to_var(FileAccess.get_file_as_bytes("/tmp/native-record.bin"))
			assert(raw is Dictionary)
			source=BattleLog.new()
			for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:source.set(key,raw[key])
			source_original_hash=_fingerprint()
			get_node("/root/GameSettings").pending_level_id=source_level
			get_node("/root/GameSettings").mark_tutorial_seen(source_level)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			await get_tree().process_frame
			await get_tree().process_frame
			m=get_tree().current_scene
			m.battle_log=source
			m.phase=m.Phase.WON # Cold historical consumer; never a new win.
			m._on_replay_pressed()
			m.replay.pause()
			m._apply_replay_scrub()
			m.presentation_3d.refresh()
			var selected:Dictionary={}
			for rec:Dictionary in source.playback_snapshots:
				var key=str(rec.wave_id)+":"+str(rec.data.phase)
				if not selected.has(key):selected[key]={"tick":rec.playback_tick,"wave":rec.wave_id,"phase":rec.data.phase,"seq":rec.frame_seq}
			_reply({"source_original_hash":source_original_hash,"attempt":source.attempt_id,"max_tick":source.playback_terminal_tick,"selected":selected.values(),"state":_state()})
		"seek":
			m.replay.set_tick(int(r.tick));m._apply_replay_scrub();m.presentation_3d.refresh();_reply(_assert_frame())
		"focus":
			var ok:bool=m.focus_latest_of_type(str(r.type));m.presentation_3d.refresh();_reply({"focused":ok,"state":_state()})
		"whole":
			m.replay.set_tick(0);m.replay.set_speed(float(r.rate));m._apply_replay_scrub();m.presentation_3d.refresh()
			original_state=[m.sim.tick,m.sim.speed,m.sim.paused,m.sim._accum,m.run_id]
			monitor_ticks=0.0;monitor_rows.clear();monitor_failures.clear();monitor_start=Time.get_ticks_usec();monitor=true;m.replay.play()
			_reply(_state())
		"whole_result":
			_reply({"state":_state(),"rows":monitor_rows,"rate_failures":monitor_failures,"wall_s":float(Time.get_ticks_usec()-monitor_start)/1000000.0,"source_unchanged":_fingerprint()==source_original_hash,"live_sim_unchanged":original_state==[m.sim.tick,m.sim.speed,m.sim.paused,m.sim._accum,m.run_id],"terminal_reached":m.replay.scrub_tick==source.playback_terminal_tick and not m.replay.playing})
		"restart_scout":
			monitor=false;get_node("/root/GameSettings").pending_level_id="yard";get_node("/root/GameSettings").mark_tutorial_seen("yard");get_tree().change_scene_to_file("res://scenes/main.tscn");await get_tree().process_frame;await get_tree().process_frame;_reply(_state())

func _process(delta:float) -> void:
	if not monitor:return
	var m=get_tree().current_scene
	monitor_ticks+=delta*m.replay.speed*60.0
	var expected:=mini(floori(monitor_ticks+0.000001),m.replay.max_tick())
	if m.replay.scrub_tick!=expected:monitor_failures.append({"tick":m.replay.scrub_tick,"expected":expected})
	monitor_rows.append({"tick":m.replay.scrub_tick,"expected":expected,"delta":delta,"us":Time.get_ticks_usec()-monitor_start,"view_tick":m.presentation_3d.frame.get("playback_tick",-1)})
	if not m.replay.playing:monitor=false

func _observe_polygon(node: Node) -> void:
	if node is Polygon2D and node.get_script() == null:
		node.set_script(preload("res://web_polygon_observer.gd"))
