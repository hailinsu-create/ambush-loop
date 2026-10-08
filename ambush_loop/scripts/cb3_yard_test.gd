extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const Paths := preload("res://scripts/raid/pathfinder.gd")
var checks := 0
var failures := 0

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CB3_YARD: " + label)

func _collect(main: Node, index: int, kind: String) -> void:
	for stash in main.raid_stashes:
		if stash.kind == kind:
			var op: OperatorUnit = main.operators[index]
			op.global_position = stash.global_position
			op.begin_search(stash)
			if op.tick_search(0.4):
				_check(main._complete_stash_search(op), "real crate search " + kind)
			return
	_check(false, "authored crate missing " + kind)

func _run() -> void:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	var rendered_3d := OS.get_environment("AMBUSH_YARD_RENDER3D") == "1"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn" if rendered_3d else "res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	if main.presentation_3d != null:
		main.presentation_3d.set_process(false)
	for scenario in [
		{"strategy":"high","offset":Vector2.ZERO,"angle":0.0},
		{"strategy":"high","offset":Vector2(4,4),"angle":5.0},
		{"strategy":"high","offset":Vector2(-4,-4),"angle":-5.0},
		{"strategy":"ground","offset":Vector2.ZERO,"angle":0.0},
		{"strategy":"ground","offset":Vector2(4,4),"angle":5.0},
		{"strategy":"ground","offset":Vector2(-4,-4),"angle":-5.0},
		{"strategy":"ground","offset":Vector2.ZERO,"angle":0.0,"no_mine":true},
		{"strategy":"high","offset":Vector2.ZERO,"angle":0.0,"negative":"ammo"},
		{"strategy":"high","offset":Vector2.ZERO,"angle":0.0,"negative":"flank"},
		{"strategy":"ground","offset":Vector2.ZERO,"angle":0.0,"negative":"tool"},
	]:
		var strategy: String = scenario.strategy
		var negative: String = scenario.get("negative", "")
		main._load_level("yard", false, false)
		await process_frame
		_check(main.operators.map(func(op): return op.ammo) == [1,3,1], "actual scarce start " + strategy)
		_check(main.level.wave_count() == 1 and main.level.spawns_for_wave(0).size() == 3, "single encounter includes delayed flank")
		_collect(main, 0, "rifle_ammo")
		_collect(main, 1, "mg_ammo")
		_collect(main, 2, "scout_ammo")
		_check(main.operators.map(func(op): return op.ammo) == [7,50,6], "real authored primary budget " + strategy)
		var cells := [Vector2i(24,7),Vector2i(15,12),Vector2i(15,10)] if strategy == "high" else [Vector2i(7,11),Vector2i(24,7),Vector2i(28,16)]
		var facings := [180.0,270.0,240.0] if strategy == "high" else [0.0,180.0,180.0]
		if strategy == "ground" and not scenario.get("no_mine",false):
			_collect(main, 0, "mine")
			main._select_op(0)
			main.selected.global_position = main.grid.cell_to_world_center(Vector2i(13,12))
			main._try_place_inventory_mine(main.grid.cell_to_world_center(Vector2i(13,11)))
			_check(main.raid_mines.size() == 1 and main.selected.mines == 0, "real ground tool deployed and consumed")
		for i in 3:
			var op: OperatorUnit = main.operators[i]
			_check(not main.grid.is_blocked(cells[i].x,cells[i].y) and not Paths.find_path(main.grid, main.level.insert_cell_for(i), cells[i]).is_empty(), "authored position reachable " + strategy + str(i))
			op.slot = main.cover_slots[([2,6,7] if strategy == "high" else [0,2,5])[i]]
			op.global_position = main.grid.cell_to_world_center(cells[i]) + scenario.offset
			op.set_facing(facings[i] + scenario.angle)
			op.auto_grenade = false
			if negative == "ammo":
				op.ammo = 0
				op.ammo_pool.clear()
			if negative == "flank" and i in [0,1]:
				op.set_facing(90.0)
			if negative == "tool" and i == 1:
				op.apply_weapon("knife",false)
		if rendered_3d and scenario.offset == Vector2.ZERO and negative.is_empty() and not scenario.get("no_mine",false):
			await _capture(main,strategy + "-prepared")
		main.raid_force_alarm()
		var limit := 0
		while main.phase == main.Phase.WATCHING and limit < 3000:
			main._sim_tick()
			limit += 1
		print("CB3_YARD_STRATEGY ",strategy," offset=",scenario.offset," angle=",scenario.angle," negative=",negative," phase=",main.phase," reason=",main.fail_reason," ticks=",limit," ammo=",main.operators.map(func(op):return op.ammo)," hp=",main.operators.map(func(op):return op.hp))
		if not negative.is_empty():
			_check(main.phase == main.Phase.FAILED, "causal missing " + negative + " fails rather than free win")
		else:
			_check(main.phase == main.Phase.SWEEP, "actual budget strategy wins " + strategy)
			_check(main.operators.all(func(op): return op.alive), "both authored solutions preserve squad " + strategy)
		if main.phase == main.Phase.SWEEP and negative.is_empty():
			if rendered_3d and scenario.offset == Vector2.ZERO and not scenario.get("no_mine",false):
				await _capture(main,strategy + "-cleared")
			main._on_sweep_commit()
			_check(main.phase == main.Phase.WON, "one encounter extracts " + strategy)
	print("CB3_YARD_CHECKED checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)

func _capture(main: Node, label: String) -> void:
	var before: Dictionary = main._snapshot_data().duplicate(true)
	main.presentation_3d.refresh()
	_check(main._snapshot_data() == before, "3D refresh does not alter authored battle " + label)
	if DisplayServer.get_name() == "headless":
		return
	root.size = Vector2i(1280,720)
	main.presentation_3d.rig.reset_view()
	main.presentation_3d.refresh()
	for draw in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	var directory := "res://build/ambush_test_runs/%s/captures" % OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory + "/" + label + ".png"
	_check(root.get_texture().get_image().save_png(path) == OK, "save actual 3D " + label)
	print("CB3_YARD_CAPTURE ",ProjectSettings.globalize_path(path))
