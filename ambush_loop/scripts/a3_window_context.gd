extends RefCounted
## Test-only shared frozen workload and provenance receipts; call outside timing.
const Provenance := preload("res://scripts/a3_provenance.gd")


static func configure(tree: SceneTree) -> void:
	tree.root.size=Vector2i(1280,720)
	tree.root.position=Vector2i.ZERO
	tree.root.content_scale_factor=1.0
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED) # Record actual mode even if driver refuses.
	var settings: Node = tree.root.get_node("GameSettings")
	settings.set_quality_tier("standard")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")


static func freeze(main: Node) -> void:
	main.set_process(false)
	var view: Node3D = main.presentation_3d
	view.rig.reset_view()
	main._update_hud()
	view.refresh()
	view.set_process(false) # Both controls use this same explicit stationary render workload.


static func backend_bytes(main: Node) -> PackedByteArray:
	var log: BattleLog = main.battle_log
	return var_to_bytes([main.phase,main.level_id,main.run_id,main._presentation_suspended,
		main._pose_command_clock_s,main._night_timer,main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,
		log.attempt_id,log.wave_id,log.wave_offset,log.events,log.snapshots,log.playback_snapshots,
		log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick(),
		main.raid.wave_index,main.raid.waves_cleared,main.raid.awaiting_extract,
		main.operators.map(func(op:OperatorUnit)->Array:return [op.op_id,op.global_position,op.hp,op.ammo,
			op.grenades,op.mines,op.weapon_id,op.ammo_pool,op.pack.slots,op.stance,op.sprinting,op.move_path,op._path_i]),
		main.enemies.map(func(enemy:EnemyRunner)->Array:return [enemy.global_position,enemy.hp,enemy.alive,enemy.active])])


static func digest(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


static func workload(main: Node) -> Dictionary:
	var view: Node3D = main.presentation_3d
	return {"backend_sha256":digest(backend_bytes(main)),"presenter_frame_sha256":digest(var_to_bytes(view.frame)),
		"level_id":main.level_id,"attempt_id":main.battle_log.attempt_id,"phase":main.phase,
		"main_auto_process":main.is_processing(),"presenter_auto_process":view.is_processing(),
		"tree_paused":main.get_tree().paused,"policy":main.get_tree().root.get_node("GameSettings").quality_tier,
		"window_width":main.get_window().size.x,"window_height":main.get_window().size.y,
		"content_scale":main.get_window().content_scale_factor,"max_fps":Engine.max_fps,
		"vsync":DisplayServer.window_get_vsync_mode(),"focus":view.rig.focus,
		"yaw_deg":view.rig.yaw_deg,"pitch_deg":view.rig.pitch_deg,"view_size":view.rig.view_size}


static func proof(receipt_sha: String) -> Dictionary:
	var result := Provenance.verify(OS.get_environment("AMBUSH_A3_PROVENANCE_FILE"),OS.get_environment("AMBUSH_TEST_SOURCE_SHA"))
	result["window_control_verified"]=result.get("verified",false) and result.get("complete_source_tree_verified",false) and result.get("imported_cache_files_verified",0)>0 and result.get("receipt_sha256")==receipt_sha
	return result


static func _visible_limit(path: String) -> String:
	if not FileAccess.file_exists(path):return "unavailable"
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null:return "unavailable"
	var lines := PackedStringArray()
	while not file.eof_reached():lines.append(file.get_line())
	file.close()
	return "\n".join(lines).strip_edges()


static func environment() -> Dictionary:
	return {"engine":Engine.get_version_info(),"pid":OS.get_process_id(),"os":OS.get_name(),"os_version":OS.get_version(),
		"cpu":OS.get_processor_name(),"cpu_count":OS.get_processor_count(),"display":DisplayServer.get_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),
		"api_version":RenderingServer.get_video_adapter_api_version(),"method":RenderingServer.get_current_rendering_method(),
		"driver":RenderingServer.get_current_rendering_driver_name(),"audio_driver":AudioServer.get_driver_name(),
		"debug_build":OS.is_debug_build(),"visible_cpu_max":_visible_limit("/sys/fs/cgroup/cpu.max"),
		"visible_memory_max":_visible_limit("/sys/fs/cgroup/memory.max"),
		"visible_cpu_effective":_visible_limit("/sys/fs/cgroup/cpuset.cpus.effective"),
		"cgroup_scope":"visible mount-root limits; not proof of exclusive host CPU",
		"scope":"stationary original yard with main AND presenter automatic process stopped; not normal SCOUT/dynamic FX/mobile FPS"}
