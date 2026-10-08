extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
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
		push_error("CB4_CHECKPOINT: " + label)

func _run() -> void:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	var checkpoint = main.preparation_checkpoint
	var op = main.operators[0]
	op.receive_item("rifle_ammo", 6)
	op.receive_item("grenade", 2)
	# Produce a corpse through the real stealth action, then bind and carry it.
	var sentry = main.c2.sentries[0]
	op.global_position = sentry.global_position + Vector2(0, 8)
	_check(main.c2._skill_knife(op), "real stealth action succeeds")
	sentry.bind_gag()
	op.haul_loot(main.loot_piles[0])
	main.visual_snapshot.corpses.action(main, op, op.hauled_loot, "grab")
	var searcher = main.operators[1]
	searcher.global_position = main.raid_stashes[0].global_position
	searcher.begin_search(main.raid_stashes[0])
	searcher.tick_search(0.2)
	main._select_op(2)
	main.selected.receive_item("mine", 1)
	main.selected.global_position = main.grid.cell_to_world_center(Vector2i(13, 12))
	main._try_place_inventory_mine(main.grid.cell_to_world_center(Vector2i(13, 11)))
	_check(main.raid_mines.size() == 1, "real mine consumed and deployed")
	main.selected.receive_item("grenade", 1)
	main._throw_grenade_from(main.selected, main.selected.global_position + Vector2(64, 0))
	_check(main.raid_grenades.size() == 1, "real grenade created")
	var original_ammo: int = op.ammo
	var original_grenades: int = op.grenades
	main._capture_plan()
	checkpoint.capture(main)
	_check(checkpoint.available(main), "complete initial yard checkpoint valid")
	var original: Dictionary = checkpoint.snapshot.duplicate(true)
	var original_position: Vector2 = op.global_position
	for iteration in 5:
		var failed_log = main.battle_log
		var failed_attempt: String = failed_log.attempt_id
		op.ammo = 0
		op.grenades = 0
		op.global_position += Vector2(32, 0)
		# Terminal fixture: exercise the same production retry button as a failure.
		main.phase = main.Phase.FAILED
		main._on_continue_pressed()
		_check(main.phase == main.Phase.SETUP, "retry returns setup %d" % iteration)
		_check(op.ammo == original_ammo and op.grenades == original_grenades, "exact resource restore %d" % iteration)
		_check(op.global_position == original_position, "position restore %d" % iteration)
		_check(main.battle_log != failed_log and failed_log.attempt_id == failed_attempt, "historical attempt object preserved %d" % iteration)
		_check(checkpoint.snapshot == original, "immutable checkpoint %d" % iteration)
		_check(main.c2.sentries.size() == original.sentries.size(), "sentries restored %d" % iteration)
		_check(main.c2.sentries[0].is_down(), "bound sentry remains down %d" % iteration)
		_check(op.is_hauling() and op.hauled_loot == main.loot_piles[0], "carry links rebuilt %d" % iteration)
		_check(searcher.is_searching() and is_equal_approx(searcher.search_t, 0.2), "partial search restored %d" % iteration)
		_check(is_equal_approx(searcher.search_stash.search_progress, 0.5), "crate progress restored %d" % iteration)
		_check(main.visual_snapshot.corpses.records.size() == 1, "body record restored %d" % iteration)
		_check(main.raid_mines.size() == 1 and main.raid_grenades.size() == 1, "deployed tools restored %d" % iteration)
		var frame: Dictionary = main._snapshot_data()
		_check(frame.get("corpses", []).size() == 1, "body visible in snapshot %d" % iteration)
		_check(main.battle_log.playback_snapshots.size() == 1 and main.battle_log.playback_snapshots[0].data.corpses.size() == 1, "no provisional fresh-map replay frame %d" % iteration)
	checkpoint.snapshot.version = -1
	_check(not checkpoint.available(main), "unknown version rejected")
	main.phase = main.Phase.FAILED
	_check(not checkpoint.restore(main), "invalid version cannot mutate world")
	checkpoint.snapshot = original.duplicate(true)
	checkpoint.snapshot.terrain = []
	_check(not checkpoint.available(main), "malformed terrain rejected without runtime error")
	checkpoint.snapshot = original.duplicate(true)
	main.phase = main.Phase.SETUP
	_check(not checkpoint.restore(main), "restore outside failure rejected")
	main._start_setup(false, false)
	op = main.operators[0]
	for guard in main.c2.sentries:
		op.global_position = guard.global_position + Vector2(0, 8)
		_check(main.c2._skill_knife(op), "real quiet-yard takedown")
	var pre_reward: int = op.grenades
	for iteration in 3:
		main.raid_force_alarm()
		_check(main.phase == main.Phase.WATCHING and op.grenades == pre_reward + 1, "quiet reward once per restored attempt %d" % iteration)
		# Fault-injection terminal fixture, not a claimed played combat victory.
		main._fail_squad_wipe()
		main._on_continue_pressed()
		_check(op.grenades == pre_reward and main.c2.sentries.size() > 0, "retry rolls back bonus and preserves quiet-yard preparation %d" % iteration)
	print("CB4_CHECKPOINT_RESULT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
