extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ACTOR_BATTLE: " + message)


func _body(main: Node, key: String) -> ActorVisual:
	return main.presentation_3d.actors[key].get_node("Body") as ActorVisual


func _signature(body: ActorVisual) -> Array:
	var values: Array = [body.asset_id, body.equipped_id, body.sampled_action, body.sampled_time, body.global_transform, body.get_meta("pose_event_id", "")]
	for i in body.skeleton.get_bone_count():
		values.append(body.skeleton.get_bone_pose(i))
	return values


func _frame_contract(main: Node) -> void:
	var view = main.presentation_3d
	for group in ["ops", "enemies", "sentries"]:
		for item in view.frame[group]:
			var key := "%s:%s" % [group, item.id]
			var body := _body(main, key)
			_check(body != null and body.asset_id == item.visual_model and body.skeleton.get_bone_count() == 20, "actual battlefield actor uses its recorded imported rig: " + key)
			if body == null:
				continue
			_check(body.global_position.distance_to(Space.logic_to_world(item.pos)) < 0.001 and body.scale == Vector3.ONE, "actor keeps simulation feet and full root scale: " + key)
			_check((body.global_basis * Vector3.FORWARD).distance_to(Space.facing_direction(item.facing)) < 0.0001, "actor forward is the recorded tactical heading: " + key)
			_check(body.equipped_id == item.visual_weapon and body.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, "recorded visual equipment and manual clock: " + key)
			if body.equipped != null:
				var socket := body.item_socket("grip")
				_check(not socket.is_empty() and socket.transform.origin.distance_to(body.bone_socket("weapon_hand").position) < 0.0001, "actual battlefield grip aligns with hand: " + key)
				if body.sampled_action in ["aim", "fire"]:
					_check((body.equipped.global_basis * Vector3.FORWARD).normalized().dot((body.global_basis * Vector3.FORWARD).normalized()) > 0.98, "actual aim/fire gun axis follows the recorded ground heading: " + key)


