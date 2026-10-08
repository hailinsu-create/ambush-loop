extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const Guide := preload("res://scripts/raid/yard_guide.gd")
const Status := preload("res://scripts/presentation/tactical_status.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
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
		push_error("CB4_TEACHING: " + label)

func _run() -> void:
	var gs = root.get_node("GameSettings")
	gs.mark_tutorial_seen("yard")
	gs.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	_check(TutorialOverlay.pages_for("yard").size() == 4, "four short pages")
	_check(Guide.line(main).begins_with("1/4"), "fresh world asks for supplies")
	var op = main.operators[0]
	var stash = main.raid_stashes[0]
	op.global_position = stash.global_position
	op.begin_search(stash)
	op.tick_search(0.4)
	_check(main._complete_stash_search(op), "real crate collection")
	_check(Guide.line(main).begins_with("2/4"), "collection advances to cover placement")
	for i in 3:
		main._select_op(i)
		var slot = main.cover_slots[[2,6,7][i]]
		main.selected.global_position = slot.global_position
		main._deploy_selected_to(slot, false)
		main.selected.set_facing(90.0)
	_check(Guide.line(main).begins_with("3/4"), "uncovered flank asks for aiming")
	for i in 3:
		main.operators[i].set_facing([180.0,270.0,240.0][i])
	_check(Guide.line(main).begins_with("4/4"), "two covered routes ask for final resource check, not guaranteed win")
	var world: Dictionary = main._snapshot_data().duplicate(true)
	var before: String = main.battle_log.fingerprint()
	var frame: Dictionary = ViewState.capture(main)
	_check(Status.line(frame).begins_with("4/4") and Status.line(frame).contains("弹"), "actual 3D reader keeps guide and ammo")
	main.presentation_3d.refresh()
	_check(main._snapshot_data() == world and main.battle_log.fingerprint() == before, "guide rendering is read-only")
	main.battle_log.add_command_snapshot(0, world)
	var historical = main.battle_log
	main.battle_log = BattleLog.new()
	main._start_setup(true, false)
	main.replay.bind(historical)
	main.phase = main.Phase.REPLAY
	main.replay.scrub_tick = 0
	var saved: Dictionary = ViewState.capture(main)
	_check(saved.yard_guide == world.yard_guide, "replay uses saved guide, never fresh world progress")
	main.phase = main.Phase.SETUP
	main.tutorial_overlay.present("yard")
	for i in 4: main.tutorial_overlay._on_next()
	_check(not main.tutorial_overlay.is_open() and gs.has_seen_tutorial("yard"), "tutorial closes and remembers completion")
	main._maybe_show_tutorial()
	_check(not main.tutorial_overlay.is_open(), "completed tutorial not forced on reentry")
	main._load_level("warehouse", false, false)
	_check(Guide.line(main).is_empty(), "yard guide never leaks into other missions")
	print("CB4_TEACHING_RESULT checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
