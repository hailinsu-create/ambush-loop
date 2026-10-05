extends "res://scripts/viewport_hud_test.gd"
## Controlled adjacency/tool/phase fixtures; normal fresh native flow is separate.
const Commands := preload("res://scripts/input/command_router.gd")
var pad: Node2D

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("COVER_COMMAND_FAIL " + message)

func _adjacent() -> void:
	main.phase = main.Phase.SETUP
	main.tool = main.Tool.DEPLOY
	main._select_op(2)
	if main.selected.slot:
		main.selected.slot.occupied_by = null
		main.selected.slot = null
	main.selected.unlock_plan()
	main.selected.stop_move()
	main.selected.global_position = pad.global_position + Vector2(32, 0)

func _units() -> Array:
	var values := []
	for op in main.operators:
		values.append([op.global_position, op.facing_deg, op.hp, op.ammo, op.grenades, op.mines, op.decoys, op.pack.slots.duplicate(true), op.slot.slot_id if op.slot else -1])
	values.append([main.raid_mines.size(), main.raid_decoys.size()])
	return values

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	pad = main.cover_slots[5]
	var pick := {"valid":true, "kind":"covers", "id":"covers:5", "pos":pad.global_position}
	_adjacent()
	# Keep the original legacy proximity behavior for 2D/untyped ground input.
	main._handle_setup_click(pad.global_position)
	_check(main.selected.slot == null and main.selected.global_position == pad.global_position + Vector2(32, 0), "legacy2D body selection at32px retains its original behavior")
	_check(Commands.dispatch(main, "primary", {"valid":true,"kind":"ground","pos":pad.global_position}), "untyped ground route remains accepted")
	_check(main.selected.slot == null, "ground routing retains original body priority")
	for phase in [main.Phase.SETUP, main.Phase.SWEEP]:
		_adjacent()
		main.phase = phase
		_check(Commands.dispatch(main, "primary", pick), "explicit cover accepted in legal command phase " + str(phase))
		_check(main.selected.slot == pad and pad.occupied_by == main.selected and main.selected.global_position == pad.global_position, "explicit cover deploys intended actor/pad despite adjacent body")
		rows.append({"phase":phase,"target_slot":pad.slot_id,"actual_slot":main.selected.slot.slot_id if main.selected.slot else -1})
	for state in ["alert", "paused_alert", "replay"]:
		_adjacent()
		main.phase = main.Phase.REPLAY if state == "replay" else main.Phase.WATCHING
		main.sim.paused = state == "paused_alert"
		var before := _units()
		_check(not Commands.dispatch(main, "primary", pick), state + " rejects explicit cover")
		_check(_units() == before, state + " keeps positions/equipment/slots unchanged")
	_adjacent()
	main._toggle_pause_menu()
	var before := _units()
	_check(main.pause_overlay.is_open() and not Commands.dispatch(main, "primary", pick), "settings modal blocks cover")
	_check(before == _units(), "modal cover input is read-only")
	main.pause_overlay.dismiss()
	for pos in [Vector2.INF, Vector2(-1, 0), pad.global_position + Vector2(12, 0)]:
		var invalid := pick.duplicate()
		invalid.pos = pos
		before = _units()
		_check(not Commands.dispatch(main, "primary", invalid) and before == _units(), "invalid/off-anchor explicit cover cannot become movement")
	_adjacent()
	main.selected.receive_item("grenade", 1)
	main.tool = main.Tool.GRENADE
	_check(Commands.dispatch(main, "primary", pick), "grenade tool still routes cover click")
	_check(main.selected.slot == null and main.selected.has_nade_mark and main.selected.nade_mark == pad.global_position and main.selected.grenades == 1, "grenade tool marks original target without deploying or consuming grenade")
	main.selected.receive_item("mine", 1)
	main.tool = main.Tool.TRIPWIRE
	var mines: int = main.raid_mines.size()
	_check(Commands.dispatch(main, "primary", pick), "mine tool still routes cover click")
	_check(main.selected.slot == null and main.raid_mines.size() == mines + 1 and main.selected.mines == 0 and main.raid_mines.back().global_position == pad.global_position, "mine tool consumes fixture item at original target without deploying")
	main.selected.receive_item("decoy", 1)
	main.tool = main.Tool.DECOY
	var decoys: int = main.raid_decoys.size()
	_check(Commands.dispatch(main, "primary", pick), "decoy tool still routes cover click")
	_check(main.selected.slot == null and main.raid_decoys.size() == decoys + 1 and main.selected.decoys == 0 and main.raid_decoys.back().global_position == pad.global_position, "decoy tool consumes fixture item at original target without deploying")
	main.tool = main.Tool.DEPLOY
	_check(Commands.dispatch(main, "primary", {"valid":true,"kind":"op","id":main.operators[0].op_id,"pos":main.operators[0].global_position}) and main.selected == main.operators[0], "explicit body selection still chooses the named actor")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/cover-command-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"fixture":"manual adjacency/phase/item fixtures; not normal player journey"}, "  "))
	root.get_node("AudioDirector").pause_for_background()
	print("COVER_COMMAND_TEST checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
