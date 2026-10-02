extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
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
		push_error("VISUAL_SNAPSHOT: " + message)


func _plain(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		for child in value.values():
			if not _plain(child):
				return false
	elif value is Array:
		for child in value:
			if not _plain(child):
				return false
	return true


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	var initial_kit: String = main.operators[1].weapon_id
	main.operators[1].receive_item("m1911", 5)
	main.operators[1].equip_from_pack(initial_kit)
	main.raid_force_alarm()
	var first: Dictionary = main.battle_log.snapshots.front()
	_check(first.data.visual_schema == 1 and _plain(first.data), "versioned history contains only plain values")
	var limit := 0
	while main.phase == main.Phase.WATCHING and limit < 3000:
		main._sim_tick()
		limit += 1
	_check(main.phase == main.Phase.SWEEP, "actual first wave reaches legal equipment phase")
	first = main.battle_log.snapshots.filter(func(s: Dictionary) -> bool: return s.tick == 6).front()
	main._select_op(1)
	main._on_pack_equip("m1911")
	main.selected.toggle_crouch()
	main._toggle_auto_grenade()
	var loot = main.loot_piles.front()
	var captured: Dictionary = main._snapshot_data()
	var old_id: String = captured.loot[0].id
	main.loot_piles.erase(loot)
	loot.queue_free()
	main._spawn_loot_at(Vector2(700, 400), 2, "ammo")
	var new_data: Dictionary = main._snapshot_data()
	_check(new_data.loot.back().id != old_id, "removing an object cannot reuse its recording identity")
	main._on_sweep_commit()
	for i in 120:
		main._sim_tick()
	var second: Dictionary = main.battle_log.snapshots.filter(func(s: Dictionary) -> bool: return s.wave_id == 1).back()
	_check(first.data.ops[1].weapon == initial_kit and second.data.ops[1].weapon == "m1911", "different waves retain their actual equipment")
	_check(second.data.ops[1].stance == OperatorUnit.Stance.CROUCH and not second.data.ops[1].auto_grenade, "pose and grenade policy are recorded")
	_check(second.data.ops[1].inventory.size() > 0 and second.data.ops[1].ammo_pool.has("pistol"), "backpack and ammo pools are copied")
	_check(not second.data.enemies.is_empty() and second.data.enemies[0].has("facing"), "enemies record orientation and action state")
	_check(second.data.has("sentries") and second.data.covers.size() == main.cover_slots.size() and second.data.has("barrels"), "historical environment, patrols and objects are recorded")
	_tool_contract(main)
	main.battle_log.add_snapshot(main.sim.tick, main._snapshot_data())
	second = main.battle_log.snapshots.back()
	main._on_replay_pressed()
	main.operators[1].weapon_id = "knife"
	main.operators[0].stance = OperatorUnit.Stance.STAND
	main.operators[0].global_position = Vector2(32, 32)
	main.operators[0].pack.slots.clear()
	main.enemies[0].facing_deg = -45.0
	main.grid.blocked.fill(0)
	main.escape_world = Vector2(999, 999)
	main.cover_slots[0].global_position += Vector2(32, 0)
	main.run_id += 200
	var live: Dictionary = main._snapshot_data().duplicate(true)
	for snap in [first, second, first, second]:
		main.replay.set_tick(BattleLog.record_tick(snap))
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		var frame := ViewState.capture(main)
		_check(frame.ops[0].weapon == snap.data.ops[0].weapon and frame.ops[0].stance == snap.data.ops[0].stance, "backward/forward scrub uses historical kit and stance")
		_check(frame.blocked == snap.data.blocked and frame.escape == snap.data.escape and frame.covers == snap.data.covers, "replay world layout cannot borrow current geometry")
		_check(frame.enemies == ViewState.capture(main).enemies and (frame.enemies.is_empty() or frame.enemies[0].facing == snap.data.enemies[0].facing), "historical enemy orientation is retained")
		_check(frame.is_read_only() and frame.ops[0].inventory.is_read_only(), "nested history is immutable")
		var selection: Array = frame.ops.filter(func(o: Dictionary) -> bool: return o.id == frame.selected_id)
		_check(main.presentation_3d.focus_selected() and main.presentation_3d.rig.focus == Space.logic_to_world(selection[0].pos), "selected camera focus uses the historical position")
		var body: Node3D = main.presentation_3d.actors["ops:2"].get_node("Body")
		_check(is_equal_approx(body.scale.y, 0.7 if frame.ops[1].stance == 1 and frame.ops[1].alive else 1.0), "graybox proxy uses the historical crouch state")
	_check(live == main._snapshot_data(), "capture, rendering, focus and scrubs cannot write live state")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://build/asset_review/pr15-runtime")
		var path := "res://build/asset_review/pr15-runtime/history_schema_frame.png"
		_check(root.get_texture().get_image().save_png(path) == OK, "rendered historical frame is saved")
		print("VISUAL_SNAPSHOT_CAPTURE ", path)
	_compatibility(main)
	root.get_node("AudioDirector").pause_for_background()
	print("VISUAL_SNAPSHOT_OK" if failures == 0 else "VISUAL_SNAPSHOT_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _compatibility(main: Node) -> void:
	var log := BattleLog.new()
	log.snapshots = [{"tick": 0, "data": {"ops": [{"id": 1, "pos": Vector2(96, 96), "alive": true}], "enemies": []}}]
	main.replay.bind(log)
	main._apply_replay_scrub()
	main.presentation_3d.refresh()
	var old := ViewState.capture(main)
	_check(old.historical_defaults and old.ops[0].weapon == "" and old.ops[0].action == "idle", "old partial snapshots use neutral actor defaults")
	_check(old.blocked.is_empty() and old.covers.is_empty() and old.level_id == "" and old.selected_id == -1, "old history does not invent current world fields")
	_check(not main.presentation_3d.focus_selected(), "missing historical selection cannot focus a live operator")
	_check(main.status_label.text.contains("旧记录"), "partial history is visibly identified")
	log.snapshots[0].data["visual_schema"] = 99
	var retained: Array = log.snapshots.duplicate(true)
	main.replay.bind(log)
	main._apply_replay_scrub()
	main.presentation_3d.refresh()
	var unknown := ViewState.capture(main)
	_check(unknown.visual_unsupported and unknown.ops.is_empty() and unknown.blocked.is_empty(), "unsupported future format is not silently interpreted")
	_check(main.status_label.text.contains("暂不支持") and log.snapshots == retained, "unsupported source history remains intact with a notice")


func _tool_contract(main: Node) -> void:
	# Explicit visual fixtures validate copying/lifetimes; no simulation steps follow.
	var mine := RaidMine.new()
	main.get_node("World").add_child(mine)
	mine.global_position = Vector2(700, 450)
	main.raid_mines.append(mine)
	var grenade := RaidGrenade.new()
	main.get_node("World").add_child(grenade)
	grenade.setup(Vector2(670, 450), Vector2(740, 450), 10.0, 78.0, 78.0, "mills")
	main.raid_grenades.append(grenade)
	var decoy := RaidDecoy.new()
	main.get_node("World").add_child(decoy)
	decoy.setup()
	decoy.global_position = Vector2(740, 470)
	main.raid_decoys.append(decoy)
	var data: Dictionary = main._snapshot_data()
	_check(data.mines.back().armed and not data.mines.back().spent, "mine state is copied")
	_check(data.grenades.back().variant == "mills" and data.grenades.back().target == Vector2(740, 450), "projectile variant and trajectory are copied")
	_check(data.decoys.back().life == decoy.life and _plain(data), "tool lifetimes contain no live nodes")
	mine.spent = true
	grenade.target = Vector2.ZERO
	decoy.life = 3.0
	_check(not data.mines.back().spent and data.grenades.back().target == Vector2(740, 450) and data.decoys.back().life != decoy.life, "retained tool values do not alias live instances")
	mine.spent = false
	grenade.target = Vector2(740, 450)
	decoy.life = 1.6
