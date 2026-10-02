extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const GridScript := preload("res://scripts/grid.gd")
var failures: PackedStringArray = []
var main
var op: OperatorUnit
var target: Vector2
var fixture_offset := Vector2i.ZERO


func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")
	create_timer(120.0).timeout.connect(func():
		push_error("C3_GATE_TIMEOUT")
		quit(90)
	)


func _expect(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error(label)


func _points() -> Array:
	var points: Array = []
	for marker in main.selected_coverage_draw.get_children():
		_expect(marker is Polygon2D and marker.position == marker.global_position, "C3_WORLD_NONINTERACTIVE")
		points.append(marker.position)
	points.sort()
	return points


func _expected() -> Array:
	var points: Array = []
	if main.phase != main.Phase.SETUP or main.selected == null or main.selected.melee:
		return points
	for route in main._active_routes():
		for point in main._sample_polyline(route, 16.0):
			if main.selected.in_fire_geometry(point, main.grid) and not points.has(point):
				points.append(point)
	points.sort()
	return points


func _clear_grid() -> void:
	main.grid.blocked.fill(0)
	main.grid.elevation_tier.fill(GridScript.HEIGHT_GROUND)
	main.grid.occlusion_kind.fill(GridScript.OCCLUSION_INHERIT)
	main.grid.ramp_links.clear()


func _cell(cell: Vector2i) -> Vector2:
	return main.grid.cell_to_world_center(cell + fixture_offset)


func _high(cell: Vector2i) -> void:
	cell += fixture_offset
	main.grid.elevation_tier[cell.y * GridScript.COLS + cell.x] = GridScript.HEIGHT_PLATFORM


func _block(cell: Vector2i, kind: int) -> void:
	cell += fixture_offset
	main.grid.blocked[cell.y * GridScript.COLS + cell.x] = 1
	main.grid.occlusion_kind[cell.y * GridScript.COLS + cell.x] = kind


func _fixture(high_shooter: bool, high_target: bool, block_x: int, kind: int) -> void:
	_clear_grid()
	op.slot = null
	op.stop_move()
	op.global_position = _cell(Vector2i(6, 6))
	op.apply_weapon("rifle", true)
	op.set_facing(0.0)
	main.selected = op
	target = _cell(Vector2i(10, 6))
	main.route_world = {"c3": PackedVector2Array([target])}
	main.door_locked = false
	if high_shooter:
		_high(Vector2i(6, 6))
	if high_target:
		_high(Vector2i(10, 6))
	if block_x >= 0:
		_block(Vector2i(block_x, 6), kind)
	main._refresh_killzone_preview()


func _read_state() -> Array:
	return [op.hp, op.ammo, op.facing_deg, op.global_position, main.sim.tick,
		main.battle_log.events.duplicate(true), main.route_world.duplicate(true), op.move_path.duplicate()]


func _run() -> void:
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		quit(2)
		return
	for _i in 14:
		await process_frame
	main = current_scene
	main.set_process(false)
	for unit in main.operators:
		unit.visible = false
		unit.set_process(false)
	op = main.operators[0]
	op.visible = true
	op.locked = false
	_fixture(false, false, 8, GridScript.OCCLUSION_LOW)
	_expect(_points().is_empty(), "C3_GROUND_LOW_DENY")
	_fixture(true, true, 8, GridScript.OCCLUSION_LOW)
	_expect(_points() == [target], "C3_HIGH_LOW_ALLOW")
	_fixture(true, false, 7, GridScript.OCCLUSION_LOW)
	_expect(_points() == [target], "C3_MIXED_NEAR_HIGH_ALLOW")
	_fixture(true, false, 9, GridScript.OCCLUSION_LOW)
	_expect(_points().is_empty(), "C3_MIXED_NEAR_LOW_DENY")
	_fixture(true, true, 8, GridScript.OCCLUSION_FULL)
	_expect(_points().is_empty(), "C3_HIGH_FULL_DENY")
	_fixture(false, false, -1, GridScript.OCCLUSION_FULL)
	_expect(_points() == [target], "C3_OPEN_ALLOW")
	op.range_px = 100.0
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_RANGE_DENY")
	op.apply_weapon("rifle", true)
	op.set_facing(180.0)
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_FACING_DENY")
	var other: OperatorUnit = main.operators[1]
	other.visible = true
	other.slot = null
	other.apply_weapon("rifle", true)
	other.global_position = _cell(Vector2i(8, 6))
	other.set_facing(0.0)
	_expect(other.in_fire_geometry(target, main.grid), "C3_UNSELECTED_POSITIVE_FIXTURE")
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_NOT_UNION")
	main._select_op(1)
	_expect(_points() == [target], "C3_REAL_SELECTION_REFRESH")
	main._select_op(0)
	op.apply_weapon("knife", true)
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_MELEE_SUPPRESSED")
	op.apply_weapon("rifle", true)
	op.set_facing(0.0)
	main._refresh_killzone_preview()
	var before := _read_state()
	for _i in 20:
		main._refresh_selected_coverage()
		_expect(_points() == [target], "C3_NO_ACCUMULATION")
	_expect(_read_state() == before, "C3_REFRESH_READ_ONLY")
	main._cam_pan = Vector2(30, -20)
	main._cam_zoom = 1.2
	main._apply_cam()
	_expect(_points() == [target], "C3_PAN_MEMBERSHIP_UNCHANGED")
	main._reset_cam_view()
	# Real movement changes facing away from the target; no manual refresh.
	op.set_move_path(PackedVector2Array([op.global_position, _cell(Vector2i(6, 8))]))
	main._tick_command_moves(0.1)
	_expect(op.global_position != before[3], "C3_REAL_MOVEMENT_NONVACUOUS")
	_expect(_points() == _expected() and _points().is_empty(), "C3_MOVE_AUTO_REFRESH")
	op.stop_move()
	# Real snap/deploy temporarily selects another operator, then restores op.
	_clear_grid()
	op.set_facing(180.0)
	main._refresh_killzone_preview()
	var slot: CoverSlot = main.covers.get_child(0)
	target = slot.global_position + Vector2(32, 0)
	main.route_world = {"snap-identity": PackedVector2Array([target])}
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_SNAP_ORIGINAL_DENIES_FIXTURE")
	var saved_default_face = slot.get_meta("default_face")
	slot.set_meta("default_face", 0.0)
	slot.occupied_by = null
	other.slot = null
	other.global_position = slot.global_position
	other.locked = false
	main._snap_op_to_cover_if_clicked(other)
	slot.set_meta("default_face", saved_default_face)
	_expect(other.slot == slot and main.selected == op, "C3_REAL_SNAP_IDENTITY")
	_expect(other.in_fire_geometry(target, main.grid), "C3_SNAP_TEMPORARY_POSITIVE_FIXTURE")
	_expect(_points() == _expected() and _points().is_empty(), "C3_SNAP_RESTORED_COVERAGE")
	# Phase transitions must hide AND clear, even SWEEP command phase.
	for next_phase in [main.Phase.WATCHING, main.Phase.REPLAY, main.Phase.SWEEP]:
		main.phase = next_phase
		main._apply_watch_layers()
		_expect(_points().is_empty() and not main.selected_coverage_draw.visible, "C3_PHASE_CLEAR")
	main.phase = main.Phase.SETUP
	_fixture(true, true, 8, GridScript.OCCLUSION_LOW)
	_expect(_points() == [target], "C3_SETUP_REBUILD")
	# Door filters consume the actual active-route contract.
	var saved_door_route = main.level.door_blocks_route
	var saved_alternate = main.level.alternate_route_cells.duplicate()
	main.level.door_blocks_route = "c3"
	main.level.alternate_route_cells.clear()
	main.door_locked = true
	main._refresh_killzone_preview()
	_expect(_points().is_empty(), "C3_DOOR_FILTER_REFRESH")
	main.door_locked = false
	main._refresh_killzone_preview()
	_expect(_points() == [target], "C3_DOOR_OPEN_REFRESH")
	main.level.door_blocks_route = saved_door_route
	main.level.alternate_route_cells = saved_alternate
	op.visible = false
	main._refresh_selected_coverage()
	_expect(_points().is_empty(), "C3_HIDDEN_SELECTION")
	op.visible = true
	op.alive = false
	main._refresh_selected_coverage()
	_expect(_points().is_empty(), "C3_DEAD_SELECTION")
	op.alive = true
	main.selected = null
	main._refresh_selected_coverage()
	_expect(_points().is_empty(), "C3_NULL_SELECTION")
	main.selected = op
	if DisplayServer.get_name() != "headless":
		await _screenshots()
	else:
		print("C3_SCREENSHOTS_NOT_RUN headless_structure_only=1")
	if failures.is_empty():
		print("M1_HEIGHT_COVERAGE_GATE_OK low=1 mixed=1 full=1 identity=1 movement=1 snap=1 readonly=1 camera=1 phases=1")
		quit(0)
	else:
		print("M1_HEIGHT_COVERAGE_GATE_FAIL count=", failures.size())
		quit(1)


func _screenshots() -> void:
	fixture_offset = Vector2i(8, 2)
	for unit in main.operators:
		unit.visible = unit == op
	main.tutorial_overlay.hide()
	main._on_tutorial_dismissed()
	main._reset_cam_view()
	main.status_label.text = "C3测试夹具 · 青色菱形=选中队员可覆盖的路线样本 · 不是连续射界"
	for spec in [["low", true, 8, GridScript.OCCLUSION_LOW],
		["mixed-near-high", false, 7, GridScript.OCCLUSION_LOW],
		["mixed-near-low", false, 9, GridScript.OCCLUSION_LOW],
		["full", true, 8, GridScript.OCCLUSION_FULL]]:
		_fixture(true, spec[1], spec[2], spec[3])
		# Multiple independent samples; no joins or filled region.
		main.route_world["c3"] = PackedVector2Array([target, _cell(Vector2i(12, 6))])
		main._refresh_killzone_preview()
		await _capture(spec[0])
	_fixture(true, true, 8, GridScript.OCCLUSION_LOW)
	main.route_world["c3"] = PackedVector2Array([target, _cell(Vector2i(12, 6))])
	main._refresh_killzone_preview()
	_high(Vector2i(7, 6))
	var old_position := op.global_position
	op.set_move_path(PackedVector2Array([op.global_position, _cell(Vector2i(7, 6))]))
	main._tick_command_moves(0.1)
	_expect(op.global_position != old_position, "C3_SCREENSHOT_REAL_MOVE")
	_expect(not _points().is_empty() and _points() == _expected(), "C3_MOVE_PAN_VISIBLE_MEMBERSHIP")
	main._cam_pan = Vector2(48, -24)
	main._cam_zoom = 1.15
	main._apply_cam()
	_expect(_points() == _expected(), "C3_MOVE_PAN_STABLE_MEMBERSHIP")
	await _capture("move-pan")


func _capture(label: String) -> void:
	main.map_draw.invalidate_static_cache()
	main._refresh_selection_visual()
	main._update_role_cards()
	if main.c2:
		main.c2.refresh_hud_light()
	for _i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	_expect(not picture.is_empty() and picture.get_size() == Vector2i(root.size), "C3_RENDER_DIMENSIONS")
	var run_dir := OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir()
	var path := run_dir.path_join("c3-" + label + ".png")
	_expect(picture.save_png(path) == OK and FileAccess.get_file_as_bytes(path).size() > 100, "C3_SCREENSHOT_SAVED")
	print("C3_SCREENSHOT=", path, " size=", picture.get_size())
