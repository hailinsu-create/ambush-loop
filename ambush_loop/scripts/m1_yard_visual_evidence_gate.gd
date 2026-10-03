extends SceneTree

## M1-I: render real yard plan A, plan B, flank failure, and retry states.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const WeaponCatalogScript := preload("res://scripts/raid/weapon_catalog.gd")
const RAMP_GROUND := Vector2i(15, 13)
const RAMP_PLATFORM := Vector2i(15, 12)
const MAX_SETUP_MOVE_STEPS := 1600
const MAX_SIM_TICKS := 6000

var failures: Array[String] = []
var capture_dir := ""


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	var data_root := OS.get_environment("AMBUSH_TEST_DATA_ROOT")
	capture_dir = data_root.get_base_dir().path_join("m1-i-screens")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(capture_dir)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		push_error("M1_I_CAPTURE_DIR_CREATE err=%d path=%s" % [mkdir_error, capture_dir])
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	var plan_a = await _open_yard("PLAN_A")
	if plan_a == null or not await _prepare_plan(plan_a, "A"):
		_finish_failed()
		return
	_expect(int(plan_a.phase) == int(plan_a.Phase.SETUP), "M1_I_PLAN_A_SETUP_RENDER_STATE")
	var plan_a_captured: bool = await _capture(plan_a, "plan-a")
	_expect(plan_a_captured, "M1_I_PLAN_A_VIEWPORT_CAPTURED")

	var plan_b = await _open_yard("PLAN_B")
	if plan_b == null or not await _prepare_plan(plan_b, "B"):
		_finish_failed()
		return
	_expect(int(plan_b.phase) == int(plan_b.Phase.SETUP), "M1_I_PLAN_B_SETUP_RENDER_STATE")
	var plan_b_captured: bool = await _capture(plan_b, "plan-b")
	_expect(plan_b_captured, "M1_I_PLAN_B_VIEWPORT_CAPTURED")

	var negative = await _open_yard("FLANK_FAILURE")
	if negative == null or not await _prepare_main_only(negative):
		_finish_failed()
		return
	negative.raid_force_alarm()
	var guard := 0
	while int(negative.phase) != int(negative.Phase.FAILED) and int(negative.phase) != int(negative.Phase.WON) and guard < MAX_SIM_TICKS:
		guard += 1
		if int(negative.phase) == int(negative.Phase.SWEEP):
			negative._on_sweep_commit()
		else:
			negative._sim_tick()
	if guard >= MAX_SIM_TICKS:
		_fail("M1_I_FLANK_FAILURE_SIM_GUARD")
		_finish_failed()
		return
	var flank_escaped := int(negative.phase) == int(negative.Phase.FAILED) and str(negative.fail_reason) == "escape" and _has_real_flank_escape(negative)
	_expect(flank_escaped, "M1_I_NEGATIVE_RENDER_IS_REAL_FLANK_ESCAPE")
	_expect(negative.result_panel != null and bool(negative.result_panel.visible), "M1_I_FAILURE_RESULT_PANEL_VISIBLE")
	var failure_captured: bool = await _capture(negative, "flank-failure")
	_expect(failure_captured, "M1_I_FAILURE_VIEWPORT_CAPTURED")

	negative._on_continue_pressed()
	await _frames(4)
	_expect(int(negative.phase) == int(negative.Phase.SETUP), "M1_I_RETRY_RENDER_IS_SETUP")
	_expect(_inventory_empty(negative) and not negative.raid_stashes.is_empty(), "M1_I_RETRY_RENDER_HAS_RESET_RESOURCES")
	negative._cam_zoom = 0.72
	negative._cam_pan = Vector2(-110.0, 100.0)
	negative._apply_cam()
	var retry_captured: bool = await _capture(negative, "retry-setup")
	_expect(retry_captured, "M1_I_RETRY_VIEWPORT_CAPTURED")

	if not failures.is_empty():
		_finish_failed()
		return
	print("M1_YARD_VISUAL_EVIDENCE_OK plan_a=1 plan_b=1 real_flank_failure=1 retry_setup=1 screenshots=4 directory=%s" % capture_dir)
	quit(0)


func _open_yard(label: String):
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		_fail("M1_I_%s_LOAD_MAIN" % label)
		return null
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null:
		_fail("M1_I_%s_MAIN_HAS_LEVEL" % label)
		return null
	if str(main.level.level_id) != "yard":
		main._load_level("yard", false, false)
		await _frames(2)
	if main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_I_%s_REAL_YARD" % label)
		return null
	if main.tutorial_overlay != null and main.tutorial_overlay.is_open():
		for _page in 3:
			main.tutorial_overlay._on_next()
		await _frames(2)
	if main.tutorial_overlay != null and main.tutorial_overlay.is_open():
		_fail("M1_I_%s_DISMISSES_TUTORIAL_THROUGH_NORMAL_PAGES" % label)
		return null
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)
		op.visible = true
	return main


