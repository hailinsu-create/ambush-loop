extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Pose := preload("res://scripts/presentation/actor_pose.gd")
const Utility := preload("res://scripts/presentation/utility_pose.gd")
const Upper := preload("res://scripts/presentation/firearm_pose.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var checks := 0
var failures := 0
var captures: Array = []
var completed_stages := 0
var main: Node
var view: Node3D


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("UTILITY_RUNTIME: " + message)


func _bones(body: Actor) -> Array:
	var values: Array = [body.sampled_action, body.sampled_time, body.global_transform, body.equipped_id]
	for i in body.skeleton.get_bone_count():
		values.append(body.skeleton.get_bone_pose(i))
	return values


func _body() -> Actor:
	view.refresh()
	return view.actors["ops:%d" % main.selected.op_id].get_node("Body") as Actor


func _operator(frame: Dictionary) -> Dictionary:
	return frame.ops.filter(func(item: Dictionary) -> bool: return item.id == main.selected.op_id).front()


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	main._update_hud()
	view.rig.focus = Space.logic_to_world(main.selected.global_position)
	view.rig.view_size = 10.0
	view.rig.yaw_deg = 180.0
	view.rig.apply_pose()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/r5_" + name + ".png"
	_check(root.get_texture().get_image().save_png(path) == OK, "save actual framebuffer " + name)
	captures.append({"path": path, "sha256": FileAccess.get_sha256(path), "phase": main.phase,
		"wave_id": view.frame.wave_id, "event_id": _body().get_meta("pose_event_id"), "action": _body().sampled_action})


func _reset() -> void:
	main._load_level("yard", false, false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0], {"grenades": 2, "mines": 0})
	main._select_op(0)
	main.selected.decoys = 2 # Explicit inventory fixture; production consume paths below.
	view.refresh()


func _record_copy(data: Dictionary, phase: int, attempt: String, wave: int, tick: int) -> Dictionary:
	var log := BattleLog.new()
	log.attempt_id = attempt
	log.wave_id = wave
	log.add_snapshot(tick, data)
	log.mark_terminal(tick, "fixture")
	main.replay.bind(log)
	main.phase = main.Phase.REPLAY
	view.refresh()
	var frame: Dictionary = view.frame.duplicate(true)
	_check(frame.recorded_phase == phase, "copied record keeps source phase")
	return frame


