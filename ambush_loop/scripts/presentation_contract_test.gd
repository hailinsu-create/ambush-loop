extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Picker := preload("res://scripts/presentation/world_picker_3d.gd")
const Commands := preload("res://scripts/input/command_router.gd")
var failures := 0
var checks := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PRESENTATION_CONTRACT: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	var view = main.presentation_3d
	_check(view != null, "3D scene binds presentation")
	if view == null:
		quit(1)
		return
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	view.refresh()
	var rig = view.rig
	var state: Dictionary = ViewState.capture(main)
	_check(state.is_read_only() and state.ops.is_read_only() and state.ops[0].is_read_only(), "frame containers are read only")
	_check(_plain_values(state), "view state contains no live objects")
	var hp: float = main.operators[0].hp
	main.operators[0].hp = hp - 1.0
	_check(state.ops[0].hp == hp, "retained frame is independent of actor changes")
	main.operators[0].hp = hp
	var bytes: PackedByteArray = state.blocked
	bytes[0] = 0
	_check(main.grid.blocked[0] == 1, "grid bytes do not alias logic")
	state = ViewState.capture(main)
	_check(main.get_node("World").visible and main.operators[0].visible, "render gate preserves logical visibility")
	_check(main.visible == (not OS.has_feature("web")), "only Web suppresses the legacy root canvas")
	_check(main.get_node("HUD/Root").is_visible_in_tree(), "independent HUD remains visible through render gate")
	_check(main.process_mode == Node.PROCESS_MODE_INHERIT, "render gate keeps simulation processing mode")
	for y in 22:
		for x in 40:
			var pos := Vector2(x * 32 + 16, y * 32 + 16)
			_check(Space.world_to_logic(Space.logic_to_world(pos)).distance_to(pos) < 0.001, "cell round trip %s" % Vector2i(x, y))
	_check(Space.contains_logic(Vector2.ZERO), "zero coordinate is valid")
	_check(not Space.contains_logic(Vector2.INF) and not Space.contains_logic(Vector2(-1, 0)), "reject nonfinite and outside coordinates")
	for angle in [0.0, 90.0, 180.0, 270.0]:
		var front := Basis(Vector3.UP, Space.facing_yaw(angle)) * Vector3.FORWARD
		_check(front.distance_to(Space.facing_direction(angle)) < 0.0001, "model forward aligns with world heading")
	var ground_frame := {"blocked": state.blocked}
	var samples := 0
	for yaw in range(0, 360, 45):
		for pitch in [35.0, 55.0, 65.0]:
			for size in [12.0, 24.0, 36.0]:
				rig.yaw_deg = yaw
				rig.pitch_deg = pitch
				rig.view_size = size
				rig.apply_pose()
				for y in 22:
					for x in 40:
						var pos := Vector2(x * 32 + 16, y * 32 + 16)
						var screen: Vector2 = rig.project_logic(pos)
						if not root.get_visible_rect().has_point(screen):
							continue
						var hit := Picker.pick(rig.camera, screen, ground_frame)
						var valid: bool = not main.grid.is_blocked(x, y)
						_check(bool(hit.get("valid", false)) == valid, "ray cell validity %s yaw=%d pitch=%d size=%d" % [Vector2i(x, y), yaw, pitch, size])
						if valid:
							_check(hit.pos.distance_to(pos) < 0.02, "projected ray returns logical ground anchor")
						samples += 1
				for op in state.ops:
					var screen: Vector2 = rig.project_logic(op.pos, 1.2)
					if root.get_visible_rect().has_point(screen):
						var picked := Picker.pick(rig.camera, screen, {"ops": [op], "blocked": state.blocked})
						_check(bool(picked.get("valid", false)) and picked.get("id", -1) == op.id, "body ray selects ground-anchored operator")
	var before: Dictionary = main._snapshot_data().duplicate(true)
	view.refresh()
	_check(before == main._snapshot_data(), "cutaway/camera leaves units unchanged")
	_check(state.blocked == main.grid.blocked, "cutaway does not change navigation/LOS")
	main.phase = main.Phase.WATCHING
	_check(not Commands.dispatch(main, "primary", {"valid": true, "pos": Vector2(400, 400)}), "ALERT rejects placement")
	_check(not Commands.dispatch(main, "face", {"valid": true, "pos": Vector2(400, 400)}), "ALERT rejects facing")
	main.phase = main.Phase.SETUP
	_check(not Commands.dispatch(main, "primary", {"valid": false, "pos": Vector2.ZERO}), "invalid ray cannot become a command")
	_check(not Commands.dispatch(main, "primary", {"valid": true, "pos": Vector2.INF}), "nonfinite target rejected")
	_check(Commands.dispatch(main, "face", {"valid": true, "pos": main.selected.global_position + Vector2(0, 32)}), "valid facing command accepted")
	_check(is_equal_approx(main.selected.facing_deg, 90.0), "facing is independent of camera yaw")
	print("PRESENTATION_PICK_MATRIX samples=", samples, " poses=72")
	var static_battle := _battle(main, false, 60, 1.0)
	var rotating_battle := _battle(main, true, 30, 1.0)
	var fast_battle := _battle(main, true, 60, 2.0)
	_check(static_battle == rotating_battle, "30 FPS rotating and 60 FPS static outcomes/events are identical")
	_check(static_battle == fast_battle, "2x presentation keeps identical simulation result")
	print("PRESENTATION_BATTLE tick=", main.sim.tick, " events=", main.battle_log.events.size())
	var live_before: Dictionary = main._snapshot_data().duplicate(true)
	main._on_replay_pressed()
	for tick in [0, main.replay.max_tick() / 2, main.replay.max_tick(), 0]:
		main.replay.set_tick(tick)
		main._apply_replay_scrub()
		view.refresh()
		var historical: Dictionary = ViewState.capture(main)
		_check(historical.replay, "replay frame marked historical")
		for i in main.operators.size():
			_check(main.operators[i].hp == live_before.ops[i].hp and main.operators[i].ammo == live_before.ops[i].ammo,
				"scrubbing never changes live HP/ammo")
		for op in historical.ops:
			var recorded: Array = main.replay.snapshot_at_or_before(tick).data.ops
			var matching: Array = recorded.filter(func(item: Dictionary) -> bool: return item.id == op.id)
			_check(op.weapon == matching[0].weapon, "replay uses recorded equipment")
	main._exit_replay_to_setup()
	view.refresh()
	_check(main.phase == main.Phase.SETUP, "exit replay restores setup")
	if failures == 0:
		print("PRESENTATION_CONTRACT_OK checks=", checks)
	else:
		print("PRESENTATION_CONTRACT_FAILED failures=", failures, " checks=", checks)
	quit(0 if failures == 0 else 1)


