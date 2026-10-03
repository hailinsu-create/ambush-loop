extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Pose := preload("res://scripts/presentation/actor_pose.gd")
const Profiles := preload("res://scripts/presentation/firearm_pose.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
var checks := 0
var failures := 0
var configurations := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FIREARM_RUNTIME: " + message)


func _bones(body: Actor) -> Array:
	var result := []
	for i in body.skeleton.get_bone_count():
		result.append(body.skeleton.get_bone_pose(i))
	return result


func _event(type: String, gun: String, tick: int, seq: int = 0) -> Dictionary:
	var definition := WeaponCatalog.def(gun)
	return {"schema": 2, "attempt_id": "fixture", "wave_id": 2, "timeline_tick": tick, "tick": tick,
		"seq": seq, "event_id": "fixture:2:%d" % seq, "type": type, "actor_id": 1,
		"payload": {"animation_schema": 2, "visual_weapon": gun, "shot_interval_s": definition.shot_interval,
			"reload_s": definition.reload_s, "source_visual_weapon": gun, "repack_kind": "same_weapon"}}


func _frame(tick: int, events: Array = []) -> Dictionary:
	return {"schema": 2, "attempt_id": "fixture", "wave_id": 2, "tick": tick,
		"animation_schema": Pose.FORMAT, "actor_asset_revision": Pose.ASSET_REVISION,
		"pose_clock_s": float(tick) / 60.0, "recorded_phase": 1, "events": events}


func _item(gun: String) -> Dictionary:
	return {"id": 1, "visual_weapon": gun, "alive": true, "moving": false, "stance": 0,
		"locked": true, "fire_permitted": true,
		"firearm_pose": {"weapon": gun, "intent": "aim", "since": 0.0, "from_intent": "ready"}}


func _contact(body: Actor, message: String, reload: bool = false, aim: bool = true) -> void:
	var support := body.item_socket("reload_contact" if reload else "pose_support")
	_check(not support.is_empty() and body.bone_socket("support_hand").position.distance_to(support.transform.origin) < 0.015, "actual left-hand contact " + message)
	_check(body.bone_socket("weapon_hand").position.distance_to(body.item_socket("grip").transform.origin) < 0.0001, "actual right-hand grip " + message)
	if aim and not reload:
		var direction := -body.equipped.global_basis.z.normalized()
		var eye_delta: Vector3 = body.bone_socket("sight_eye").position - body.item_socket("sight").transform.origin
		_check((eye_delta - direction * eye_delta.dot(direction)).length() < 0.035, "actual eye sightline " + message)
		_check(direction.dot(-body.global_basis.z.normalized()) > 0.98, "actual gun keeps ground heading " + message)


func _sample_configuration(body: Actor, gun: String, role: String, lod: int) -> void:
	configurations += 1
	_check(body.set_asset(role, lod, Pose.ASSET_REVISION) and body.mount_item(gun), "actual current rig and gun " + role + gun + str(lod))
	var item := _item(gun)
	var frame := _frame(120)
	var profile := Profiles.profile(gun)
	for stance in [0, 1]:
		item.stance = stance
		for moving in [false, true]:
			item.moving = moving
			var pose := Pose.sample(item, frame, "ops")
			body.sample_pose(pose.base_action, pose.base_seconds)
			var base := _bones(body)
			_check(body.sample_layers(pose) and body.player.current_animation == profile.clips.aim, "actual weapon-family upper clip " + gun)
			var mixed := _bones(body)
			for i in body.skeleton.get_bone_count():
				if body.skeleton.get_bone_name(i) not in Profiles.UPPER_BONES:
					_check(mixed[i].is_equal_approx(base[i]) and body.scale == Vector3.ONE, "locomotion hips/legs/root survive upper mask " + gun)
			_contact(body, gun + ":stance=%d:moving=%s" % [stance, moving])
			var frozen := _bones(body)
			body.sample_layers(pose)
			_check(frozen == _bones(body), "same historical pose samples identically " + gun)
	item.stance = 0
	item.moving = false
	item.firearm_pose.since = 119.0 / 60.0
	var raised := Pose.sample(item, frame, "ops")
	_check(raised.upper_action == profile.clips.raise and body.sample_layers(raised), "recorded ready-to-aim raises " + gun)
	item.firearm_pose.intent = "ready"
	item.firearm_pose.from_intent = "aim"
	var lowered := Pose.sample(item, frame, "ops")
	_check(lowered.upper_action == profile.clips.lower and body.sample_layers(lowered), "recorded mid-action cancel lowers " + gun)
	item.firearm_pose = {"weapon": gun, "intent": "aim", "since": 0.0, "from_intent": "ready"}
	var shot := _event("fire", gun, 100)
	var interval := float(shot.payload.shot_interval_s)
	var pulse := minf(interval, Pose.FIRE_SECONDS)
	for delta in [0, maxi(int(pulse * 60.0 * 0.5), 1)]:
		var fire_frame := _frame(100 + delta, [shot])
		var fire := Pose.sample(item, fire_frame, "ops")
		_check(fire.action == "fire" and fire.event_id == shot.event_id and fire.upper_action == profile.clips.fire and is_equal_approx(fire.upper_seconds, float(delta) / 60.0 * Pose.FIRE_SECONDS / pulse), "actual cadence scales visual pulse without a new cooldown " + gun)
		_check(body.sample_layers(fire), "sample actual rapid-fire family clip " + gun)
		_contact(body, "fire:" + gun)
	var second := _event("fire", gun, 105, 1)
	var repeated := Pose.sample(item, _frame(105, [shot, second]), "ops")
	_check(repeated.event_id == second.event_id and repeated.upper_seconds == 0.0, "newer repeated shot restarts its own stable event " + gun)
	var past := Pose.sample(item, _frame(100, [shot, second]), "ops")
	_check(past.event_id == shot.event_id, "future shot cannot steal past pulse " + gun)
	var foreign := second.duplicate(true)
	foreign.attempt_id = "other"
	_check(Pose.sample(item, _frame(105, [shot, foreign]), "ops").event_id != foreign.event_id, "foreign attempt cannot select gun pulse " + gun)
	var reload := _event("repack", gun, 100, 1)
	var mid_tick := 100 + int(round((pulse + (float(reload.payload.reload_s) - pulse) * 0.5) * 60.0))
	var contact := Pose.sample(item, _frame(mid_tick, [shot, reload]), "ops")
	_check(contact.action == "reload_contact" and contact.event_id == reload.event_id and contact.upper_action == profile.clips.reload_contact and body.sample_layers(contact), "actual same-gun repack event selects contact without ammo guessing " + gun)
	_contact(body, "reload:" + gun, true, false)
	_check(Pose.sample(item, _frame(100, [shot, reload]), "ops").action == "fire", "last bullet pulse precedes repack contact " + gun)
	reload.payload.repack_kind = "weapon_switch"
	_check(Pose.sample(item, _frame(mid_tick, [shot, reload]), "ops").action != "reload_contact", "pistol fallback is not a reload mechanism " + gun)
	item.fire_permitted = false
	_check(Pose.sample(item, _frame(100, [shot]), "ops").action != "fire", "hold-fire cancellation rejects prior pulse " + gun)
	item.fire_permitted = true
	var sweep := _frame(100, [shot])
	sweep.recorded_phase = 5
	_check(Pose.sample(item, sweep, "ops").action != "fire", "SWEEP cancels terminal shot despite frozen battle tick " + gun)
	item.visual_weapon = "knife"
	_check(Pose.sample(item, _frame(100, [shot]), "ops").action != "fire", "unknown/new weapon cannot inherit old gun clip " + gun)
	item = _item("m1911" if gun != "m1911" else "kar98k")
	_check(Pose.sample(item, _frame(100, [shot]), "ops").event_id == "", "weapon swap cancels other gun event " + gun)
	item = _item(gun)
	var malformed := shot.duplicate(true)
	malformed.payload = []
	_check(Pose.sample(item, _frame(100, [malformed]), "ops").event_id == "", "malformed event payload cannot crash or invent a gun pose " + gun)
	item.firearm_pose = []
	_check(Pose.sample(item, _frame(100, [shot]), "ops").fallback == "firearm_record_missing_or_invalid", "invalid copied pose state uses explicit fallback " + gun)


func _capture(main: Node, name: String) -> void:
	# This fixture advances sim ticks with main._process disabled. Refresh the
	# normal HUD path before capture so labels do not remain at tick zero.
	main._update_hud()
	main.presentation_3d.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var dir := "res://build/asset_review/pr15-runtime"
	DirAccess.make_dir_recursive_absolute(dir)
	_check(root.get_texture().get_image().save_png(dir.path_join("r4_runtime_" + name + ".png")) == OK, "capture actual runtime " + name)


func _actual_battle(main: Node) -> void:
	main.raid_prepare_ref([2, 1, 5], [180.0, 90.0, 180.0], {"grenades": 0, "mines": 0})
	var mg = main.operators[1]
	mg.apply_weapon("mg42", true) # Explicit authored gun fixture, in SCOUT.
	main.operators[0].set_fire_mode(OperatorUnit.FireMode.HOLD_FOR_AMBUSH)
	main.operators[2].set_fire_mode(OperatorUnit.FireMode.HOLD_FOR_AMBUSH)
	main.raid_force_alarm()
	var ticks := 0
	var shots: Array = []
	while main.phase == main.Phase.WATCHING and shots.size() < 2 and ticks < 3000:
		main._sim_tick()
		ticks += 1
		shots = main.battle_log.events.filter(func(ev: Dictionary) -> bool: return ev.type == "fire" and ev.actor_id == mg.op_id)
	_check(shots.size() >= 2 and main.phase == main.Phase.WATCHING, "real frozen ALERT fires repeated MG42 shots")
	if shots.size() < 2 or main.phase != main.Phase.WATCHING:
		print("FIREARM_ACTUAL_DIAGNOSE phase=", main.phase, " ticks=", ticks, " weapon=", mg.weapon_id, " shots=", shots.size(), " alive=", mg.alive, " ammo=", mg.ammo, " position=", mg.global_position, " facing=", mg.facing_deg, " permitted=", mg.fire_permitted, " deny=", mg.last_deny)
		return
	_check(shots[0].payload.visual_weapon == "mg42" and is_equal_approx(shots[0].payload.shot_interval_s, WeaponCatalog.def("mg42").shot_interval) and BattleLog.record_tick(shots[1]) - BattleLog.record_tick(shots[0]) <= 4, "real gun metadata/cadence are captured before ammo fallback")
	main.battle_log.add_snapshot(main.sim.tick, main._snapshot_data())
	main.presentation_3d.refresh()
	var body: Actor = main.presentation_3d.actors["ops:2"].get_node("Body")
	_check(body._layers.upper_action == "fire_mg" and body.get_meta("pose_event_id") == shots.back().event_id, "real presenter selects recorded MG clip and latest event")
	await _capture(main, "actual_mg")
	var before := _bones(body)
	main.sim.paused = true
	for i in 3:
		main._process(0.2)
		main.presentation_3d.refresh()
		await process_frame
	_check(before == _bones(body), "real paused ALERT holds all blended bone poses")
	main.sim.paused = false
	var recorded: Dictionary = main.battle_log.snapshots.back().duplicate(true)
	mg.ammo = 1 # Explicit empty-gun mechanic fixture, not a balance change.
	mg.has_ammo_pack = false
	mg.ammo_pool["pistol"] = 4
	mg.shot_cd = 0.0
	var log_start: int = main.battle_log.events.size()
	while main.phase == main.Phase.WATCHING and mg.weapon_id == "mg42" and ticks < 4000:
		main._sim_tick()
		ticks += 1
	_check(mg.weapon_id == "pistol", "real existing empty-gun fallback immediately switches pistol")
	var repacks: Array = main.battle_log.events.slice(log_start).filter(func(ev: Dictionary) -> bool: return ev.type == "repack" and ev.actor_id == mg.op_id)
	_check(not repacks.is_empty() and repacks.back().payload.repack_kind == "weapon_switch" and repacks.back().payload.source_visual_weapon == "mg42" and repacks.back().payload.visual_weapon == "m1911", "real fallback metadata keeps old and new visual gun identities")
	main.presentation_3d.refresh()
	body = main.presentation_3d.actors["ops:2"].get_node("Body")
	_check(body.equipped_id == "m1911" and body.get_meta("pose_event_id") == "" and body.sampled_action != "reload_contact", "real swap drops old MG fire/reload pose immediately")
	_check(main.sfx.last_cue == "fire_mg42", "last MG bullet keeps its actual pre-fallback sound")
	await _capture(main, "actual_fallback")
	main._on_replay_pressed()
	var live_copy: Dictionary = main._snapshot_data().duplicate(true)
	var signature: Array = []
	var recorded_time: int = main.replay.playback_time(recorded)
	for tick in [recorded_time, main.replay.max_tick(), recorded_time]:
		main.replay.set_tick(tick)
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		if tick == recorded_time:
			body = main.presentation_3d.actors["ops:2"].get_node("Body")
			_check(body.equipped_id == "mg42" and body._layers.upper_action == "fire_mg", "actual backward seek restores historical MG rather than current pistol")
			if signature.is_empty():
				signature = _bones(body)
			else:
				_check(signature == _bones(body), "actual forward/back seek reproduces mixed bones exactly")
	_check(live_copy == main._snapshot_data(), "actual history seek cannot change current equipment/combat state")
	await _capture(main, "actual_history_mg")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("FIREARM_RUNTIME requires actual rendered bone/marker and battlefield capture checks")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	root.get_node("AudioDirector").pause_for_background()
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	var stage := Node3D.new()
	root.add_child(stage)
	for role in ["operator_rifle", "operator_mg", "operator_scout"]:
		var body := Actor.new()
		stage.add_child(body)
		for lod in 3:
			for gun in WeaponCatalog.model_ids():
				_sample_configuration(body, gun, role, lod)
		body.free()
	_check(configurations == 90, "all ten guns, three operator rigs and three LODs exercised")
	_check(not Assets.has_asset("operator_rifle", 0, "unknown") and not Pose.supported({"animation_schema": 2, "actor_asset_revision": Pose.ASSET_REVISION, "pose_clock_s": "invalid"}), "unknown resource version and non-numeric record clock refuse")
	for gun in ["thompson", "bar", "mg42"]:
		var body := Actor.new()
		stage.add_child(body)
		for lod in 2:
			body.set_asset("operator_mg", lod, Pose.LEGACY_REVISION)
			body.mount_item(gun)
			var old_path := "res://art/v2/replay_r3/%s_lod%d.glb" % [gun, lod]
			_check(body.equipped.get_meta("asset_resource_path") == old_path and body.item_socket("pose_support").is_empty(), "actual R3 gun instance retains its original resource/marker set " + gun)
			var record := Assets.asset_record(gun)
			_check(FileAccess.get_sha256(old_path) == record.legacy_r3_lods[lod].sha256, "exact old R3 gun bytes " + gun)
		body.free()
	stage.free()
	await _actual_battle(main)
	root.get_node("AudioDirector").pause_for_background()
	await process_frame
	print("FIREARM_RUNTIME_OK" if failures == 0 else "FIREARM_RUNTIME_FAILED", " checks=", checks, " configurations=", configurations, " failures=", failures)
	quit(0 if failures == 0 else 1)