func _capture(main: Node, name: String, size: float = 24.0, yaw: float = 35.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var view = main.presentation_3d
	view.rig.view_size = size
	view.rig.yaw_deg = yaw
	view.rig.apply_pose()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://build/asset_review/pr15-runtime"
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("r3_battle_" + name + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "save actual battlefield " + name)
	print("ACTOR_BATTLE_CAPTURE ", path)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	var view = main.presentation_3d
	view.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.operators[1].receive_item("m1911", 5) # Explicit visual equipment fixture.
	view.refresh()
	_frame_contract(main)
	_check(_body(main, "ops:1").asset_id == "operator_rifle" and _body(main, "ops:2").asset_id == "operator_mg" and _body(main, "ops:3").asset_id == "operator_scout", "all three actual operator role models are present")
	await _capture(main, "scout")
	main.raid_force_alarm()
	var ticks := 0
	while main.phase == main.Phase.WATCHING and main.battle_log.first_of_type("fire").is_empty() and ticks < 3000:
		main._sim_tick()
		ticks += 1
	var fire: Dictionary = main.battle_log.first_of_type("fire")
	_check(not fire.is_empty() and main.phase == main.Phase.WATCHING, "actual first wave produces a shot before completion")
	if fire.is_empty() or main.phase != main.Phase.WATCHING:
		root.get_node("AudioDirector").pause_for_background()
		quit(2)
		return
	main.battle_log.add_snapshot(main.sim.tick, main._snapshot_data())
	var first: Dictionary = main.battle_log.snapshots.back().duplicate(true)
	view.refresh()
	_frame_contract(main)
	var key := "ops:%d" % int(fire.actor_id)
	var body := _body(main, key)
	_check(body.sampled_action == "fire" and body.get_meta("pose_event_id") == fire.event_id and is_equal_approx(body.sampled_time, float(main.sim.tick - BattleLog.record_tick(fire)) / 60.0), "actual shot samples its stable event and global elapsed time")
	var paused_pose := _signature(body)
	var paused_state: Dictionary = main._snapshot_data().duplicate(true)
	main.sim.paused = true
	for i in 4:
		main._process(0.2)
		view.refresh()
		await process_frame
	_diagnose(paused_state, main._snapshot_data(), "paused")
	print("ACTOR_POSE_PAUSE_SIGNATURE_EQUAL=", paused_pose == _signature(_body(main, key)))
	_check(paused_state == main._snapshot_data() and paused_pose == _signature(_body(main, key)), "paused ALERT wall time cannot advance rig, recorded clock or combat")
	main.sim.paused = false
	main.sim.set_speed(2.0)
	var start_tick: int = main.sim.tick
	main._process(1.0 / 60.0)
	view.refresh()
	_check(main.sim.tick == start_tick + 2 and is_equal_approx(view.frame.pose_clock_s, float(main.sim.tick) / 60.0), "actual 2x frame uses two simulation ticks, not animation wall time")
	await _capture(main, "alert")
	while main.phase == main.Phase.WATCHING and ticks < 6000:
		main._sim_tick()
		ticks += 1
	_check(main.phase == main.Phase.SWEEP, "actual first wave reaches SWEEP")
	if main.phase != main.Phase.SWEEP:
		root.get_node("AudioDirector").pause_for_background()
		quit(2)
		return
	main.raid_vacuum_loot() # Consume authored drops, no additional battle ammo.
	main._select_op(1)
	main._on_pack_equip("m1911")
	main.selected.toggle_crouch()
	view.refresh()
	_check(_body(main, "ops:2").equipped_id == "m1911" and _body(main, "ops:2").sampled_action == "crouch", "legal SWEEP equip and crouch reach the actual rig")
	await _capture(main, "sweep")
	main._on_sweep_commit()
	for i in 60:
		if main.phase == main.Phase.WATCHING:
			main._sim_tick()
	main.battle_log.add_snapshot(main.sim.tick, main._snapshot_data())
	var second: Dictionary = main.battle_log.snapshots.back().duplicate(true)
	_check(second.wave_id == 1 and second.data.ops[1].visual_weapon == "m1911" and second.data.ops[1].stance == 1, "second wave records actual changed equipment and pose")
	view.refresh()
	_frame_contract(main)
	await _capture(main, "wave2")
	while main.phase == main.Phase.WATCHING and ticks < 12000:
		main._sim_tick()
		ticks += 1
	_check(main.phase == main.Phase.SWEEP, "actual changed-equipment second wave clears")
	if main.phase == main.Phase.SWEEP:
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase == main.Phase.WON and main.raid.waves_cleared == 2, "both actual waves extract with unchanged battle rules")
	var source: Array = main.battle_log.snapshots.duplicate(true)
	main._on_replay_pressed()
	main.operators[1].weapon_id = "knife"
	main.operators[1].stance = OperatorUnit.Stance.STAND
	main.operators[1].global_position = Vector2(32, 32)
	main.operators[1].hp = 3
	main.run_id += 200
	var poisoned_live: Dictionary = main._snapshot_data().duplicate(true)
	var retained_poses := {}
	for snap in [first, second, first, second]:
		main.replay.set_tick(BattleLog.record_tick(snap))
		main._apply_replay_scrub()
		view.refresh()
		_frame_contract(main)
		var current := _body(main, "ops:2")
		_check(current.equipped_id == snap.data.ops[1].visual_weapon and current.asset_id == snap.data.ops[1].visual_model, "backward/forward history ignores current knife/model/position")
		if snap.wave_id == 1:
			_check(current.sampled_action == "crouch" and current.scale == Vector3.ONE, "historical crouch is sampled in bones, no root squash")
		var stamp: String = "%s:%s" % [snap.attempt_id, snap.wave_id]
		if retained_poses.has(stamp):
			_check(retained_poses[stamp] == _signature(current), "same historical identity/time reproduces the exact bone pose after another wave")
		retained_poses[stamp] = _signature(current)
		var muzzle: Transform3D = current.item_socket("muzzle").transform
		for spec in [[12.0, 0], [24.0, 1], [36.0, 2], [24.0, 1], [12.0, 0]]:
			view.rig.view_size = spec[0]
			view.rig.apply_pose()
			view.refresh()
			_check(current.lod == spec[1] and current.item_socket("muzzle").transform.is_equal_approx(muzzle), "actual near/mid/far LOD preserves historical muzzle and identity")
		await _capture(main, "history_wave%d" % int(snap.wave_id), 24.0)
	_diagnose(poisoned_live, main._snapshot_data(), "history")
	_check(source == main.battle_log.snapshots and poisoned_live == main._snapshot_data(), "full battle history rendering/LOD/seek preserves recordings and poisoned live state")
	# Future/current/other-wave combat events cannot start a historical animation.
	main.replay.set_tick(BattleLog.record_tick(fire) - 1)
	main._apply_replay_scrub()
	view.refresh()
	_check(_body(main, key).get_meta("pose_event_id") != fire.event_id, "scrubbing before the actual shot removes its future pose event")
	var probe: Dictionary = view.frame.duplicate(true)
	probe.tick = BattleLog.record_tick(fire)
	probe.events = [fire.duplicate(true)]
	var actor: Dictionary = probe.ops.filter(func(o: Dictionary) -> bool: return o.id == fire.actor_id).front()
	probe.events[0].wave_id += 1
	_check(ActorPose.sample(actor, probe, "ops").event_id == "", "same actor/tick from another wave cannot replay the shot")
	probe.events[0] = fire.duplicate(true)
	probe.events[0].attempt_id = "another-attempt"
	_check(ActorPose.sample(actor, probe, "ops").event_id == "", "another attempt cannot lend its event to the current run")
	main.replay.set_tick(BattleLog.record_tick(first))
	main._apply_replay_scrub()
	view.refresh()
	await _capture(main, "history_close", 12.0, 180.0)
	await _capture(main, "history_rotated", 24.0, 270.0)
	_compatibility(main, first)
	main._exit_replay_to_setup()
	main._start_setup(false, false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.raid_force_alarm()
	view.refresh()
	_check(view.frame.attempt_id != first.attempt_id and _body(main, "ops:2").get_meta("pose_event_id") == "", "new attempt clears old wave identity and shot pose")
	root.get_node("AudioDirector").pause_for_background()
	print("ACTOR_BATTLE_OK" if failures == 0 else "ACTOR_BATTLE_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _compatibility(main: Node, first: Dictionary) -> void:
	for mode in ["missing", "future", "revision", "invalid_clock"]:
		var log := BattleLog.new()
		var snap := first.duplicate(true)
		match mode:
			"missing":
				snap.data.erase("animation_schema")
				snap.data.erase("actor_asset_revision")
				for op in snap.data.ops:
					op.erase("visual_model")
					op.erase("visual_weapon")
			"future": snap.data.animation_schema = 99
			"revision": snap.data.actor_asset_revision = "future-rig-version"
			"invalid_clock": snap.data.pose_clock_s = INF
		log.snapshots = [snap]
		var copy: Array = log.snapshots.duplicate(true)
		main.replay.bind(log)
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		_check(not main.presentation_3d.frame.animation_supported and not main.presentation_3d.actors["ops:2"].get_node("Body") is ActorVisual, "unsupported/missing animation uses neutral gray model: " + mode)
		_check(main.c2.portraits._cards[1].get_node("Gun").get("weapon_id") == snap.data.ops[1].weapon and log.snapshots == copy, "neutral animation keeps historical HUD and source data: " + mode)


func _diagnose(before: Dictionary, after: Dictionary, prefix: String) -> void:
	for field in before:
		if before[field] == after.get(field):
			continue
		if before[field] is Array and after.get(field) is Array:
			for i in mini(before[field].size(), after[field].size()):
				if before[field][i] is Dictionary:
					_diagnose(before[field][i], after[field][i], prefix + "." + str(field) + ":" + str(i))
		else:
			print("ACTOR_STATE_DIFF ", prefix, ".", field, " before=", before[field], " after=", after.get(field))
