extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m25-p1a-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("M25_P1A_TACTICAL_DATA")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	var op = main.selected
	_expect(op != null and not bool(op.melee), "M25_P1A_SELECTED_FIREARM_FIXTURE")
	if op == null or bool(op.melee):
		_finish_failed()
		return

	main.call("_refresh_selected_coverage")
	var baseline := _authority_snapshot(main, op)
	var data: Dictionary = main.call("yard_tactical_display_data")
	var repeat: Dictionary = main.call("yard_tactical_display_data")
	_expect(bool(data.get("available", false)) and int(data.get("schema", 0)) == 1, "M25_P1A_QUERY_AVAILABLE_SCHEMA")
	_expect(str(data.get("state_signature", "")) == str(repeat.get("state_signature", "")), "M25_P1A_QUERY_SIGNATURE_STABLE")
	_expect(str(main.call("yard_tactical_display_signature")) == str(data.get("state_signature", "")), "M25_P1A_CHEAP_SIGNATURE_MATCHES_DATA")
	_expect(_signature_tracks(main, op, "facing_deg", float(op.facing_deg) + 7.0), "M25_P1A_SIGNATURE_TRACKS_FACING")
	_expect(_signature_tracks(main, op, "ammo", int(op.ammo) + 1), "M25_P1A_SIGNATURE_TRACKS_AMMO")
	_expect(_signature_tracks(main, op, "weapon_id", str(op.weapon_id) + "_test"), "M25_P1A_SIGNATURE_TRACKS_WEAPON")
	_expect(_signature_tracks(main, op, "melee", not bool(op.melee)), "M25_P1A_SIGNATURE_TRACKS_MELEE")
	_expect(_signature_tracks(main, op, "fire_permitted", not bool(op.fire_permitted)), "M25_P1A_SIGNATURE_TRACKS_PERMISSION")
	_expect(_signature_tracks(main, op, "range_px", float(op.range_px) + 1.0), "M25_P1A_SIGNATURE_TRACKS_RANGE")
	_expect(_signature_tracks(main, op, "half_angle_deg", float(op.half_angle_deg) + 1.0), "M25_P1A_SIGNATURE_TRACKS_HALF_ANGLE")
	_expect(_signature_tracks(main, op, "shot_cd", float(op.shot_cd) + 0.1), "M25_P1A_SIGNATURE_TRACKS_COOLDOWN")
	_expect(_signature_tracks(main, op, "global_position", op.global_position + Vector2(1.0, 0.0)), "M25_P1A_SIGNATURE_TRACKS_POSITION")
	_expect(data.get("actor", {}).get("id", -1) == op.op_id, "M25_P1A_QUERY_SELECTED_ACTOR_ID")
	_expect(data.get("nominal_sector", {}).get("authority", "") == "weapon_envelope" and not bool(data.get("nominal_sector", {}).get("line_of_sight_tested", true)), "M25_P1A_NOMINAL_SECTOR_IS_NOT_AUTHORITY_QUERY")
	var coverage: PackedVector2Array = data.get("coverage_points", PackedVector2Array())
	_expect(not coverage.is_empty(), "M25_P1A_ROUTE_COVERAGE_PRESENT")
	for point in coverage:
		_expect(op.in_fire_geometry(point, main.grid), "M25_P1A_EVERY_COVERED_POINT_USES_AUTHORITATIVE_GEOMETRY")
	_expect(main.selected_coverage_draw.get_child_count() == coverage.size(), "M25_P1A_2D_CONSUMES_SHARED_COVERAGE_DATA")
	_expect(not data.get("route_samples", []).is_empty(), "M25_P1A_ROUTE_SAMPLE_STATES_PRESENT")
	var route_records: Array = main.call("_active_route_records")
	var active_route_ids: Dictionary = {}
	var active_routes: Array = main.call("_active_routes")
	_expect(route_records.size() == active_routes.size() and not route_records.is_empty(), "M25_P1A_ROUTE_RECORDS_MATCH_ACTIVE_PATHS")
	for route_index in route_records.size():
		var record: Dictionary = route_records[route_index]
		var route_id := str(record.get("route_id", ""))
		_expect(not route_id.is_empty() and not active_route_ids.has(route_id), "M25_P1A_ROUTE_IDENTITY_STABLE_UNIQUE")
		active_route_ids[route_id] = true
		_expect(record.get("points", PackedVector2Array()) == active_routes[route_index], "M25_P1A_ROUTE_ID_PRESERVES_AUTHORED_PATH")
	for route in data.get("route_summary", []):
		_expect(active_route_ids.has(str(route.get("route_id", ""))), "M25_P1A_ROUTE_SUMMARY_USES_AUTHORED_ID")
	_expect(baseline == _authority_snapshot(main, op), "M25_P1A_READ_ONLY_QUERY_NO_AUTHORITY_MUTATION")

	var original_ammo := int(op.ammo)
	var original_permission := bool(op.fire_permitted)
	var original_shot_cd := float(op.shot_cd)
	op.ammo = maxi(original_ammo, 1)
	op.fire_permitted = true
	var target = main.call("_make_enemy", 9001)
	main.entities.add_child(target)
	var synthetic_route := PackedVector2Array([coverage[0], coverage[0] + Vector2(16.0, 0.0)])
	target.call("setup", 9001, synthetic_route, main.grid, 0, "main")
	target.set("active", true)
	target.global_position = coverage[0]
	main.enemies.append(target)
	var target_data: Dictionary = main.call("yard_tactical_display_data")
	var clear_status := _target_status(target_data, int(target.label_id))
	_expect(not clear_status.is_empty(), "M25_P1A_ACTIVE_TARGET_STATUS_PRESENT")
	_expect(bool(clear_status.get("geometry_clear", false)) and op.in_fire_geometry(target.global_position, main.grid), "M25_P1A_CLEAR_TARGET_MATCHES_AUTHORITY")
	_expect(str(clear_status.get("block_reason", "")) == op.engage_block_reason(target.global_position, main.grid), "M25_P1A_CLEAR_TARGET_REASON_MATCHES_AUTHORITY")
	_expect(bool(clear_status.get("engagement_conditions_clear", false)) == op.engage_block_reason(target.global_position, main.grid).is_empty(), "M25_P1A_TARGET_ENGAGEMENT_SEMANTIC_MATCHES_AUTHORITY")
	_expect(bool(clear_status.get("shot_cooldown_clear", false)) == (op.shot_cd <= 0.0), "M25_P1A_TARGET_STATUS_SEPARATES_COOLDOWN")
	var blocker_cell := _force_line_of_sight_block(main, op, target.global_position)
	var occluded_status_data: Dictionary = main.call("yard_tactical_display_data")
	var occluded_status := _target_status(occluded_status_data, int(target.label_id))
	_expect(_inside_nominal_sector(op, target.global_position), "M25_P1A_BLOCKED_TARGET_REMAINS_INSIDE_NOMINAL_ENVELOPE")
	_expect(not op.in_fire_geometry(target.global_position, main.grid), "M25_P1A_BLOCKED_TARGET_FAILS_PRECISE_GEOMETRY")
	_expect(str(occluded_status.get("block_reason", "")) == "los" and not bool(occluded_status.get("geometry_clear", true)), "M25_P1A_BLOCKED_TARGET_STATUS_EXPLAINS_LOS")
	_expect(not bool(occluded_status.get("engagement_conditions_clear", true)), "M25_P1A_BLOCKED_TARGET_NOT_MARKED_CONDITION_CLEAR")
	main.call("open_yard_3d")
	var occluded_presenter = main.get_node_or_null("I0YardPresentation")
	if occluded_presenter != null:
		occluded_presenter.set_process(false)
		occluded_presenter.call("sync_presentation")
		_expect(occluded_presenter.get("_tactical_sector").mesh != null, "M25_P1A_NOMINAL_WEDGE_REMAINS_PRESENT_WHEN_LOS_BLOCKED")
		var occluded_info := str(occluded_presenter.get("_tactical_info").text)
		_expect(occluded_info.contains("名义射界") and occluded_info.contains("被地形遮挡") and not occluded_info.contains("当前可射"), "M25_P1A_BLOCKED_TARGET_PRESENTATION_DOES_NOT_PROMISE_FIRE")
	else:
		_expect(false, "M25_P1A_BLOCKED_TARGET_3D_PRESENTER_AVAILABLE")
	_restore_line_of_sight_block(main, blocker_cell)
	op.ammo = original_ammo
	op.fire_permitted = original_permission
	op.shot_cd = original_shot_cd
	var cooldown_authority_before := _authority_snapshot(main, op)
	op.ammo = maxi(original_ammo, 1)
	op.fire_permitted = true
	op.shot_cd = 0.0
	var ready_panel_data: Dictionary = main.call("yard_tactical_display_data")
	var ready_panel_status := _target_status(ready_panel_data, int(target.label_id))
	_expect(bool(ready_panel_status.get("geometry_clear", false)) and str(ready_panel_status.get("block_reason", "")) == "", "M25_P1A_COOLDOWN_FIXTURE_HAS_CLEAR_TARGET")
	_expect(bool(ready_panel_status.get("shot_cooldown_clear", false)), "M25_P1A_READY_STATUS_HAS_NO_COOLDOWN")
	if occluded_presenter != null:
		occluded_presenter.call("sync_presentation")
		var ready_panel_text := str(occluded_presenter.get("_tactical_info").text)
		_expect(ready_panel_text.contains("交战条件满足") and not ready_panel_text.contains("冷却中"), "M25_P1A_READY_TARGET_STATUS_IS_EXPLICIT")
	op.shot_cd = 1.0
	var cooldown_panel_data: Dictionary = main.call("yard_tactical_display_data")
	var cooldown_panel_status := _target_status(cooldown_panel_data, int(target.label_id))
	_expect(bool(cooldown_panel_status.get("engagement_conditions_clear", false)) and not bool(cooldown_panel_status.get("shot_cooldown_clear", true)), "M25_P1A_COOLDOWN_FIXTURE_SEPARATES_GEOMETRY_FROM_COOLDOWN")
	if occluded_presenter != null:
		occluded_presenter.call("sync_presentation")
		var cooldown_panel_text := str(occluded_presenter.get("_tactical_info").text)
		_expect(cooldown_panel_text.contains("射击冷却中") and not cooldown_panel_text.contains("当前可射") and not cooldown_panel_text.contains("交战条件满足"), "M25_P1A_COOLDOWN_PRESENTATION_DOES_NOT_PROMISE_READY_SHOT")
	op.shot_cd = 0.0
	var restored_ready_data: Dictionary = main.call("yard_tactical_display_data")
	var restored_ready_status := _target_status(restored_ready_data, int(target.label_id))
	_expect(bool(restored_ready_status.get("shot_cooldown_clear", false)), "M25_P1A_COOLDOWN_CLEAR_RESTORES_STATUS")
	if occluded_presenter != null:
		occluded_presenter.call("sync_presentation")
		var restored_ready_text := str(occluded_presenter.get("_tactical_info").text)
		_expect(restored_ready_text.contains("交战条件满足") and not restored_ready_text.contains("冷却中"), "M25_P1A_COOLDOWN_CLEAR_RESTORES_PANEL_COPY")
	op.ammo = original_ammo
	op.fire_permitted = original_permission
	op.shot_cd = original_shot_cd
	_expect(cooldown_authority_before == _authority_snapshot(main, op), "M25_P1A_COOLDOWN_PRESENTATION_RESTORES_WITHOUT_MUTATION")
	baseline = _authority_snapshot(main, op)

	main.set("_touch_intent", {
		"kind": "move", "world": op.global_position + Vector2(32.0, 0.0),
		"cells": [op.grid_cell()], "sprint": false,
		"actor_instance_id": op.get_instance_id(), "tool": int(main.tool),
	})
	var signature_with_intent := str(main.call("yard_tactical_display_signature"))
	var movement_data: Dictionary = main.call("yard_tactical_display_data")
	var movement_preview: Dictionary = movement_data.get("movement_preview", {})
	_expect(bool(movement_preview.get("valid", false)) and int(movement_preview.get("actor_id", -1)) == int(op.op_id), "M25_P1A_READS_EXISTING_MOVE_PREVIEW_OWNER")
	_expect(not movement_preview.get("cells", []).is_empty(), "M25_P1A_MOVE_PREVIEW_CARRIES_PATH")
	_expect(baseline == _authority_snapshot(main, op), "M25_P1A_MOVE_QUERY_DOES_NOT_EXECUTE_OR_SPEND")
	main.set("_touch_intent", {})
	_expect(signature_with_intent != str(main.call("yard_tactical_display_signature")), "M25_P1A_INTENT_CREATION_AND_REMOVAL_INVALIDATE_CACHE")
	var slot_test := Node2D.new()
	main.add_child(slot_test)
	slot_test.global_position = op.global_position + Vector2(48.0, 0.0)
	main.set("_touch_intent", {
		"kind": "cover", "world": op.global_position, "slot": slot_test,
		"cells": [op.grid_cell()], "sprint": false,
		"actor_instance_id": op.get_instance_id(), "tool": int(main.tool),
	})
	var slot_signature := str(main.call("yard_tactical_display_signature"))
	var slot_preview: Dictionary = main.call("yard_tactical_display_data").get("movement_preview", {})
	_expect(slot_preview.get("position", Vector2.INF) == slot_test.global_position, "M25_P1A_COVER_PREVIEW_USES_SLOT_POSITION")
	slot_test.global_position += Vector2(1.0, 0.0)
	_expect(slot_signature != str(main.call("yard_tactical_display_signature")), "M25_P1A_SLOT_POSITION_INVALIDATES_CACHE")
	main.set("_touch_intent", {})
	slot_test.queue_free()

	var old_signature := str(main.call("yard_tactical_display_data").get("state_signature", ""))
	var prior_grid_revision := int(main.grid.tactical_revision)
	main.grid.set_occlusion_kind(1, 1, main.grid.OCCLUSION_NONE)
	var revised: Dictionary = main.call("yard_tactical_display_data")
	_expect(int(main.grid.tactical_revision) > prior_grid_revision and str(revised.get("state_signature", "")) != old_signature, "M25_P1A_OCCLUSION_REVISION_INVALIDATES_QUERY_CACHE")
	main.grid.set_occlusion_kind(1, 1, main.grid.OCCLUSION_INHERIT)

	main.call("open_yard_3d")
	var presenter = main.get_node_or_null("I0YardPresentation")
	_expect(presenter != null and bool(presenter.get("active")), "M25_P1A_3D_PRESENTER_ACTIVE")
	if presenter != null:
		presenter.set_process(false)
		presenter.call("sync_presentation")
		var shared: Dictionary = presenter.call("tactical_display_snapshot")
		_expect(str(shared.get("state_signature", "")) == str(main.call("yard_tactical_display_data").get("state_signature", "")), "M25_P1A_3D_READS_SHARED_QUERY")
		_expect(bool(presenter.get("_tactical_sector").visible) and presenter.get("_tactical_sector").mesh != null, "M25_P1A_3D_NOMINAL_SECTOR_RENDERED")
		_expect(bool(presenter.get("_tactical_coverage").visible) and int(presenter.get("_tactical_coverage").multimesh.instance_count) > 0, "M25_P1A_3D_ROUTE_QUERY_MARKERS_BOUNDED")
		_expect(bool(presenter.get("_tactical_info").visible) and str(presenter.get("_tactical_info").text).contains("射界"), "M25_P1A_3D_SELECTED_INFO_VISIBLE")
		_expect(presenter.get("_tactical_panel") != null and bool(presenter.get("_tactical_panel").visible), "M25_P1A_3D_FIXED_INFO_PANEL_VISIBLE")
		_expect(int(presenter.get("_tactical_panel").mouse_filter) == Control.MOUSE_FILTER_IGNORE, "M25_P1A_INFO_PANEL_PASSES_MAP_INPUT_THROUGH")
		var sector_mesh_instance_id := int(presenter.get("_tactical_sector").mesh.get_instance_id())
		presenter.call("_sync_tactical_display")
		_expect(int(presenter.get("_tactical_sector").mesh.get_instance_id()) == sector_mesh_instance_id, "M25_P1A_UNCHANGED_3D_TACTICS_REUSES_GEOMETRY")
		await _capture_if_rendered(main, "p1a-selected-fire-sector")

	if failures.is_empty():
		print("M25_P1A_TACTICAL_DATA_OK shared=1 read_only=1 cache_revision=1 sector=1 route_points=1 move_preview=1 target_status=1")
		quit(0)
	else:
		_finish_failed()


