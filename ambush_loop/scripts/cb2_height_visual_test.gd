extends "res://scripts/m1_height_fire_gate.gd"

const Space := preload("res://scripts/presentation/world_space.gd")

func _prepare_high_recording(main: Node) -> void:
	main.battle_log.begin_attempt("cb2-height-visual-" + OS.get_environment("AMBUSH_TEST_RUN_ID"))
	main.battle_log.enable_continuous_playback(2)
	main.battle_log.begin_wave(0)

func _scene_path() -> String:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	return "res://scenes/presentation/yard_3d.tscn"

func _after_high_shots(main: Node) -> void:
	var view = main.presentation_3d
	view.refresh()
	var op = main.operators[0]
	_expect(view.frame.height_schema == 2, "CB2_CURRENT_CONTINUOUS_TERRAIN_RECORDED")
	_expect(is_equal_approx(view.actors["ops:%d" % op.op_id].position.y,1.0), "CB2_ACTUAL_OPERATOR_PROXY_HIGH")
	_expect(is_equal_approx(view.actors["enemies:99"].position.y,1.0), "CB2_ACTUAL_ENEMY_PROXY_HIGH")
	var fx: Dictionary = view.shot_fx.diagnostics()
	_expect(fx.active.size() == 2, "CB2_ACTUAL_HIGH_SHOT_AND_RETURN_CUES")
	for shot in fx.active:
		_expect(shot.muzzle.y > 1.0 and shot.muzzle.y < 3.0, "CB2_ACTUAL_MUZZLE_USES_HIGH_BODY_SOCKET")
		_expect(is_equal_approx(shot.target.y,2.05), "CB2_ACTUAL_TARGET_HIGH_BODY_ANCHOR")
	var before: Dictionary = main._snapshot_data().duplicate(true)
	for repeat in 30:
		view.refresh()
	var stable: Dictionary = view.shot_fx.diagnostics()
	_expect(stable.sample_calls == fx.sample_calls and stable.mesh_nodes == fx.mesh_nodes, "CB2_REPEATED_HEIGHT_FRAME_BOUNDED_POOL")
	_expect(main._snapshot_data() == before, "CB2_PRESENTATION_DOES_NOT_WRITE_HEIGHT_BATTLE")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280,720)
		view.rig.focus = Space.logic_to_world(op.global_position)
		view.rig.view_size = 12.0
		view.rig.apply_pose()
		await process_frame
		await RenderingServer.frame_post_draw
		var directory := "res://build/ambush_test_runs/%s/captures" % OS.get_environment("AMBUSH_TEST_RUN_ID")
		DirAccess.make_dir_recursive_absolute(directory)
		var path := directory + "/high-shot-and-return.png"
		_expect(root.get_texture().get_image().save_png(path) == OK, "CB2_HIGH_SHOT_RENDER_SAVED")
		print("CB2_HEIGHT_VISUAL_CAPTURE ",ProjectSettings.globalize_path(path))
	print("CB2_HEIGHT_VISUAL_CHECKED failures=", failures.size(), " active_shots=", fx.active.size())
