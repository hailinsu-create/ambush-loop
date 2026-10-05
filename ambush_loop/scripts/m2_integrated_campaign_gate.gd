extends "res://scripts/m2_yard_supply_gate.gd"

## Focused six-mission authority/advance gate; NOT a replacement for full smoke.
func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	var main = await _open_yard("M2_INTEGRATED_CAMPAIGN")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	var order := ["yard", "warehouse", "pump", "railcut", "depot", "radio"]
	for id in order:
		_expect(str(main.level.level_id) == id, "M2_CAMPAIGN_REAL_ADVANCE_" + id)
		if str(main.level.level_id) != id:
			_finish_failed()
			return
		if main.tutorial_overlay.is_open():
			for _page in 3: main.tutorial_overlay._on_next()
		if id != "yard":
			var faces := [180.0, 0.0, 180.0] if id == "warehouse" else ([90.0, 0.0, 180.0] if id == "pump" else ([270.0, 90.0, 270.0] if id == "radio" else [270.0, 270.0, 180.0]))
			main.raid_prepare_ref([1, 3, 5] if id == "warehouse" else [1, 4, 5], faces)
			if id == "warehouse": main._play_hold_pack(1)
			if id in ["depot", "radio"]:
				main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7, 11)))
		main.raid_force_alarm()
		_run_battle(main)
		_expect(main.phase == main.Phase.WON and main.battle_log.terminal_reason == "win", "M2_CAMPAIGN_ALL_WAVES_REAL_WIN_" + id)
		_expect(main._gs().is_level_cleared(id), "M2_CAMPAIGN_WIN_RECORDED_" + id)
		if main.phase != main.Phase.WON:
			print("M2_CAMPAIGN_FAILURE level=%s reason=%s tick=%s" % [id, main.fail_reason, main.sim.tick])
			_finish_failed()
			return
		print("M2_CAMPAIGN_LEVEL_OK id=%s waves=%d events=%d terminal=%d" % [id, main.level.wave_count(), main.battle_log.events.size(), main.battle_log.terminal_tick])
		if id != "radio":
			main._on_continue_pressed()
			await _frames(3)
			main.set_process(false)
			for op in main.operators: op.set_process(false)
	_expect(main._campaign_complete and main._gs().is_campaign_complete(), "M2_CAMPAIGN_COMPLETE_PROFILE")
	if failures.is_empty():
		print("M2_INTEGRATED_CAMPAIGN_OK six_missions=1 real_advance=1 original_five=1 credits_unlock=1")
		quit(0)
	else: _finish_failed()