func _prepare_plan(main, label: String) -> bool:
	if not await _acquire_weapons(main, label):
		return false
	var assignments: Dictionary
	if label == "A":
		assignments = {
			1: {"cell": Vector2i(30, 11), "facing": 0.0, "weapon": "rifle"},
			2: {"cell": Vector2i(12, 14), "facing": 45.0, "weapon": "mg"},
			3: {"cell": Vector2i(15, 10), "facing": 153.4, "weapon": "scout"},
		}
	else:
		assignments = {
			1: {"cell": RAMP_GROUND, "facing": 180.0, "weapon": "rifle"},
			2: {"cell": Vector2i(15, 10), "facing": 153.4, "weapon": "mg"},
			3: {"cell": Vector2i(29, 15), "facing": 0.0, "weapon": "scout"},
		}
	var high_role_id := 3 if label == "A" else 2
	var highpoint_reached_via_ramp := false
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var assignment: Dictionary = assignments[op_id]
		var destination: Vector2i = assignment["cell"]
		var path: Dictionary = await _walk_to_cell(main, op, destination)
		if not bool(path.get("ok", false)):
			_fail("M1_I_PLAN_%s_MOVE_OP%d_TO_%s" % [label, op_id, str(destination)])
			return false
		if op_id == high_role_id:
			highpoint_reached_via_ramp = bool(path.get("used_ramp", false))
		op.set_facing(float(assignment["facing"]))
		op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
		_expect(WeaponCatalogScript.family_of(str(op.weapon_id)) == WeaponCatalogScript.family_of(str(assignment["weapon"])), "M1_I_PLAN_%s_OP%d_ROLE_LOADOUT" % [label, op_id])
	_expect(highpoint_reached_via_ramp, "M1_I_PLAN_%s_HIGH_ROLE_USES_RAMP" % label)
	main.selected = _operator_by_id(main, high_role_id)
	main._cam_zoom = 0.72
	main._cam_pan = Vector2(-110.0, 100.0)
	main._apply_cam()
	main._refresh_selection_visual()
	main._update_role_cards()
	main._refresh_killzone_preview()
	return failures.is_empty()


func _prepare_main_only(main) -> bool:
	if not await _acquire_weapons(main, "FAILURE"):
		return false
	var assignments := {
		1: {"cell": Vector2i(13, 10), "facing": 90.0},
		2: {"cell": Vector2i(13, 11), "facing": 90.0},
		3: {"cell": Vector2i(13, 12), "facing": 90.0},
	}
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var assignment: Dictionary = assignments[op_id]
		var path: Dictionary = await _walk_to_cell(main, op, assignment["cell"])
		if not bool(path.get("ok", false)):
			_fail("M1_I_FAILURE_MOVE_OP%d_TO_MAIN_ROUTE" % op_id)
			return false
		op.set_facing(float(assignment["facing"]))
		op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
	main.selected = _operator_by_id(main, 1)
	main._cam_zoom = 0.72
	main._cam_pan = Vector2(-110.0, 100.0)
	main._apply_cam()
	main._refresh_selection_visual()
	main._update_role_cards()
	main._refresh_killzone_preview()
	return failures.is_empty()


func _acquire_weapons(main, label: String) -> bool:
	var kinds := {1: "rifle", 2: "mg", 3: "scout"}
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var kind := str(kinds[op_id])
		var stash = _find_stash(main, kind)
		if stash == null:
			_fail("M1_I_%s_REAL_STASH_%s" % [label, kind])
			return false
		var path: Dictionary = await _walk_to_cell(main, op, stash.cell)
		if not bool(path.get("ok", false)):
			_fail("M1_I_%s_WALK_TO_STASH_%s" % [label, kind])
			return false
		var stash_id: int = stash.get_instance_id()
		main.selected = op
		main._try_pickup_near_selected()
		if not op.is_searching() or op.search_stash != stash:
			_fail("M1_I_%s_REAL_SEARCH_%s" % [label, kind])
			return false
		main.raid_advance_search(0.8)
		await process_frame
		if is_instance_id_valid(stash_id) or WeaponCatalogScript.family_of(str(op.weapon_id)) != WeaponCatalogScript.family_of(kind):
			_fail("M1_I_%s_REAL_PICKUP_%s" % [label, kind])
			return false
	return true


