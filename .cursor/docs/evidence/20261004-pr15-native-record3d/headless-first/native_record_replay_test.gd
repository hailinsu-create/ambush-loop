extends "res://scripts/replay_autoplay_test.gd"
## Authentic native producer bytes; scene construction is a cold replay fixture.
## Native transport uses the unchanged original UI and engine process.
const Pose := preload("res://scripts/presentation/actor_pose.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
var record_directory := ""
var output_directory := ""
var record_manifest := {}
var record_level := ""
var source_hash := ""
var record_rows := []
var seek_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("NATIVE_RECORD_REPLAY_FAIL " + record_level + " " + message)

func _write_report() -> void:
	var file := FileAccess.open(output_directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"consumer_source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"consumer_stage":OS.get_environment("AMBUSH_CONSUMER_STAGE"),"fixture_sha256":FileAccess.get_sha256("res://scripts/native_record_replay_test.gd"),"producer_source_sha":record_manifest.get("source_sha",""),"checks":checks,"failures":failures,"records":record_rows,"seeks":seek_rows,"rows":rows,"captures":captures,"native_inputs":input_rows,"scope":"Read-only authentic archived native producer bytes. Cold scene loads and explicit terminal/foreign-live fixtures are not new normal battles. Real imported3D actors/world/20bones, original native transport and natural engine callbacks. API seek/focus fixtures separately identified. No source upgrades or final same-candidate FX/A3/device acceptance."},"  "))
	file.close()

func _modal_capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path := output_directory+"/"+record_level+"_"+label+".png"
	_check(image.save_png(path)==OK,"actual native Window capture saved")
	captures.append({"id":record_level+"_"+label,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()],"capture_source":"DisplayServer.screen_get_image native Window crop"})

func _open_source(row: Dictionary) -> bool:
	record_level = row.level
	var path := record_directory.path_join("native-player-"+record_level+"-record.bin")
	source_hash=FileAccess.get_sha256(path)
	_check(source_hash==row.sha256,"manifest raw SHA matches actual original record")
	if source_hash!=row.sha256: return false
	var raw: Variant = bytes_to_var(FileAccess.get_file_as_bytes(path))
	_check(raw is Dictionary,"original record is a Dictionary")
	if not raw is Dictionary: return false
	source=BattleLog.new()
	for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
		source.set(key,raw[key])
	_check(source.attempt_id==row.attempt and source.playback_terminal_tick==row.playback_terminal_tick,"manifest identity/clock matches source")
	retained=_state(source)
	var settings=root.get_node("GameSettings")
	settings.pending_level_id=record_level
	settings.mark_tutorial_seen(record_level) # Cold consumer fixture only.
	settings.set_force_touch_hud(false)
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	main.battle_log=source
	main.phase=main.Phase.WON # Cold terminal UI fixture, never a new victory.
	main.result_panel.visible=true
	main.replay_button.visible=true
	main._ensure_result_layout()
	main._raise_result_overlay()
	main._update_hud()
	await _draw()
	return true

func _all_actor_bones() -> Dictionary:
	var result := {}
	for key in view.actors:
		var body = view.actors[key].get_node("Body")
		if not body is Actor: continue
		var signature := [body.global_transform,body.sampled_action,body.sampled_time,body.asset_id,body.asset_revision,body.equipped_id]
		for i in body.skeleton.get_bone_count(): signature.append(body.skeleton.get_bone_pose(i))
		result[key]=signature
	return result

func _assert_source_frame(record: Dictionary) -> void:
	var frame: Dictionary = view.frame
	_check(frame.attempt_id==source.attempt_id and frame.level_id==record_level and frame.wave_id==record.wave_id,"selected source identity/wave/level")
	_check(frame.playback_tick==main.replay.scrub_tick and frame.recorded_phase==record.data.phase,"selected source clock/phase")
	_check(frame.environment_revision==record.data.environment_revision and frame.actor_asset_revision==record.data.actor_asset_revision,"source environment/actor revisions")
	for group in ViewState.GROUPS:
		var expected: Array = record.data.get(group,[])
		_check(frame[group].size()==expected.size(),"source object count "+group)
		for item: Dictionary in expected:
			var matches: Array = frame[group].filter(func(value: Dictionary) -> bool: return value.id==item.id)
			_check(matches.size()==1,"source object identity "+group+":"+str(item.id))
			if matches.size()!=1: continue
			for key in item:
				_check(matches[0].get(key)==item[key],"saved field "+group+":"+str(item.id)+":"+str(key))
			if group not in ["ops","enemies","sentries"]: continue
			var actor_key: String = str(group)+":"+str(item.id)
			_check(view.actors.has(actor_key),"actual3D actor exists "+actor_key)
			if not view.actors.has(actor_key): continue
			var proxy: Node3D=view.actors[actor_key]
			_check(proxy.position.is_equal_approx(Space.logic_to_world(item.pos)),"actual3D recorded root "+actor_key)
			var body = proxy.get_node("Body")
			_check(body is Actor,"actual imported actor "+actor_key)
			if not body is Actor: continue
			_check(body.skeleton.get_bone_count()==20 and body.asset_revision==frame.actor_asset_revision,"actual20 bones/R5 revision "+actor_key)
			var pose := Pose.sample(matches[0],frame,group)
			_check(body.equipped_id==str(pose.get("visual_item",matches[0].visual_weapon)),"actual original source equipment "+actor_key)
	_check(frame.events==source.events.filter(func(ev: Dictionary) -> bool: return main.replay.playback_time(ev)<=main.replay.scrub_tick),"no future/foreign live events in selected frame")

func _source_seeks() -> void:
	main._on_replay_pressed() # Original entry API; native button separately below.
	main.replay.pause()
	main._apply_replay_scrub()
	var foreign := BattleLog.new()
	foreign.begin_attempt("foreign-native-record-consumer")
	foreign.add_event(0,"fire",1,1,Vector2(9999,9999),{"name":"foreign","visual_weapon":"luger"})
	foreign.add_snapshot(0,{"level_id":"foreign","phase":1,"ops":[]})
	var foreign_state:=_state(foreign)
	main.battle_log=foreign
	main.operators[0].global_position=Vector2(7777,8888)
	main.operators[0].weapon_id="luger"
	live=main._snapshot_data().duplicate(true)
	sim_state=[main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]
	var selected := {}
	for record: Dictionary in source.playback_snapshots:
		var key := str(record.wave_id)+":"+str(record.data.phase)
		if not selected.has(key): selected[key]=record
	selected["last"]=source.playback_snapshots.back()
	var signatures := {}
	var samples: Array=selected.values()
	var order: Array=samples.duplicate()
	samples.reverse()
	order.append_array(samples)
	for record: Dictionary in order:
		main.replay.set_tick(record.playback_tick)
		main._apply_replay_scrub()
		view.refresh()
		_assert_source_frame(record)
		var signature := _all_actor_bones()
		var key := str(record.frame_seq)
		if signatures.has(key): _check(signature==signatures[key],"back/forward exact source root/all20bones "+key)
		else: signatures[key]=signature
		_unchanged("cold source seek")
		_check(_state(foreign)==foreign_state,"foreign colliding actor/seq record unmodified")
		seek_rows.append({"level":record_level,"frame_seq":record.frame_seq,"phase":record.data.phase,"wave":record.wave_id,"playback_tick":record.playback_tick,"actor_bone_signatures":signature.size()})
		await _draw()
	for record: Dictionary in selected.values():
		main.replay.set_tick(record.playback_tick)
		main._apply_replay_scrub()
		view.refresh()
		await _modal_capture("seek_wave%d_phase%d" % [record.wave_id,record.data.phase])
	for ev: Dictionary in source.events:
		if ev.type not in ["fire","return_fire","mine","repack","loot","terminal"]: continue
		main._focus_battle_event(ev)
		view.refresh()
		_check(main.replay.scrub_tick==main.replay.playback_time(ev) and not main.replay.playing,"original event focus saved identity/time "+ev.event_id)
		_check(view._focus_attempt==source.attempt_id and view._focus_wave==ev.wave_id,"actual3D focus source identity "+ev.event_id)
		_unchanged("saved event focus")
	main.battle_log=source
	main.phase=main.Phase.WON
	main.replay.pause()
	main.result_panel.visible=true
	main.replay_button.visible=true
	main._ensure_result_layout()
	main._raise_result_overlay()
	main._update_hud()
	await _draw()

func _whole_engine_playback() -> void:
	main._on_replay_pressed()
	main.replay.set_speed(2.0)
	main.replay.play(true)
	main._apply_replay_scrub()
	view.set_process(true)
	live=main._snapshot_data().duplicate(true)
	sim_state=[main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]
	var probe:=ClockProbe.new()
	probe.host=main
	probe.process_priority=150
	root.add_child(probe)
	probe.armed=true
	main.set_process(true)
	var started:=Time.get_ticks_msec()
	var deadline:=started+240000
	while main.replay.playing and Time.get_ticks_msec()<deadline: await process_frame
	probe.armed=false
	main.set_process(false)
	await _draw()
	_check(main.replay.scrub_tick==source.playback_terminal_tick and not main.replay.playing,"whole natural engine2x reaches original terminal")
	_check(view.frame.recorded_phase==main.Phase.WON and view.frame.attempt_id==source.attempt_id,"actual3D terminal source WON")
	for row in probe.rate_rows: _check(row.tick==row.expected,"whole natural callback rate120 ticks/s")
	_unchanged("whole natural source playback")
	rows.append({"level":record_level,"scope":"Whole2x from original0 to original terminal without manual seek/advance/tick callbacks","callbacks":probe.rate_rows.size(),"rate_rows":probe.rate_rows,"elapsed_wall_ms":Time.get_ticks_msec()-started,"tick":main.replay.scrub_tick,"terminal":source.playback_terminal_tick})
	probe.queue_free()
	await _modal_capture("whole2x_terminal")

func _run() -> void:
	var manifest_path:=OS.get_environment("AMBUSH_NATIVE_RECORD_MANIFEST")
	record_directory=OS.get_environment("AMBUSH_NATIVE_RECORD_DIR")
	if not FileAccess.file_exists(manifest_path):
		_check(false,"explicit original native manifest required")
		quit(2)
		return
	record_manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	_check(record_manifest.get("source_sha","")==OS.get_environment("AMBUSH_RECORD_SOURCE_SHA") and not str(record_manifest.get("source_sha","")).is_empty(),"explicit producer SHA matches manifest")
	output_directory="res://build/asset_review/pr15-runtime/native-record3d-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))==OK,"independent consumer output")
	print("NATIVE_RECORD_OUTPUT="+output_directory)
	for row: Dictionary in record_manifest.records:
		print("NATIVE_RECORD_LEVEL="+str(row.level))
		if not await _open_source(row): break
		await _source_seeks()
		view.set_process(true)
		if DisplayServer.get_name()!="headless":
			var begin:=rows.size()
			await _native_case(false)
			for i in range(begin,rows.size()): rows[i]["level"]=record_level
		await _whole_engine_playback()
		var path:=record_directory.path_join("native-player-"+record_level+"-record.bin")
		_check(FileAccess.get_sha256(path)==source_hash and _state(source)==retained,"original source raw and all values remain unchanged")
		record_rows.append({"level":record_level,"sha256":source_hash,"attempt":source.attempt_id,"playback_terminal_tick":source.playback_terminal_tick,"events":source.events.size(),"frames":source.playback_snapshots.size(),"source_unchanged":FileAccess.get_sha256(path)==source_hash and _state(source)==retained})
		_write_report()
	root.get_node("AudioDirector").pause_for_background()
	_write_report()
	print("NATIVE_RECORD_REPLAY_TEST checks=%d failures=%d records=%d" % [checks,failures,record_rows.size()])
	quit(0 if failures==0 and record_rows.size()==record_manifest.records.size() else 1)