func _authority_snapshot(main: Node, op: Node) -> Dictionary:
	return {
		"phase": int(main.phase),
		"position": op.global_position,
		"facing": float(op.facing_deg),
		"weapon": str(op.weapon_id),
		"ammo": int(op.ammo),
		"hp": float(op.hp),
		"events": main.battle_log.events.size(),
		"grid_revision": int(main.grid.tactical_revision),
	}


func _signature_tracks(main: Node, op: Node, property_name: String, changed_value: Variant) -> bool:
	var before := str(main.call("yard_tactical_display_signature"))
	var original: Variant = op.get(property_name)
	op.set(property_name, changed_value)
	var changed := str(main.call("yard_tactical_display_signature"))
	op.set(property_name, original)
	var restored := str(main.call("yard_tactical_display_signature"))
	return before != changed and before == restored


func _target_status(data: Dictionary, target_id: int) -> Dictionary:
	for status in data.get("target_states", []):
		if int(status.get("id", -1)) == target_id:
			return status
	return {}


func _inside_nominal_sector(op: Node, target_position: Vector2) -> bool:
	var relative: Vector2 = target_position - op.global_position
	if relative.length() < 8.0 or relative.length() > float(op.range_px):
		return false
	var relative_angle := rad_to_deg(relative.angle())
	return absf(wrapf(relative_angle - float(op.facing_deg), -180.0, 180.0)) <= float(op.half_angle_deg)