func _walk_to_cell(main, op, destination: Vector2i) -> Dictionary:
	if op.grid_cell() == destination:
		return {"ok": true, "used_ramp": false}
	main.selected = op
	if not main._command_move_op(op, main.grid.cell_to_world_center(destination)):
		return {"ok": false, "used_ramp": false}
	var points: PackedVector2Array = op.move_path.duplicate()
	if not _world_path_is_safe(main.grid, points):
		return {"ok": false, "used_ramp": false}
	var used_ramp := _world_path_contains_ramp(main.grid, points)
	var guard := 0
	while op.is_moving() and guard < MAX_SETUP_MOVE_STEPS:
		guard += 1
		var before: Vector2 = op.global_position
		op.tick_move(0.20)
		if not _world_segment_is_safe(main.grid, before, op.global_position):
			return {"ok": false, "used_ramp": used_ramp}
		main._tick_command_pickups(0.20)
	if guard >= MAX_SETUP_MOVE_STEPS or op.grid_cell() != destination:
		return {"ok": false, "used_ramp": used_ramp}
	return {"ok": true, "used_ramp": used_ramp}


func _world_path_is_safe(grid, points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	for i in range(1, points.size()):
		if not grid.world_segment_traversable(points[i - 1], points[i]):
			return false
	return true


func _world_path_contains_ramp(grid, points: PackedVector2Array) -> bool:
	for i in range(1, points.size()):
		var from_cell: Vector2i = grid.world_to_cell(points[i - 1])
		var to_cell: Vector2i = grid.world_to_cell(points[i])
		if from_cell == RAMP_GROUND and to_cell == RAMP_PLATFORM:
			return true
	return false


func _world_segment_is_safe(grid, from_world: Vector2, to_world: Vector2) -> bool:
	var previous: Vector2i = grid.world_to_cell(from_world)
	var sample_count := maxi(1, int(ceil(from_world.distance_to(to_world) / 4.0)))
	for step in range(1, sample_count + 1):
		var sample: Vector2 = from_world.lerp(to_world, float(step) / float(sample_count))
		var current: Vector2i = grid.world_to_cell(sample)
		if current != previous and not grid.can_traverse_height(previous, current):
			return false
		previous = current
	return true


func _capture(main, label: String) -> bool:
	if main.map_draw != null and main.map_draw.has_method("invalidate_static_cache"):
		main.map_draw.invalidate_static_cache()
	main._refresh_selection_visual()
	main._update_role_cards()
	main._update_hud()
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() < 640 or image.get_height() < 360:
		_fail("M1_I_%s_RENDER_DIMENSIONS" % label)
		return false
	var path := capture_dir.path_join(label + ".png")
	var saved := image.save_png(path)
	var bytes := FileAccess.get_file_as_bytes(path).size() if saved == OK else 0
	_expect(saved == OK and bytes > 1000, "M1_I_%s_RENDERED_PNG_WRITTEN" % label)
	print("M1_I_SCREENSHOT name=%s path=%s size=%dx%d bytes=%d" % [label, path, image.get_width(), image.get_height(), bytes])
	return saved == OK and bytes > 1000


func _has_real_flank_escape(main) -> bool:
	var flank_spawn := false
	var escaped_id := -1
	for event in main.battle_log.events:
		if str(event.get("type", "")) == "spawn" and int(event.get("actor_id", -1)) == 3 and str(event.get("payload", {}).get("route", "")) == "flank":
			flank_spawn = true
		if str(event.get("type", "")) == "escape":
			escaped_id = int(event.get("actor_id", -1))
	return flank_spawn and escaped_id == 3


func _operator_by_id(main, op_id: int):
	for op in main.operators:
		if int(op.op_id) == op_id:
			return op
	return null


func _find_stash(main, kind: String):
	var wanted_family := WeaponCatalogScript.family_of(kind)
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		if (main.level.explicit_ammo and str(stash.kind) == wanted_family + "_ammo") or (not main.level.explicit_ammo and WeaponCatalogScript.family_of(str(stash.kind)) == wanted_family):
			return stash
	return null


func _inventory_empty(main) -> bool:
	if main.level.explicit_ammo:
		for i in main.operators.size():
			var op = main.operators[i]
			var kit: Dictionary = main.level.starting_loadouts[i]
			if str(op.weapon_id) != str(kit.weapon) or int(op.ammo) != int(kit.ammo) or op.pack.occupied() != 1:
				return false
			if op.grenades != 0 or op.mines != 0 or op.decoys != 0 or op.ammo_pool.size() != 1:
				return false
		return true
	for op in main.operators:
		if str(op.weapon_id) != "knife" or int(op.ammo) != 0 or int(op.pack.occupied()) != 0:
			return false
		if int(op.grenades) != 0 or int(op.mines) != 0 or int(op.decoys) != 0 or not op.ammo_pool.is_empty():
			return false
	return true


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _expect(ok: bool, marker: String) -> void:
	if not ok:
		_fail(marker)
	else:
		print(marker)


func _fail(marker: String) -> void:
	failures.append(marker)
	push_error(marker)


func _finish_failed() -> void:
	for failure in failures:
		push_error(failure)
	print("M1_YARD_VISUAL_EVIDENCE_FAILED count=%d" % failures.size())
	quit(2)