func _actual_command() -> void:
	_reset()
	var op = main.selected
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var events: Array = main.battle_log.events.duplicate(true)
	var count: int = main.raid_grenades.size()
	var target: Vector2 = op.global_position + Vector2(0, -240)
	_check(main._throw_grenade_from(op, target), "successful production SCOUT throw")
	_check(op.grenades == int(before.ops[0].grenades) - 1 and main.raid_grenades.size() == count + 1, "inventory and actual grenade change immediately")
	var grenade = main.raid_grenades.back()
	_check(grenade._flight == 0.0 and is_equal_approx(grenade._flight_t, 0.18) and grenade.target.distance_to(op.global_position) <= 160.001, "existing .18s flight and range clamp are unchanged")
	var body := _body()
	_check(body.sampled_action == "grenade_throw" and is_equal_approx(body.sampled_time, 0.5) and body.equipped_id == "", "immediate release samples .5s and hides already released hand prop")
	var release: Dictionary = main._snapshot_data().duplicate(true)
	var release_frame: Dictionary = view.frame.duplicate(true)
	var state: Dictionary = _operator(release_frame).utility_pose.duplicate(true)
	_check(state.target == grenade.target and state.attempt_id == "" and state.event_id.begins_with(release.utility_scope_id), "record copies actual clamped target and pre-ALERT identity")
	main._process(0.1)
	body = _body()
	_check(is_equal_approx(body.sampled_time, 0.6) and grenade._flight > 0.0, "command action and actual flight advance on original clocks")
	var signature := _bones(body)
	main._toggle_pause_menu()
	main._process(0.25)
	await process_frame
	_check(_bones(_body()) == signature, "pause menu freezes all sampled utility bones")
	main.pause_overlay.dismiss()
	main.handle_app_focus_out()
	main._process(0.25)
	_check(_bones(_body()) == signature, "background freezes command utility bones")
	main.handle_app_focus_in()
	main._process(0.1)
	_check(_body().sampled_time > float(signature[1]), "command utility resumes on focus return")
	await _capture("scout_grenade_follow")
	# Poison every live input relevant to this pose. A copied command record
	# remains fixed even though its BattleLog attempt identity is still empty.
	var source_scope: String = release.utility_scope_id
	main.run_id += 500
	main._pose_command_clock_s = 999.0
	op.apply_weapon("knife", false)
	op.global_position += Vector2(64, 64)
	var historical := _record_copy(release, main.Phase.SETUP, "", 0, 0)
	var historical_bones := _bones(_body())
	_check(_body().sampled_action == "grenade_throw" and _body().sampled_time == 0.5 and historical.utility_scope_id == source_scope and _operator(historical).utility_pose.event_id == state.event_id, "history uses original event identity/clock/equipment/position")
	main.replay.set_tick(0)
	view.refresh()
	_check(_bones(_body()) == historical_bones, "repeated command seek exactly reproduces bones")
	_check(main.battle_log.events == events, "utility recording creates no extra simulation events")
	for field in ["scope_id", "attempt_id", "wave_id", "phase", "clock_domain", "actor_id", "weapon", "since", "schema", "event_id"]:
		var probe := historical.duplicate(true)
		var item := _operator(probe)
		match field:
			"scope_id", "attempt_id", "clock_domain", "weapon", "event_id": item.utility_pose[field] = "foreign"
			"since": item.utility_pose[field] = float(probe.pose_clock_s) + 1.0
			_: item.utility_pose[field] = 99
		_check(Pose.sample(item, probe, "ops").action != "grenade_throw", "invalid/foreign/future utility field refuses " + field)
	for revision in ["r4", "r3", "future"]:
		var probe := historical.duplicate(true)
		probe.animation_schema = 2 if revision == "r4" else (1 if revision == "r3" else 99)
		probe.actor_asset_revision = Pose.R4_REVISION if revision == "r4" else (Pose.LEGACY_REVISION if revision == "r3" else "unknown")
		_check(Pose.supported(probe) == (revision != "future") and Pose.sample(_operator(probe), probe, "ops").action != "grenade_throw", "old/future records cannot acquire R5 action " + revision)
	_reset()
	op = main.selected
	var sentry = main.c2.sentries.front()
	op.global_position = sentry.backstab_world()
	op.facing_deg = sentry.facing_deg
	var loot_before: int = main.loot_piles.size()
	var weapon_before: String = op.weapon_id
	_check(main.c2._skill_knife(op), "successful production C2 knife skill")
	_check(sentry.is_down() and main.loot_piles.size() == loot_before + 1 and op.weapon_id == weapon_before, "C2 immediate knockout/loot do not change equipment")
	body = _body()
	_check(body.sampled_action == "knife_stab" and body.equipped_id == "knife" and body.sampled_time == 0.5, "C2 actual strike selects tool at hit window")
	_check(body.bone_socket("weapon_hand").position.distance_to(body.item_socket("grip").transform.origin) < 0.0001, "actual C2 knife grip uses old real socket")
	await _capture("scout_knife_hit")
	op.apply_weapon("mg42", true)
	_check(_body().sampled_action != "knife_stab", "weapon change latches tool cancellation")
	op.apply_weapon(weapon_before, true)
	_check(_body().sampled_action != "knife_stab", "swapping back cannot resurrect cancelled strike")
	var decoys_before: int = main.raid_decoys.size()
	var far: Vector2 = main.grid.cell_to_world_center(Vector2i(30, 18))
	main._throw_decoy_at(far)
	_check(main.raid_decoys.size() == decoys_before + 1 and main.raid_decoys.back().global_position == far and op.decoys == 1, "actual far decoy appears immediately; no approach/reach rule")
	body = _body()
	_check(body.sampled_action == "decoy_place" and body.equipped_id == "" and body.sampled_time == 0.5, "already placed decoy has no duplicate held prop")
	await _capture("scout_decoy_release")
	main._command_move_selected(op.global_position + Vector2(0, 96))
	_check(op.is_moving() and _body().sampled_action != "decoy_place", "new move cancels stationary placement without delaying movement")
	op.stop_move()
	main._throw_grenade_from(op, op.global_position + Vector2(60, 0))
	var command_event: String = _body().get_meta("pose_event_id")
	main.raid_force_alarm()
	_check(_body().get_meta("pose_event_id") != command_event, "phase and real attempt change cancel SCOUT event")
	completed_stages += 1


