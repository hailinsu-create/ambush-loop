extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const Pose := preload("res://scripts/presentation/actor_pose.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMMAND_POSE_CLOCK: " + message)


func _bones(body: Actor) -> Array:
	var result: Array = [body.sampled_action, body.sampled_time, body.global_transform]
	for i in body.skeleton.get_bone_count():
		result.append(body.skeleton.get_bone_pose(i))
	return result


func _capture(main: Node, pos: Vector2, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	main._update_hud()
	var view = main.presentation_3d
	view.rig.focus = Space.logic_to_world(pos)
	view.rig.view_size = 12.0
	view.rig.yaw_deg = 180.0
	view.rig.apply_pose()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/command_death_" + name + ".png"
	_check(root.get_texture().get_image().save_png(path) == OK, "save actual command death framebuffer " + name)


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
	main.raid_force_alarm()
	var count := 0
	while main.phase == main.Phase.WATCHING and count < 5000:
		main._sim_tick()
		count += 1
	_check(main.phase == main.Phase.SWEEP, "actual first yard wave reaches SWEEP")
	if main.phase != main.Phase.SWEEP:
		quit(2)
		return
	view.refresh()
	var tick: int = main.sim.tick
	var killed: Dictionary = {}
	for event in main.battle_log.events:
		if event.type == "kill":
			killed = event
	_check(not killed.is_empty(), "actual recent death event exists")
	var key := "enemies:%d" % int(killed.actor_id)
	var dead = view.actors[key].get_node("Body") as Actor
	var first_time: float = dead.sampled_time
	var first_bones := _bones(dead)
	var first: Dictionary = main._snapshot_data().duplicate(true)
	await _capture(main, killed.position, "initial")
	main._select_op(2)
	var scout = main.selected
	var from: Vector2 = scout.global_position
	var target: Vector2 = main.grid.cell_to_world_center(Vector2i(32, 16))
	main._command_move_selected(target)
	_check(scout.is_moving(), "living scout legally accepts four-cell SWEEP move")
	for i in 24:
		main._process(1.0 / 60.0)
	view.refresh()
	var moving = view.actors["ops:3"].get_node("Body") as Actor
	print("COMMAND_MOVE_ACTUAL from=", from, " now=", scout.global_position, " action=", moving.sampled_action, " battle_tick=", main.sim.tick)
	_check(scout.global_position != from and moving.sampled_action in ["walk", "run", "crouch_walk"], "actual moving scout does not retain terminal fire")
	var mid_time: float = dead.sampled_time
	_check(main.sim.tick == tick and mid_time > first_time + 0.35, "SWEEP death progresses while simulation tick stays frozen")
	_check(_bones(dead) != first_bones, "actual imported death bones move after entering SWEEP")
	for i in 24:
		main._process(1.0 / 60.0)
	view.refresh()
	_check(dead.sampled_time > mid_time + 0.35, "death continues on the command presentation clock")
	var last: Dictionary = main._snapshot_data().duplicate(true)
	await _capture(main, killed.position, "after_0800")
	var live_bones := _bones(dead)
	# The real pause menu must gate command simulation and pose time.
	main._toggle_pause_menu()
	var paused: Dictionary = main._snapshot_data().duplicate(true)
	main._process(0.2)
	await create_timer(0.15).timeout
	view.refresh()
	_check(main._snapshot_data() == paused and _bones(dead) == live_bones, "actual paused SWEEP holds data and bone sample")
	main.pause_overlay.dismiss()
	main._process(0.4)
	view.refresh()
	_check(dead.sampled_time > float(live_bones[1]) + 0.35, "resume continues the recent death")
	main.handle_app_focus_out()
	var suspended: Dictionary = main._snapshot_data().duplicate(true)
	var suspended_pose := _bones(dead)
	main._process(0.2)
	view.refresh()
	_check(main._snapshot_data() == suspended and _bones(dead) == suspended_pose, "background SWEEP holds command state and sampled age")
	main.handle_app_focus_in()
	main._process(0.2)
	view.refresh()
	_check(main.sim.tick == tick and float(main._snapshot_data().get("event_pose_clock_s", 0.0)) > float(suspended.get("event_pose_clock_s", 0.0)) + 0.15, "focus return resumes command display without changing battle tick")
	# Retained records have enough timing metadata to reproduce command samples;
	# no current host timer is used when each historical record is loaded.
	var retained: Dictionary = main._snapshot_data().duplicate(true)
	var signatures := {}
	for data in [first, last, first, last]:
		var log := BattleLog.new()
		log.attempt_id = main.battle_log.attempt_id
		log.wave_id = main.battle_log.wave_id
		log.events = main.battle_log.events.duplicate(true)
		log.add_snapshot(tick, data)
		main.replay.bind(log)
		main.replay.set_tick(tick)
		main.phase = main.Phase.REPLAY
		view.refresh()
		var historical = view.actors[key].get_node("Body") as Actor
		var signature := _bones(historical)
		var stamp: String = str(data.pose_clock_s)
		if signatures.has(stamp):
			_check(signatures[stamp] == signature, "back/forward same command record has identical bones")
		else:
			signatures[stamp] = signature
		_check(is_equal_approx(historical.sampled_time, Pose.sample(view.frame.enemies.filter(func(e: Dictionary) -> bool: return e.id == killed.actor_id).front(), view.frame, "enemies").seconds), "historical death uses only copied event age")
	_check(signatures.values()[0] != signatures.values()[1], "different retained command times replay different falling poses")
	main.phase = main.Phase.SWEEP
	_check(retained == main._snapshot_data(), "history never changes live command clock or nodes")
	# Old R3 command records lacked a cross-domain age. They finish death and
	# cancel the old shot rather than holding an unrecoverable intermediate pose.
	var old: Dictionary = view.frame.duplicate(true)
	old.animation_schema = 1
	old.actor_asset_revision = Pose.LEGACY_REVISION
	old.recorded_phase = 5
	old.erase("event_pose_schema")
	old.erase("event_pose_clock_s")
	var op: Dictionary = old.ops[0].duplicate(true)
	op.alive = true
	op.searching = false
	op.hauling = false
	op.moving = true
	op.stance = 0
	var event := {"schema": 2, "attempt_id": old.attempt_id, "wave_id": old.wave_id, "tick": old.tick, "timeline_tick": old.tick, "seq": 500, "event_id": "old-shot", "type": "fire", "actor_id": op.id, "payload": {}}
	old.events = [event]
	_check(Pose.sample(op, old, "ops").action == "walk", "legacy SWEEP moving actor cannot retain frozen fire")
	var corpse: Dictionary = old.enemies[0].duplicate(true)
	corpse.alive = false
	event.type = "kill"
	event.actor_id = corpse.id
	old.events = [event]
	_check(Pose.sample(corpse, old, "enemies").seconds >= 1.2, "legacy command death without age reaches safe finished pose")
	old.event_pose_schema = 9
	old.event_pose_clock_s = 900.0
	_check(Pose.sample(corpse, old, "enemies").seconds == 1.2, "future event clock cannot invent command age")
	root.get_node("AudioDirector").pause_for_background()
	print("COMMAND_POSE_CLOCK_OK" if failures == 0 else "COMMAND_POSE_CLOCK_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
