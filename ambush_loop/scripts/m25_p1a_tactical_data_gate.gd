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
	_expect(data.get("actor", {}).get("id", -1) == op.op_id, "M25_P1A_QUERY_SELECTED_ACTOR_ID")
	_expect(data.get("nominal_sector", {}).get("authority", "") == "OperatorUnit.in_fire_geometry", "M25_P1A_NOMINAL_SECTOR_IDENTIFIES_RULE_SOURCE")
	var coverage: PackedVector2Array = data.get("coverage_points", PackedVector2Array())
	_expect(not coverage.is_empty(), "M25_P1A_ROUTE_COVERAGE_PRESENT")
	for point in coverage:
		_expect(op.in_fire_geometry(point, main.grid), "M25_P1A_EVERY_COVERED_POINT_USES_AUTHORITATIVE_GEOMETRY")
	_expect(main.selected_coverage_draw.get_child_count() == coverage.size(), "M25_P1A_2D_CONSUMES_SHARED_COVERAGE_DATA")
	_expect(not data.get("route_samples", []).is_empty(), "M25_P1A_ROUTE_SAMPLE_STATES_PRESENT")
	_expect(baseline == _authority_snapshot(main, op), "M25_P1A_READ_ONLY_QUERY_NO_AUTHORITY_MUTATION")

	var target = main.call("_make_enemy", 9001)
	main.entities.add_child(target)
	var synthetic_route := PackedVector2Array([coverage[0], coverage[0] + Vector2(16.0, 0.0)])
	target.call("setup", 9001, synthetic_route, main.grid, 0, "main")
	target.set("active", true)
	target.global_position = coverage[0]
	main.enemies.append(target)
	var target_data: Dictionary = main.call("yard_tactical_display_data")
	var found := false
	for status in target_data.get("target_states", []):
		if int(status.get("id", -1)) != int(target.label_id):
			continue
		found = true
		_expect(bool(status.get("geometry_clear", false)) == op.in_fire_geometry(target.global_position, main.grid), "M25_P1A_TARGET_GEOMETRY_MATCHES_AUTHORITY")
		_expect(str(status.get("block_reason", "")) == op.engage_block_reason(target.global_position, main.grid), "M25_P1A_TARGET_BLOCK_REASON_MATCHES_AUTHORITY")
	_expect(found, "M25_P1A_ACTIVE_TARGET_STATUS_PRESENT")

	main.set("_touch_intent", {
		"kind": "move", "world": op.global_position + Vector2(32.0, 0.0),
		"cells": [op.grid_cell()], "sprint": false,
		"actor_instance_id": op.get_instance_id(), "tool": int(main.tool),
	})
	var movement_data: Dictionary = main.call("yard_tactical_display_data")
	var movement_preview: Dictionary = movement_data.get("movement_preview", {})
	_expect(bool(movement_preview.get("valid", false)) and int(movement_preview.get("actor_id", -1)) == int(op.op_id), "M25_P1A_READS_EXISTING_MOVE_PREVIEW_OWNER")
	_expect(not movement_preview.get("cells", []).is_empty(), "M25_P1A_MOVE_PREVIEW_CARRIES_PATH")
	_expect(baseline == _authority_snapshot(main, op), "M25_P1A_MOVE_QUERY_DOES_NOT_EXECUTE_OR_SPEND")
	main.set("_touch_intent", {})

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