func _actual_alert() -> void:
	_reset()
	main.raid_force_alarm()
	var op = main.selected
	for operator in main.operators:
		operator.fire_permitted = false # Controlled target/cadence fixture.
		operator.auto_grenade = false
	var spawn_steps := 0
	while main.enemies.is_empty() and spawn_steps < 180 and main.phase == main.Phase.WATCHING:
		main._sim_tick()
		spawn_steps += 1
	_check(not main.enemies.is_empty(), "actual ALERT schedule spawns target before auto-grenade fixture")
	if main.enemies.is_empty():
		return
	op.auto_grenade = true
	var before_ammo: int = op.grenades
	var mark: Vector2 = op.global_position + Vector2(80, 0)
	# The existing auto policy requires an active enemy at the mark and rejects
	# friendly blast risk. This is an explicit target-position fixture.
	main.enemies.front().active = true
	main.enemies.front().global_position = mark
	op.set_nade_mark(mark)
	main._tick_auto_grenades(0.0)
	_check(op.grenades == before_ammo - 1 and _body().sampled_action == "grenade_throw", "actual ALERT auto-grenade records successful release")
	for i in 6:
		main._sim_tick()
	var body := _body()
	_check(body.sampled_time > 0.5 and body.sampled_time < 1.0, "ALERT uses global simulation time")
	var recorded: Dictionary = main.battle_log.snapshots.back().duplicate(true)
	var first_pose: Array = _bones(body)
	main.sim.paused = true
	main._process(0.2)
	_check(_bones(_body()) == first_pose, "paused ALERT holds utility bones")
	main.sim.paused = false
	main.sim.speed = 2.0
	var tick: int = main.sim.tick
	main._process(0.05)
	_check(main.sim.tick == tick + 6 and _body().sampled_time >= float(first_pose[1]) + 0.09, "original ALERT 2x ticks drive utility pose")
	await _capture("alert_auto_grenade")
	# A real melee attack goes through try_fire's immediate damage + signal.
	main._select_op(2)
	op = main.selected
	op.apply_weapon("knife", false)
	op.locked = false
	op.fire_permitted = true
	op.shot_cd = 0.0
	var enemy = main.enemies.front()
	op.global_position = enemy.global_position - Vector2(10, 0)
	op.facing_deg = 0.0
	enemy.active = true
	var hp: float = enemy.hp
	_check(op.try_fire(enemy, main.grid) and enemy.hp < hp, "actual ALERT melee damage remains immediate")
	_check(_body().sampled_action == "knife_stab" and _body().equipped_id == "knife", "actual melee signal uses R5 knife pose")
	await _capture("alert_knife_hit")
	main._select_op(0)
	op = main.selected
	main.phase = main.Phase.SWEEP # Explicit command-phase cancellation fixture.
	_check(_body().sampled_action != "grenade_throw", "SWEEP cancels previous ALERT tool event")
	# Read the actual automatic-grenade recording, then seek away and back.
	var source_log := BattleLog.new()
	source_log.attempt_id = str(recorded.attempt_id)
	source_log.wave_id = int(recorded.wave_id)
	source_log.snapshots = [recorded]
	source_log.terminal_tick = BattleLog.record_tick(recorded) + 3
	main.phase = main.Phase.REPLAY
	main.replay.bind(source_log)
	var signatures := {}
	for seek in [BattleLog.record_tick(recorded), source_log.terminal_tick, BattleLog.record_tick(recorded)]:
		main.replay.set_tick(seek)
		body = _body()
		_check(body.sampled_action == "grenade_throw" and str(body.get_meta("pose_event_id")).begins_with(str(recorded.data.utility_scope_id)), "normal ALERT record restores original tool event")
		if signatures.has(seek):
			_check(signatures[seek] == _bones(body), "forward/back actual ALERT seek reproduces all 20 bones")
		else:
			signatures[seek] = _bones(body)
	await _capture("history_auto_grenade")
	var frame: Dictionary = view.frame.duplicate(true)
	var item := _operator(frame)
	var cutoff: int = item.utility_pose.battle_seq_floor
	var fire := {"schema": 2, "attempt_id": frame.attempt_id, "wave_id": frame.wave_id,
		"timeline_tick": frame.tick, "seq": cutoff + 1, "actor_id": item.id, "type": "fire", "event_id": "%s:%d:%d" % [frame.attempt_id, frame.wave_id, cutoff + 1]}
	frame.events = [fire]
	_check(Pose.sample(item, frame, "ops").action != "grenade_throw", "later actual shot identity interrupts sparse recorded tool pose")
	frame.events[0].timeline_tick += 1
	_check(Pose.sample(item, frame, "ops").action == "grenade_throw", "future shot cannot cancel earlier historical tool")
	frame.events[0].timeline_tick -= 1
	frame.events[0].wave_id += 1
	_check(Pose.sample(item, frame, "ops").action == "grenade_throw", "another wave's shot cannot cancel this tool event")
	completed_stages += 1


