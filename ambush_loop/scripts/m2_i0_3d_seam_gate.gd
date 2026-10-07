extends SceneTree

const GridScript := preload("res://scripts/grid.gd")
const Pathfinder := preload("res://scripts/raid/pathfinder.gd")
const Adapter := preload("res://scripts/m2_i0_yard_adapter.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const TILE := 32.0
const GROUND_CELL := Vector2i(15, 13)
const PLATFORM_CELL := Vector2i(15, 12)

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var grid = GridScript.new()
	grid.rebuild("yard")
	var logic_ground := _cell_center(GROUND_CELL)
	var logic_platform := _cell_center(PLATFORM_CELL)
	var authored := grid.get_elevation_tier(PLATFORM_CELL.x, PLATFORM_CELL.y)
	_expect(authored == GridScript.HEIGHT_PLATFORM, "M2_I0_LOCAL_PLATFORM_IS_AUTHORITATIVE")
	var before_cell := grid.world_to_cell(logic_platform)
	var ground_world := Adapter.world_anchor(grid, logic_ground)
	var platform_world := Adapter.world_anchor(grid, logic_platform)
	_expect(is_equal_approx(platform_world.y - ground_world.y, Adapter.HEIGHT_METRES), "M2_I0_HEIGHT_MAP_USES_LOCAL_TIER")
	_expect(Vector2i(grid.world_to_cell(logic_platform)) == before_cell, "M2_I0_VISUAL_MAPPING_DOES_NOT_MOVE_GRID")
	_expect(Space.world_to_logic(platform_world).is_equal_approx(logic_platform), "M2_I0_LOGIC_ANCHOR_ROUND_TRIP")

	var platform_hit := platform_world
	var ground_hit := ground_world
	var elevated := Adapter.candidate_for_surface(grid, platform_hit)
	var ground := Adapter.candidate_for_surface(grid, ground_hit)
	_expect(int(elevated.get("tier", -1)) == GridScript.HEIGHT_PLATFORM, "M2_I0_PLATFORM_SURFACE_RESOLVES_TO_PLATFORM_CELL")
	_expect(int(ground.get("tier", -1)) == GridScript.HEIGHT_GROUND, "M2_I0_GROUND_SURFACE_RESOLVES_TO_GROUND_CELL")
	_expect(not elevated.is_empty() and elevated.get("cell") == PLATFORM_CELL, "M2_I0_ELEVATED_CANDIDATE_RETURNS_AUTHORED_CELL")
	var fake_floor_under_platform := platform_hit
	fake_floor_under_platform.y = 0.0
	_expect(Adapter.candidate_for_surface(grid, fake_floor_under_platform).is_empty(), "M2_I0_GROUND_CANNOT_PICK_THROUGH_PLATFORM")

	var target_a := {"valid": true, "kind": "operator", "id": "op-a", "cell": PLATFORM_CELL, "pos": logic_platform, "tier": 1, "distance": 1.0}
	var target_b := {"valid": true, "kind": "operator", "id": "op-b", "cell": PLATFORM_CELL, "pos": logic_platform, "tier": 1, "distance": 1.0}
	var picked_forward := Adapter.choose_hit([target_b, target_a])
	var picked_reverse := Adapter.choose_hit([target_a, target_b])
	_expect(str(picked_forward.get("id", "")) == "op-a" and str(picked_reverse.get("id", "")) == "op-a", "M2_I0_OVERLAP_PICK_IS_ORDER_INDEPENDENT")
	var decorative := {"valid": true, "kind": "decoration", "id": "crate", "distance": 0.2}
	var ground_behind := {"valid": true, "kind": "ground", "id": "cell-15-13", "cell": GROUND_CELL, "pos": logic_ground, "distance": 0.5}
	_expect(Adapter.choose_hit([ground_behind, decorative]).is_empty(), "M2_I0_DECORATION_BLOCKS_PICK_THROUGH")
	_expect(Adapter.choose_hit([ground_behind]).get("cell") == GROUND_CELL, "M2_I0_GROUND_PICK_RETURNS_LOGICAL_CELL")

	var path_with_ramp: Array[Vector2i] = Pathfinder.find_path(grid, Vector2i(6, 16), PLATFORM_CELL)
	_expect(not path_with_ramp.is_empty(), "M2_I0_LOCAL_PATH_USES_AUTHORED_RAMP")
	grid.set_ramp_link(GROUND_CELL, PLATFORM_CELL, false)
	var path_without_ramp: Array[Vector2i] = Pathfinder.find_path(grid, Vector2i(6, 16), PLATFORM_CELL)
	_expect(path_without_ramp.is_empty(), "M2_I0_PICKER_CANNOT_REPLACE_LOCAL_PATHFINDER")
	grid.set_ramp_link(GROUND_CELL, PLATFORM_CELL)
	_expect(grid.has_ramp_link(GROUND_CELL, PLATFORM_CELL), "M2_I0_GATE_RESTORES_FIXTURE")
	await _test_alternate_yard_scene()

	if failures.is_empty():
		print("M2_I0_SEAM_OK height=1 surface_pick=1 deterministic=1 decoration_inert=1 local_path=1 scene=1")
		quit(0)
	else:
		push_error("M2_I0_SEAM_RED " + ";".join(failures))
		quit(1)


func _test_alternate_yard_scene() -> void:
	var packed := load("res://scenes/presentation/yard_i0_3d.tscn") as PackedScene
	_expect(packed != null, "M2_I0_ALTERNATE_SCENE_LOADS")
	if packed == null:
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var presenter := scene.get_node_or_null("I0YardPresentation")
	_expect(presenter != null and bool(presenter.get("active")), "M2_I0_YARD_PREVIEW_BINDS_ONLY_TO_YARD")
	if presenter == null or not bool(presenter.get("active")):
		scene.queue_free()
		await process_frame
		return
	var legacy_world := scene.get_node_or_null("World") as CanvasItem
	_expect(legacy_world != null and not legacy_world.visible, "M2_I0_ACTIVE_PREVIEW_HIDES_LEGACY_CANVAS")
	var tutorial := scene.get("tutorial_overlay") as CanvasLayer
	if tutorial != null:
		for _page in 4:
			if not tutorial.is_open():
				break
			tutorial.call("_on_next")
	var runtime_grid: RefCounted = scene.get("grid")
	var camera: Camera3D = presenter.get("camera")
	var original_camera_position := camera.position
	for key in presenter._actor_nodes:
		var miniature: MeshInstance3D = presenter._actor_nodes[key]
		_expect(miniature.mesh is BoxMesh and miniature.has_node("Helmet") and miniature.has_node("Weapon") and miniature.has_node("LeftBoot") and miniature.has_node("Backpack"), "M25_UNIT_ORIGINAL_SILHOUETTE_" + str(key))
	var original_actor_position: Vector2 = scene.get("selected").position
	scene.set("_cam_pan", Vector2(64.0, 32.0))
	scene.set("_cam_zoom", 1.4)
	scene.call("_apply_cam")
	_expect(not camera.position.is_equal_approx(original_camera_position), "M25_CAMERA_SHARED_PAN_UPDATES_3D")
	_expect(is_equal_approx(camera.size, presenter.CAMERA_SIZE / 1.4), "M25_CAMERA_SHARED_PINCH_UPDATES_3D")
	_expect(scene.get("selected").position == original_actor_position, "M25_CAMERA_DOES_NOT_MOVE_ACTOR")
	scene.call("_reset_cam_view")
	_expect(camera.position.is_equal_approx(presenter.CAMERA_RIG + presenter.CAMERA_FOCUS) and is_equal_approx(camera.size, presenter.CAMERA_SIZE), "M25_CAMERA_RECENTER_RESTORES_3D")
	var ground_picked := _find_camera_pick(presenter, camera, runtime_grid, GridScript.HEIGHT_GROUND)
	presenter.call("set_low_quality", true)
	_expect(not presenter._sun.shadow_enabled, "M25_LOW_QUALITY_DISABLES_DYNAMIC_SHADOWS")
	_expect(scene.get("selected").position == original_actor_position, "M25_QUALITY_DOES_NOT_MOVE_ACTOR")
	presenter.call("set_low_quality", false)
	_expect(presenter._sun.shadow_enabled, "M25_STANDARD_QUALITY_RESTORES_SHADOWS")
	var sync_before := int(presenter.sync_count)
	presenter.call("_set_active", false)
	presenter.call("_process", 0.016)
	_expect(int(presenter.sync_count) == sync_before, "M25_INACTIVE_3D_DOES_NOT_SYNC")
	presenter.call("_set_active", true)
	var saved_snapshots: Array = scene.battle_log.snapshots.duplicate(true)
	scene.battle_log.snapshots = [
		{"tick": 5, "data": {"ops": [{"id": 901, "pos": Vector2(32, 32), "tier": 0}]}},
		{"tick": 5, "data": {"ops": [{"id": 901, "pos": Vector2(64, 64), "tier": 1}]}},
		{"tick": 10, "data": {"ops": [{"id": 901, "pos": Vector2(96, 96), "tier": 0}]}},
	]
	var event := {"tick": 7, "actor_id": 901, "position": Vector2(128, 128)}
	_expect(presenter.call("_recorded_event_anchor", event, false).is_equal_approx(Adapter.recorded_anchor(Vector2(64, 64), 1, 0.9)), "M25_REPLAY_LOOKUP_LAST_DUPLICATE_BEFORE_EVENT")
	event.tick = 1
	_expect(presenter.call("_recorded_event_anchor", event, false).is_equal_approx(Adapter.recorded_anchor(Vector2(128, 128), 0, 0.9)), "M25_REPLAY_LOOKUP_BEFORE_FIRST_FALLBACK")
	scene.battle_log.snapshots = saved_snapshots
	print("M25_PRESENTER_PROFILE sync_last_usec=%d sync_peak_usec=%d" % [presenter.sync_last_usec, presenter.sync_peak_usec])
	var steady_samples: Array[int] = []
	var stash_instances: Dictionary = {}
	for key in presenter._stash_nodes:
		stash_instances[key] = presenter._stash_nodes[key].get_instance_id()
	var world_nodes_before: int = presenter._world.get_child_count()
	for sample in 60:
		presenter.call("sync_presentation")
		steady_samples.append(int(presenter.sync_last_usec))
	steady_samples.sort()
	_expect(not stash_instances.is_empty(), "M25_SUPPLY_CACHE_HAS_LIVE_FIXTURE")
	for key in stash_instances:
		_expect(presenter._stash_nodes.has(key) and presenter._stash_nodes[key].get_instance_id() == stash_instances[key], "M25_SUPPLY_MODEL_REUSES_INSTANCE_" + str(key))
	_expect(presenter._world.get_child_count() == world_nodes_before, "M25_STEADY_SYNC_NODE_COUNT_PLATEAUS")
	print("M25_PRESENTER_STEADY_CPU samples=60 p50_usec=%d p95_usec=%d max_usec=%d device=desktop_not_phone" % [steady_samples[29], steady_samples[56], steady_samples[59]])
	var platform_picked := _find_camera_pick(presenter, camera, runtime_grid, GridScript.HEIGHT_PLATFORM)
	_expect(ground_picked, "M2_I0_CAMERA_RAY_MAPS_GROUND_TO_LOCAL_CELL")
	_expect(platform_picked, "M2_I0_CAMERA_RAY_MAPS_PLATFORM_TO_LOCAL_CELL")
	await _test_real_b1_stash_pick(scene, presenter, camera, runtime_grid)
	_test_operator_touch_pick(scene, presenter, camera)
	var fixture_target := _cell_center(PLATFORM_CELL)
	var selected := scene.get("selected") as Node2D
	_expect(selected != null, "M2_I0_LOCAL_COMMAND_OWNER_EXISTS")
	if selected == null:
		scene.queue_free()
		await process_frame
		return
	scene.set("_touch_intent", {
		"kind": "move", "world": fixture_target,
		"cells": [PLATFORM_CELL], "sprint": false,
		"actor_instance_id": selected.get_instance_id(), "tool": int(scene.get("tool")),
	})
	presenter.call("_sync_intent_preview")
	_expect(presenter.get("_intent_preview") != null, "M2_I0_PENDING_LOCAL_INTENT_HAS_3D_PREVIEW")
	await process_frame
	_expect(bool(scene.call("touch_intent_pending")), "M2_I0_LOCAL_OWNER_PRESERVES_PENDING_INTENT")
	_expect(presenter.get("_intent_preview") != null, "M2_I0_PREVIEW_SURVIVES_INPUT_VALIDATION")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		var screenshot_path := "user://m2_i0_yard_preview.png"
		var screenshot_error := image.save_png(screenshot_path)
		_expect(screenshot_error == OK, "M2_I0_RENDERED_PREVIEW_SCREENSHOT_SAVED")
		if screenshot_error == OK:
			print("M2_I0_PREVIEW_IMAGE=" + ProjectSettings.globalize_path(screenshot_path))
	scene.set("_touch_intent", {})
	presenter.call("_sync_intent_preview")
	_expect(presenter.get("_intent_preview") == null, "M2_I0_CANCELED_LOCAL_INTENT_CLEARS_3D_PREVIEW")
	scene.queue_free()
	await process_frame


func _test_real_b1_stash_pick(scene: Node, presenter: Node, camera: Camera3D, grid: RefCounted) -> void:
	var stashes: Array = scene.get("raid_stashes")
	_expect(stashes.size() == 4, "M2_I0_REAL_B1_STASH_FIXTURE_PRESENT")
	if stashes.size() != 4 or camera == null or grid == null:
		return
	var stash: Node2D = stashes[3] as Node2D
	_expect(stash != null and str(stash.get("kind")) == "grenade", "M2_I0_TARGET_IS_REAL_OPTIONAL_GRENADE_CRATE")
	if stash == null or str(stash.get("kind")) != "grenade":
		return
	var operator := scene.get("selected") as Node2D
	_expect(operator != null, "M2_I0_REAL_STASH_HAS_LOCAL_OPERATOR")
	if operator == null:
		return

	var target_id := str(stash.get_instance_id())
	var target_screen := Vector2.ZERO
	var target: Dictionary = {}
	var anchor: Vector3 = Adapter.world_anchor(grid, stash.global_position, 0.02)
	for height_offset in [0.12, 0.30, 0.50, 0.68]:
		var screen := camera.unproject_position(anchor + Vector3(0.0, height_offset, 0.0))
		var candidate: Dictionary = presenter.call("pick_at", screen)
		if str(candidate.get("kind", "")) == "stash" and str(candidate.get("id", "")) == target_id:
			target = candidate
			target_screen = screen
			break
	_expect(not target.is_empty(), "M2_I0_3D_PICK_RESOLVES_REAL_STASH_STABLE_ID")
	if target.is_empty():
		return
	_expect(target.get("cell") == stash.get("cell"), "M2_I0_3D_STASH_PICK_RETURNS_AUTHORED_CELL")
	var before_pick := _resource_snapshot(operator)
	_expect(not bool(stash.get("collected")) and _resource_snapshot(operator) == before_pick, "M2_I0_PICKING_STASH_HAS_NO_RESOURCE_SIDE_EFFECT")

	var logical_target: Vector2 = target.get("pos", Vector2.INF)
	var began: bool = scene.call("_begin_touch_intent", logical_target)
	var intent: Dictionary = scene.get("_touch_intent")
	_expect(began and str(intent.get("kind", "")) == "move", "M2_I0_STASH_CANDIDATE_STAGES_EXISTING_LOCAL_MOVE_INTENT")
	if not began or str(intent.get("kind", "")) != "move":
		scene.call("cancel_touch_intent")
		return
	var cells: Array = intent.get("cells", [])
	_expect(not cells.is_empty() and cells.back() == stash.get("cell"), "M2_I0_LOCAL_INTENT_ROUTE_ENDS_AT_REAL_STASH_CELL")
	_expect(not bool(stash.get("collected")) and _resource_snapshot(operator) == before_pick, "M2_I0_STAGED_ROUTE_DOES_NOT_COLLECT_OR_MUTATE")
	var confirmed: bool = scene.call("confirm_touch_intent")
	_expect(confirmed and not bool(scene.call("touch_intent_pending")), "M2_I0_CONFIRM_USES_EXISTING_LOCAL_INTENT_OWNER")
	_expect(operator.is_moving(), "M2_I0_CONFIRM_STARTS_EXISTING_LOCAL_MOVE_PATH")
	if operator.is_moving():
		var guard := 0
		while operator.is_moving() and guard < 600:
			guard += 1
			scene.call("_tick_command_moves", 0.20)
		_expect(not operator.is_moving(), "M2_I0_LOCAL_MOVE_REACHES_STASH_WITHIN_GUARD")
	_expect(operator.grid_cell() == stash.get("cell"), "M2_I0_LOCAL_MOVE_REACHES_AUTHORED_STASH_CELL")
	_expect(not bool(stash.get("collected")) and _resource_snapshot(operator) == before_pick, "M2_I0_ARRIVAL_ALONE_DOES_NOT_COLLECT")

	scene.call("_try_pickup_near_selected")
	_expect(operator.is_searching() and operator.get("search_stash") == stash, "M2_I0_EXISTING_STASH_SEARCH_CHANNEL_STARTED")
	scene.call("raid_advance_search", 0.20)
	_expect(not bool(stash.get("collected")) and float(stash.get("search_progress")) < 1.0, "M2_I0_INCOMPLETE_SEARCH_DOES_NOT_COLLECT")
	_expect(_resource_snapshot(operator) == before_pick, "M2_I0_INCOMPLETE_SEARCH_DOES_NOT_MUTATE_RESOURCES")
	scene.call("raid_advance_search", 1.0)
	var after_search := _resource_snapshot(operator)
	var amount := int(stash.get("amount"))
	var remaining_stashes: Array = scene.get("raid_stashes")
	_expect(bool(stash.get("collected")) and not remaining_stashes.has(stash), "M2_I0_REAL_STASH_COLLECTS_AFTER_SEARCH_COMPLETES")
	_expect(int(after_search.get("grenades", -1)) == int(before_pick.get("grenades", 0)) + amount, "M2_I0_REAL_GRENADE_RESOURCE_GAINED_EXACT_AMOUNT_ONCE")
	_expect(int(after_search.get("grenade_pack", -1)) == int(before_pick.get("grenade_pack", 0)) + amount, "M2_I0_REAL_GRENADE_PACK_GAINED_EXACT_AMOUNT_ONCE")
	_expect(
		int(after_search.get("ammo", -1)) == int(before_pick.get("ammo", 0))
		and after_search.get("ammo_pool", {}) == before_pick.get("ammo_pool", {})
		and int(after_search.get("mines", -1)) == int(before_pick.get("mines", 0))
		and int(after_search.get("decoys", -1)) == int(before_pick.get("decoys", 0)),
		"M2_I0_STASH_GAIN_CHANGES_NO_UNRELATED_RESOURCES"
	)
	var repick: Dictionary = presenter.call("pick_at", target_screen)
	_expect(str(repick.get("id", "")) != target_id or str(repick.get("kind", "")) != "stash", "M2_I0_COLLECTED_STASH_NO_LONGER_PICKABLE")
	scene.call("_try_pickup_near_selected")
	scene.call("raid_advance_search", 1.0)
	_expect(_resource_snapshot(operator) == after_search, "M2_I0_REPICK_CANNOT_DUPLICATE_RESOURCE_GAIN")


func _resource_snapshot(operator: Node2D) -> Dictionary:
	var pack = operator.get("pack")
	return {
		"weapon": str(operator.get("weapon_id")),
		"ammo": int(operator.get("ammo")),
		"ammo_pool": (operator.get("ammo_pool") as Dictionary).duplicate(true),
		"grenades": int(operator.get("grenades")),
		"grenade_pack": int(pack.count_of("grenade")) if pack != null else 0,
		"mines": int(operator.get("mines")),
		"decoys": int(operator.get("decoys")),
		"pack_items": pack.items() if pack != null else [],
	}


func _test_operator_touch_pick(scene: Node, presenter: Node, camera: Camera3D) -> void:
	var selected_before := scene.get("selected") as Node2D
	var target_id := -1
	var target_screen := Vector2.ZERO
	for operator in scene.get("operators"):
		if operator == null or not is_instance_valid(operator) or not operator.visible or not operator.alive:
			continue
		var logic: Vector2 = operator.global_position
		var anchor := Adapter.world_anchor(scene.get("grid"), logic)
		for height_offset in [0.20, 0.45, 0.70, 1.0]:
			var screen := camera.unproject_position(anchor + Vector3(0.0, height_offset, 0.0))
			var candidate: Dictionary = presenter.call("pick_at", screen)
			if str(candidate.get("kind", "")) != "operator":
				continue
			if selected_before != null and int(candidate.get("id", -1)) == int(selected_before.op_id):
				continue
			target_id = int(candidate.get("id", -1))
			target_screen = screen
			break
		if target_id >= 0:
			break
	_expect(target_id >= 0, "M2_I0_TOUCH_CAN_HIT_UNSELECTED_OPERATOR")
	if target_id < 0:
		return
	var down := InputEventScreenTouch.new()
	down.index = 71
	down.pressed = true
	down.position = target_screen
	var consumed: bool = scene.call("_handle_touch_gestures", down)
	var selected_after := scene.get("selected") as Node2D
	_expect(consumed and selected_after != null and int(selected_after.op_id) == target_id, "M2_I0_TOUCH_PICK_SELECTS_BY_STABLE_LOCAL_ID")
	_expect(not bool(scene.call("touch_intent_pending")), "M2_I0_ACTOR_PICK_DOES_NOT_ISSUE_MOVE")
	var selection_up := InputEventScreenTouch.new()
	selection_up.index = 71
	selection_up.position = target_screen
	selection_up.pressed = false
	scene.call("_handle_touch_gestures", selection_up)
	_expect(scene.call("begin_yard_facing_handle", 71, target_screen), "M25_FACING_EXPLICIT_HANDLE_CAPTURES_POINTER")
	var facing_before := float(selected_after.facing_deg)
	var drag := InputEventScreenDrag.new()
	drag.index = 71
	var drag_found := false
	for y in GridScript.ROWS:
		for x in GridScript.COLS:
			var logic := _cell_center(Vector2i(x, y))
			var screen := camera.unproject_position(Adapter.world_anchor(scene.grid, logic))
			var candidate: Dictionary = presenter.call("pick_at", screen)
			if candidate.is_empty() or logic.distance_to(selected_after.global_position) < 96.0:
				continue
			var delta: Vector2 = candidate.get("pos", logic) - selected_after.global_position
			if absf(wrapf(rad_to_deg(delta.angle()) - facing_before, -180.0, 180.0)) < 20.0:
				continue
			drag.position = screen
			drag_found = true
			break
		if drag_found: break
	_expect(drag_found, "M25_FACING_VALID_DRAG_FIXTURE")
	if drag_found:
		scene.call("_handle_touch_gestures", drag)
		_expect(is_equal_approx(float(selected_after.facing_deg), facing_before), "M25_FACING_DRAG_PREVIEWS_WITHOUT_COMMIT")
		_expect(not scene._yard_facing_preview.is_empty(), "M25_FACING_PREVIEW_EXISTS")
		var preview_data: Dictionary = scene.call("yard_tactical_display_data")
		_expect(not preview_data.get("preview_sector", {}).is_empty() and not preview_data.get("preview_route_samples", []).is_empty(), "M25_FACING_PROPOSED_SECTOR_AND_LOS_SAMPLES")
		for sample in preview_data.get("preview_route_samples", []):
			_expect(bool(sample.geometry_clear) == selected_after.fire_geometry_from(selected_after.global_position, float(scene._yard_facing_preview.angle), sample.position, scene.grid), "M25_FACING_PROPOSED_QUERY_MATCHES_AUTHORITY")
	var up := InputEventScreenTouch.new()
	up.index = 71
	up.pressed = false
	up.position = target_screen
	scene.call("_handle_touch_gestures", up)
	if drag_found:
		_expect(not is_equal_approx(float(selected_after.facing_deg), facing_before), "M25_FACING_RELEASE_COMMITS")
		_expect(scene._yard_facing_preview.is_empty(), "M25_FACING_RELEASE_CLEARS_PREVIEW")
		selected_after.set_facing(facing_before)
		scene.call("begin_yard_facing_handle", 71, target_screen)
		scene.call("_handle_touch_gestures", drag)
		var second := InputEventScreenTouch.new()
		second.index = 72
		second.pressed = true
		second.position = drag.position + Vector2(80.0, 0.0)
		scene.call("_handle_touch_gestures", second)
		_expect(scene._yard_facing_preview.is_empty(), "M25_SECOND_FINGER_CANCELS_FACING")
		scene.call("_handle_touch_gestures", up)
		second.pressed = false
		scene.call("_handle_touch_gestures", second)
		_expect(is_equal_approx(float(selected_after.facing_deg), facing_before), "M25_CANCELED_FACING_NEVER_COMMITS")
	var emulated_mouse_up := InputEventMouseButton.new()
	emulated_mouse_up.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse_up.pressed = false
	scene.call("_unhandled_input", emulated_mouse_up)


func _find_camera_pick(presenter: Node, camera: Camera3D, grid: RefCounted, wanted_tier: int) -> bool:
	if camera == null or grid == null:
		return false
	for y in GridScript.ROWS:
		for x in GridScript.COLS:
			if grid.is_blocked(x, y) or grid.get_elevation_tier(x, y) != wanted_tier:
				continue
			var cell := Vector2i(x, y)
			var logic := _cell_center(cell)
			var world := Adapter.world_anchor(grid, logic)
			var screen := camera.unproject_position(world)
			var candidate: Dictionary = presenter.call("pick_at", screen)
			if candidate.get("cell") == cell:
				return true
	return false


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2.ONE * (TILE * 0.5)


func _expect(ok: bool, marker: String) -> void:
	if ok:
		print(marker)
	else:
		failures.append(marker)
		push_error(marker)
