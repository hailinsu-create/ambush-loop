extends "res://scripts/m25_p1a_tactical_data_gate.gd"

const YardAdapter := preload("res://scripts/m2_i0_yard_adapter.gd")

func _run() -> void:
	create_timer(120.0).timeout.connect(func(): quit(3))
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m25-p1b-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("M25_P1B_DECISION_DISPLAY")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	var op = main.selected
	_expect(op != null and not bool(op.melee), "M25_P1B_FIREARM_OPERATOR_FIXTURE")
	if op == null:
		_finish_failed()
		return
	var target_ids := [9301, 9302]
	for index in target_ids.size():
		var target_id: int = int(target_ids[index])
		var target = main.call("_make_enemy", target_id)
		main.entities.add_child(target)
		var target_position: Vector2 = op.global_position + Vector2(140.0 + index * 24.0, index * 36.0)
		target.call("setup", target_id, PackedVector2Array([target_position, target_position + Vector2(16.0, 0.0)]), main.grid, 0, "main")
		target.set("active", true)
		target.global_position = target_position
		main.enemies.append(target)

	main.call("open_yard_3d")
	var presenter = main.get_node_or_null("I0YardPresentation")
	_expect(presenter != null and bool(presenter.get("active")), "M25_P1B_3D_PRESENTER_ACTIVE")
	if presenter == null:
		_finish_failed()
		return
	presenter.set_process(false)
	presenter.call("sync_presentation")
	var data: Dictionary = main.call("yard_tactical_display_data")
	var resources: Dictionary = data.get("resources", {})
	var route_samples: Array = data.get("route_samples", [])
	var route_markers: MultiMesh = presenter.get("_tactical_coverage").multimesh
	var expected_marker_count := mini(route_samples.size(), 192)
	_expect(route_markers.instance_count == expected_marker_count and route_markers.instance_count > 0, "M25_P1B_3D_ROUTE_MARKERS_MATCH_SHARED_SAMPLE_BUDGET")
	var rendered_readback_supported := not DisplayServer.get_name().to_lower().contains("headless")
	var route_marker_positions_match := route_markers.instance_count == expected_marker_count
	var route_marker_colors_match := route_markers.instance_count == expected_marker_count
	var first_marker_debug := ""
	for index in route_markers.instance_count:
		var sample: Dictionary = route_samples[index]
		var expected_anchor := YardAdapter.world_anchor(main.grid, sample.get("position", Vector2.INF), 0.075)
		var expected_color := Color("4fe3d0") if bool(sample.get("geometry_clear", false)) else Color("e0a86b", 0.58)
		if route_markers.get_instance_transform(index).origin.distance_to(expected_anchor) > 0.01:
			route_marker_positions_match = false
		if route_markers.get_instance_color(index) != expected_color:
			route_marker_colors_match = false
		if index == 0:
			first_marker_debug = "actual_pos=%s expected_pos=%s actual_color=%s expected_color=%s" % [str(route_markers.get_instance_transform(index).origin), str(expected_anchor), str(route_markers.get_instance_color(index)), str(expected_color)]
	if rendered_readback_supported and (not route_marker_positions_match or not route_marker_colors_match):
		print("M25_P1B_ROUTE_MARKER_DEBUG " + first_marker_debug)
	if rendered_readback_supported:
		_expect(route_marker_positions_match, "M25_P1B_3D_ROUTE_MARKERS_USE_SHARED_QUERY_POSITIONS")
		_expect(route_marker_colors_match, "M25_P1B_3D_ROUTE_MARKER_COLORS_USE_AUTHORITY_GEOMETRY")
	else:
		print("M25_P1B_ROUTE_MARKER_BUFFER_READBACK_SKIPPED display=%s; rendered gate checks exact transforms/colors" % DisplayServer.get_name())
	var sector_mesh: ArrayMesh = presenter.get("_tactical_sector").mesh
	var sector_arrays: Array = sector_mesh.surface_get_arrays(0) if sector_mesh != null and sector_mesh.get_surface_count() > 0 else []
	var sector_vertices: PackedVector3Array = sector_arrays[Mesh.ARRAY_VERTEX] if not sector_arrays.is_empty() else PackedVector3Array()
	var sector: Dictionary = data.get("nominal_sector", {})
	var sector_origin: Vector2 = sector.get("origin", Vector2.INF)
	var sector_center := YardAdapter.world_anchor(main.grid, sector_origin, 0.055)
	var sector_facing := deg_to_rad(float(sector.get("facing_deg", 0.0)) - float(sector.get("half_angle_deg", 0.0)))
	var first_sector_edge := YardAdapter.world_anchor(main.grid, sector_origin + Vector2(cos(sector_facing), sin(sector_facing)) * float(sector.get("range_px", 0.0)), 0.055)
	var sector_geometry_matches := sector_vertices.size() >= 3
	if sector_geometry_matches:
		sector_geometry_matches = sector_vertices[0].distance_to(sector_center) < 0.02 and sector_vertices[1].distance_to(first_sector_edge) < 0.02
	_expect(sector_geometry_matches, "M25_P1B_3D_NOMINAL_SECTOR_MATCHES_SHARED_WEAPON_ENVELOPE")
	_expect(int(resources.get("ammo", -1)) == int(op.ammo), "M25_P1B_SELECTED_AMMO_IS_AUTHORITATIVE")
	_expect(int(resources.get("grenades", -1)) == int(op.grenades) and int(resources.get("mines", -1)) == int(op.mines) and int(resources.get("decoys", -1)) == int(op.decoys), "M25_P1B_THROWABLES_ARE_AUTHORITATIVE")
	_expect(bool(resources.get("ammo_pack_ready", false)) == (bool(op.has_ammo_pack) and not bool(op.ammo_pack_used)), "M25_P1B_AMMO_PACK_STATUS_IS_AUTHORITATIVE")
	_expect(int(resources.get("available_stashes", -1)) == _available_stash_count(main), "M25_P1B_SUPPLY_COUNT_IS_AUTHORITATIVE")
	var summary := str(presenter.call("_tactical_summary", data))
	_expect(summary.contains("弹药") and summary.contains("手雷") and summary.contains("绊雷") and summary.contains("诱饵"), "M25_P1B_3D_CARD_SHOWS_SELECTED_RESOURCES")
	_expect(summary.contains("补给点") and summary.contains("工具：") and summary.contains("自动许可"), "M25_P1B_3D_CARD_SHOWS_SUPPLY_TOOL_PERMISSION")
	var target_states: Array = data.get("target_states", [])
	_expect(target_states.size() >= 2, "M25_P1B_MULTIPLE_TARGET_FIXTURE")
	for target in target_states:
		var target_label := "目标 %d：" % int(target.get("id", -1))
		_expect(summary.contains(target_label), "M25_P1B_3D_CARD_SHOWS_EACH_TARGET_%d" % int(target.get("id", -1)))
	var landmarks: Dictionary = presenter.get("landmark_nodes")
	_expect(landmarks.has("main") and landmarks.has("flank") and landmarks.has("exit") and landmarks.has("permission"), "M25_P1B_3D_DECISION_LANDMARKS_PRESENT")
	var main_route: PackedVector2Array = main.route_world.get("main", PackedVector2Array())
	var flank_route: PackedVector2Array = main.route_world.get("flank", PackedVector2Array())
	if landmarks.has("main") and not main_route.is_empty():
		var expected_main := YardAdapter.world_anchor(main.grid, main_route[0], 1.6)
		_expect(landmarks.get("main").position.distance_to(expected_main) < 0.01, "M25_P1B_MAIN_ENTRY_LANDMARK_MATCHES_AUTHORED_ROUTE")
	if landmarks.has("flank") and not flank_route.is_empty():
		var expected_flank := YardAdapter.world_anchor(main.grid, flank_route[0], 1.6)
		_expect(landmarks.get("flank").position.distance_to(expected_flank) < 0.01, "M25_P1B_FLANK_ENTRY_LANDMARK_MATCHES_AUTHORED_ROUTE")
	var exit_world: Vector2 = main.grid.cell_to_world_center(main.level.escape_cell)
	var expected_exit := YardAdapter.world_anchor(main.grid, exit_world, 1.6)
	_expect(landmarks.get("exit").position.distance_to(expected_exit) < 0.01, "M25_P1B_EXIT_LANDMARK_MATCHES_AUTHORITY")
	_expect(str(landmarks.get("permission").text).contains("自动许可"), "M25_P1B_PERMISSION_LANDMARK_MATCHES_MODE")
	var reason_target: Node = null
	for candidate in main.enemies:
		if is_instance_valid(candidate) and int(candidate.label_id) == 9301:
			reason_target = candidate
			break
	_expect(reason_target != null, "M25_P1B_BLOCK_REASON_TARGET_FIXTURE")
	if reason_target != null:
		var original_target_position: Vector2 = reason_target.global_position
		var original_facing := float(op.facing_deg)
		var original_ammo_for_reasons := int(op.ammo)
		var original_permission_for_reasons := bool(op.fire_permitted)
		var original_shot_cd := float(op.shot_cd)
		op.fire_permitted = false
		_expect_target_reason(main, presenter, reason_target, "hold", "未获开火许可", "M25_P1B_TARGET_HOLD_REASON")
		op.fire_permitted = true
		op.ammo = 0
		_expect_target_reason(main, presenter, reason_target, "ammo", "弹药不足", "M25_P1B_TARGET_AMMO_REASON")
		op.ammo = original_ammo_for_reasons
		reason_target.global_position = op.global_position + Vector2.RIGHT * (float(op.range_px) + 32.0)
		_expect_target_reason(main, presenter, reason_target, "range", "超出射程", "M25_P1B_TARGET_RANGE_REASON")
		var out_of_cone_angle := deg_to_rad(original_facing + float(op.half_angle_deg) + 20.0)
		reason_target.global_position = op.global_position + Vector2.RIGHT.rotated(out_of_cone_angle) * minf(160.0, float(op.range_px) * 0.5)
		_expect_target_reason(main, presenter, reason_target, "cone", "不在朝向范围", "M25_P1B_TARGET_CONE_REASON")
		reason_target.global_position = original_target_position
		op.facing_deg = rad_to_deg((original_target_position - op.global_position).angle())
		var los_fixture := _force_line_of_sight_block(main, op, original_target_position)
		_expect_target_reason(main, presenter, reason_target, "los", "被地形遮挡", "M25_P1B_TARGET_LOS_REASON")
		_restore_line_of_sight_block(main, los_fixture)
		op.facing_deg = original_facing
		op.ammo = original_ammo_for_reasons
		op.fire_permitted = original_permission_for_reasons
		op.shot_cd = original_shot_cd
		reason_target.global_position = original_target_position

	var original_grenades := int(op.grenades)
	var signature_before := str(main.call("yard_tactical_display_signature"))
	op.grenades = original_grenades + 1
	var signature_after_resource_change := str(main.call("yard_tactical_display_signature"))
	var changed_resource_data: Dictionary = main.call("yard_tactical_display_data")
	_expect(signature_before != signature_after_resource_change and int(changed_resource_data.get("resources", {}).get("grenades", -1)) == original_grenades + 1, "M25_P1B_RESOURCE_CHANGE_INVALIDATES_SHARED_QUERY")
	op.grenades = original_grenades
	_expect(signature_before == str(main.call("yard_tactical_display_signature")), "M25_P1B_RESOURCE_RESTORE_RESTORES_SIGNATURE")

	var stash = null
	for candidate in main.raid_stashes:
		if candidate != null and is_instance_valid(candidate) and not bool(candidate.collected):
			stash = candidate
			break
	_expect(stash != null, "M25_P1B_UNCOLLECTED_STASH_FIXTURE")
	if stash != null:
		var stash_signature_before := str(main.call("yard_tactical_display_signature"))
		stash.collected = true
		var collected_data: Dictionary = main.call("yard_tactical_display_data")
		_expect(str(main.call("yard_tactical_display_signature")) != stash_signature_before and int(collected_data.get("resources", {}).get("available_stashes", -1)) == int(resources.get("available_stashes", 0)) - 1, "M25_P1B_STASH_CHANGE_INVALIDATES_SUPPLY_SUMMARY")
		stash.collected = false
		_expect(stash_signature_before == str(main.call("yard_tactical_display_signature")), "M25_P1B_STASH_RESTORE_RESTORES_SIGNATURE")

	var permission_before := bool(main.yard_manual_permission)
	var permission_signature := str(main.call("yard_tactical_display_signature"))
	main.yard_manual_permission = not permission_before
	var permission_data: Dictionary = main.call("yard_tactical_display_data")
	_expect(str(main.call("yard_tactical_display_signature")) != permission_signature, "M25_P1B_PERMISSION_MODE_INVALIDATES_SHARED_QUERY")
	presenter.call("sync_presentation")
	var permission_summary := str(presenter.call("_tactical_summary", permission_data))
	_expect(permission_summary.contains("手动许可"), "M25_P1B_MANUAL_PERMISSION_SHOWN_IN_CARD")
	_expect(str(presenter.get("landmark_nodes").get("permission").text).contains("手动许可"), "M25_P1B_MANUAL_PERMISSION_SHOWN_AT_LANDMARK")
	main.yard_manual_permission = permission_before
	presenter.call("sync_presentation")
	var final_data: Dictionary = main.call("yard_tactical_display_data")
	_expect(str(final_data.get("state_signature", "")) == str(main.call("yard_tactical_display_signature")), "M25_P1B_QUERY_SIGNATURE_MATCHES_RESTORED_STATE")
	var original_tool := int(main.tool)
	var tool_signature := str(main.call("yard_tactical_display_signature"))
	main.tool = (original_tool + 1) % 4
	var tool_data: Dictionary = main.call("yard_tactical_display_data")
	var tool_panel_summary := str(presenter.call("_tactical_summary", tool_data))
	_expect(str(main.call("yard_tactical_display_signature")) != tool_signature and not tool_panel_summary.contains("工具：部署"), "M25_P1B_TOOL_CHANGE_INVALIDATES_CARD")
	main.tool = original_tool
	final_data = main.call("yard_tactical_display_data")
	_expect(int(op.ammo) == int(resources.get("ammo", -1)) and int(op.grenades) == original_grenades, "M25_P1B_PRESENTATION_FIXTURE_RESTORES_GAMEPLAY_RESOURCES")
	_expect(bool(main.yard_manual_permission) == permission_before, "M25_P1B_PRESENTATION_FIXTURE_RESTORES_PERMISSION")
	_expect(int(presenter.get("_tactical_panel").mouse_filter) == Control.MOUSE_FILTER_IGNORE, "M25_P1B_CARD_PRESERVES_WORLD_INPUT_OWNERSHIP")
	await _capture_if_rendered(main, "p1b-decision-card")

	if failures.is_empty():
		print("M25_P1B_DECISION_DISPLAY_OK resources=1 supplies=1 targets=2 landmarks=1 readonly=1")
		quit(0)
	else:
		_finish_failed()


func _available_stash_count(main: Node) -> int:
	var count := 0
	for stash in main.raid_stashes:
		if stash != null and is_instance_valid(stash) and not bool(stash.collected):
			count += 1
	return count


func _expect_target_reason(main: Node, presenter: Node, target: Node, expected_reason: String, expected_copy: String, gate_name: String) -> void:
	var data: Dictionary = main.call("yard_tactical_display_data")
	var target_id := int(target.get("label_id"))
	var status: Dictionary = _target_status(data, target_id)
	_expect(str(status.get("block_reason", "")) == expected_reason, gate_name + "_AUTHORITY_REASON")
	var summary := str(presenter.call("_tactical_summary", data))
	_expect(summary.contains("目标 %d：%s" % [target_id, expected_copy]), gate_name + "_3D_COPY")