func _plain_values(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		for child in value.values():
			if not _plain_values(child):
				return false
	elif value is Array:
		for child in value:
			if not _plain_values(child):
				return false
	return true


func _battle(main: Node, rotate: bool, fps: int, speed: float) -> Dictionary:
	main._load_level("yard", false, false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.raid_force_alarm()
	main.sim.set_speed(speed)
	var frames := 0
	while main.phase == main.Phase.WATCHING and frames < 2000:
		var steps: int = main.sim.steps_for_frame(1.0 / fps)
		for i in steps:
			if main.phase == main.Phase.WATCHING:
				main._sim_tick()
		if rotate:
			main.presentation_3d.rig.yaw_deg = frames * 3.0
			main.presentation_3d.rig.apply_pose()
			main.presentation_3d.refresh()
		frames += 1
	_check(main.phase == main.Phase.SWEEP, "reference wave clears")
	var events: Array = main.battle_log.events.duplicate(true)
	_check(events.all(func(ev: Dictionary) -> bool: return _fx_identity_matches(ev)), "original FX identities bind to their recording event before normalization")
	# Independent recordings have independent identities, but identical combat.
	for ev in events:
		ev.erase("attempt_id")
		ev.erase("event_id")
	var final: Dictionary = main._snapshot_data().duplicate(true)
	var scope: String = final.get("utility_scope_id", "")
	_check(not scope.is_empty() and main.battle_log.snapshots.all(func(snap: Dictionary) -> bool: return str(snap.data.get("utility_scope_id", "")) == scope), "real wave preserves its independent utility recording identity")
	# All gameplay/visual values still participate in cross-FPS/2x equivalence.
	final.erase("utility_scope_id")
	_normalize_identity(events, scope, main.battle_log.attempt_id)
	_normalize_identity(final, scope, main.battle_log.attempt_id)
	return {"phase": int(main.phase), "tick": main.sim.tick, "state": final, "events": events}


func _fx_identity_matches(event: Dictionary) -> bool:
	var fx: Dictionary = event.get("payload", {}).get("fx", {})
	if fx.is_empty():
		return true
	return fx.get("attempt_id") == event.get("attempt_id") and fx.get("wave_id") == event.get("wave_id") and fx.get("seq") == event.get("seq") and fx.get("event_id") == event.get("event_id")


func _normalize_identity(value: Variant, scope: String, attempt: String) -> void:
	# Retain every body field and relative ID while normalizing only deliberately
	# random attempt/scope prefixes across independent FPS/2x runs.
	if value is Dictionary:
		for key in value:
			if value[key] is String:
				value[key] = value[key].replace(scope, "<scope>") if not scope.is_empty() else value[key]
				if not attempt.is_empty():
					value[key] = value[key].replace(attempt, "<attempt>")
			else:
				_normalize_identity(value[key], scope, attempt)
	elif value is Array:
		for item in value:
			_normalize_identity(item, scope, attempt)
