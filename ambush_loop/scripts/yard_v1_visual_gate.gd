extends "res://scripts/m1_yard_visual_evidence_gate.gd"

const Silhouette := preload("res://scripts/presentation/yard_unit_silhouette.gd")

func _run() -> void:
	var main = await _open_yard("V1")
	if main == null: _finish_failed(); return
	main.open_yard_3d()
	await _frames(4)
	var presenter = main._active_i0_presenter()
	if presenter == null: _fail("V1_PRESENTER"); _finish_failed(); return
	presenter.set_process(false)
	var selected_position: Vector2 = main.selected.position
	var identities := _identities(presenter._world)
	var material_ids := []
	for key in presenter._style.materials: material_ids.append(presenter._style.materials[key].get_instance_id())
	var body: MeshInstance3D = presenter._actor_nodes.values()[0]
	presenter.sync_presentation()
	var applies := int(body.get_meta("pose_applies", 0))
	var samples: Array[int] = []
	for index in 600:
		presenter.sync_presentation()
		samples.append(int(presenter.sync_last_usec))
	_expect(_identities(presenter._world) == identities, "V1_STATIC_NODE_MESH_MATERIAL_IDS_PLATEAU_600")
	var after_ids := []
	for key in presenter._style.materials: after_ids.append(presenter._style.materials[key].get_instance_id())
	_expect(material_ids == after_ids and presenter._style.build_count == 1, "V1_STYLE_BUILT_ONCE_SHARED_MATERIALS")
	_expect(int(body.get_meta("pose_applies", 0)) == applies and int(body.get_meta("pose_skips", 0)) >= 600, "V1_IDLE_POSE_WRITES_PLATEAU")
	Silhouette.pose(body, "fixture", true, true, false, false, 10)
	var moving := int(body.get_meta("pose_applies", 0))
	Silhouette.pose(body, "fixture", true, true, false, false, 11)
	_expect(int(body.get_meta("pose_applies", 0)) == moving + 1, "V1_MOVING_POSE_ADVANCES")
	body.set_meta("hit_tick", 20)
	Silhouette.pose(body, "fixture", true, false, false, false, 20)
	_expect((body.material_override as StandardMaterial3D).albedo_color == Color("f2c6a8"), "V1_HIT_FLASH_APPLIES")
	Silhouette.pose(body, "fixture", true, false, false, false, 26)
	_expect((body.material_override as StandardMaterial3D).albedo_color == body.get_meta("uniform"), "V1_HIT_FLASH_RESTORES")
	presenter.sync_presentation()
	samples.sort()
	print("V1_CPU_STATIC samples=600 p50_usec=%d p95_usec=%d max_usec=%d phone_thermal=unverified" % [samples[299], samples[569], samples[599]])
	_expect(not presenter.tactical_expanded and presenter._compact_info.visible and not presenter._tactical_details.visible, "V1_TACTICAL_CARD_DEFAULT_COMPACT")
	_expect(presenter._expand_button.size.y >= 48, "V1_EXPAND_TARGET_48")
	await _capture(main, "v1-compact-1280")
	presenter.set_tactical_expanded(true)
	await _frames(3)
	_expect(presenter._tactical_details.visible and presenter._quality_button.size.y >= 48 and presenter._handed_button.size.y >= 48, "V1_EXPANDED_SETTINGS_48")
	await _capture(main, "v1-expanded-1280")
	presenter.set_tactical_expanded(false)
	DisplayServer.window_set_size(Vector2i(960, 540))
	await _frames(4)
	main._apply_cam()
	_expect(presenter._tactical_panel.get_global_rect().end.x <= root.get_visible_rect().size.x and presenter._tactical_panel.get_global_rect().end.y <= root.get_visible_rect().size.y, "V1_960_CARD_FITS")
	await _capture(main, "v1-compact-960")
	presenter.set_low_quality(true)
	await _frames(3)
	_expect(not presenter._sun.shadow_enabled and not presenter._world.get_node("SupplyWarmLamp").shadow_enabled, "V1_LOW_QUALITY_WARM_LIGHT_NO_SHADOW")
	await _capture(main, "v1-low-960")
	_expect(main.selected.position == selected_position, "V1_PRESENTATION_DOES_NOT_MOVE_ACTOR")
	if not failures.is_empty(): _finish_failed(); return
	print("YARD_V1_VISUAL_OK captures=4 identity_plateau=600 idle_cache=1 movement_hit_restore=1 sizes=2 player_authority=unchanged")
	quit(0)

func _identities(node: Node) -> Array:
	var result := [node.get_instance_id()]
	if node is MeshInstance3D:
		result.append(node.mesh.get_instance_id() if node.mesh != null else 0)
		result.append(node.material_override.get_instance_id() if node.material_override != null else 0)
	if node is MultiMeshInstance3D:
		result.append(node.multimesh.get_instance_id())
		result.append(node.material_override.get_instance_id() if node.material_override != null else 0)
	for child in node.get_children(): result.append_array(_identities(child))
	return result