func _mask_contract() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	for role in ["operator_rifle", "operator_mg", "operator_scout"]:
		var body := Actor.new()
		stage.add_child(body)
		for lod in 3:
			_check(body.set_asset(role, lod, Pose.ASSET_REVISION), "real R5 role/LOD import " + role + str(lod))
			for action in Utility.CLIPS:
				for stance in [0, 1]:
					for moving in [false, true]:
						var item := {"id": 1, "pos": Vector2.ZERO, "facing": 90.0, "weapon": "m1911", "visual_weapon": "m1911", "alive": true, "moving": moving, "stance": stance}
						item.utility_pose = {"schema": 1, "action": action, "since": 1.0, "scope_id": "fixture", "event_id": "fixture:0:0", "seq": 0, "wave_id": 0, "attempt_id": "fixture-attempt", "phase": 0, "clock_domain": "command", "actor_id": 1, "weapon": "m1911", "target": Vector2(100, 0)}
						var frame := {"animation_schema": Pose.FORMAT, "actor_asset_revision": Pose.ASSET_REVISION, "pose_clock_s": 1.15, "utility_scope_id": "fixture", "attempt_id": "fixture-attempt", "wave_id": 0, "recorded_phase": 0, "pose_clock_domain": "command", "events": []}
						var pose := Pose.sample(item, frame, "ops")
						if action == "decoy_place" and moving:
							_check(pose.action != action, "moving actor cancels full-body decoy crouch")
							continue
						_check(pose.action == action and body.mount_item(str(pose.visual_item)) and body.sample_layers(pose), "real utility clip uses copied action " + role + str(lod) + action)
						var bones := _bones(body)
						if pose.has("upper_action"):
							body.sample_pose(pose.base_action, pose.base_seconds)
							var base := _bones(body)
							for i in body.skeleton.get_bone_count():
								if body.skeleton.get_bone_name(i) not in Upper.UPPER_BONES:
									_check(bones[i + 4].is_equal_approx(base[i + 4]), "eight locomotion bones survive utility mask " + action)
							body.sample_layers(pose)
							_check(_bones(body) == bones, "masked action samples deterministically after reset")
						if action == "knife_stab":
							_check(body.bone_socket("weapon_hand").position.distance_to(body.item_socket("grip").transform.origin) < 0.0001 and not body.item_socket("tip").is_empty(), "actual knife tip/grip remain valid through utility yaw/mask")
						_check(body.position == Vector3.ZERO and body.scale == Vector3.ONE and body.skeleton.get_bone_global_pose(body.skeleton.find_bone("root")).origin.length() < 0.00001, "utility has no world/root travel or extra 20cm offset")
		body.free()
	stage.free()
	completed_stages += 1


func _equip_roundtrip() -> void:
	_reset()
	var op = main.selected
	var sentry = main.c2.sentries.front()
	op.global_position = sentry.backstab_world()
	op.facing_deg = sentry.facing_deg
	var original: String = op.weapon_id
	_check(main.c2._skill_knife(op) and _body().sampled_action == "knife_stab", "roundtrip fixture starts actual C2 knife hit")
	op.pack.add_item("mg42", 1)
	op.pack.add_item(original, 1)
	# Two real UI handlers in one frame, with no presentation capture between.
	main._on_pack_equip("mg42")
	_check(op.weapon_id == "mg42", "first real equip handler changes weapon")
	main._on_pack_equip(original)
	_check(op.weapon_id == original, "second real equip handler restores original weapon")
	_check(_body().sampled_action != "knife_stab", "same-frame equipment roundtrip cannot resurrect interrupted utility")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	if OS.get_environment("AMBUSH_UTILITY_TEST_SCOPE") == "equip_roundtrip":
		_equip_roundtrip()
		print("UTILITY_EQUIP_ROUNDTRIP checks=", checks, " failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	_mask_contract()
	await _actual_command()
	await _actual_alert()
	_check(completed_stages == 3, "mask and both interaction stages reach their final assertion")
	_equip_roundtrip()
	root.get_node("AudioDirector").pause_for_background()
	var report := {"checks": checks, "failures": failures, "captures": captures,
		"actor_source": Pose.ASSET_REVISION, "scope": "three-role/three-LOD mask fixtures; actual SCOUT C2 knife/throw/decoy and ALERT auto-grenade/melee; copied history. Not corpse pairing, full campaign or device."}
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/r5-utility-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("UTILITY_RUNTIME_OK" if failures == 0 else "UTILITY_RUNTIME_FAILED", " checks=", checks, " failures=", failures, " captures=", captures.size())
	quit(0 if failures == 0 else 1)