func _force_line_of_sight_block(main: Node, op: Node, target_position: Vector2) -> Dictionary:
	var start_cell: Vector2i = main.grid.world_to_cell(op.global_position)
	var target_cell: Vector2i = main.grid.world_to_cell(target_position)
	var changed_cells: Array[Dictionary] = []
	for sample_index in range(1, 8):
		var point: Vector2 = op.global_position.lerp(target_position, float(sample_index) / 8.0)
		var cell: Vector2i = main.grid.world_to_cell(point)
		if cell == start_cell or cell == target_cell or not main.grid.in_bounds(cell.x, cell.y):
			continue
		var already_changed := false
		for saved in changed_cells:
			if saved.get("cell") == cell:
				already_changed = true
				break
		if already_changed:
			continue
		changed_cells.append({
			"cell": cell,
			"blocked": main.grid.is_blocked(cell.x, cell.y),
			"occlusion": main.grid.get_occlusion_kind(cell.x, cell.y),
		})
		main.grid.set_blocked(cell.x, cell.y, true)
		main.grid.set_occlusion_kind(cell.x, cell.y, main.grid.OCCLUSION_FULL)
		if not op.in_fire_geometry(target_position, main.grid):
			return {"cells": changed_cells}
	return {"cells": changed_cells}


func _restore_line_of_sight_block(main: Node, saved: Dictionary) -> void:
	for item in saved.get("cells", []):
		var cell: Vector2i = item.get("cell", Vector2i(-1, -1))
		if not main.grid.in_bounds(cell.x, cell.y):
			continue
		main.grid.set_blocked(cell.x, cell.y, bool(item.get("blocked", false)))
		main.grid.set_occlusion_kind(cell.x, cell.y, int(item.get("occlusion", main.grid.OCCLUSION_INHERIT)))
