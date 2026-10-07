extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("EQUIPMENT_FREEZE: " + message)


func _inventory(main: Node) -> Array:
	var result := []
	for op in main.operators:
		result.append({"weapon": op.weapon_id, "ammo": op.ammo, "pool": op.ammo_pool.duplicate(true),
			"slots": op.pack.slots.duplicate(true), "grenades": op.grenades, "mines": op.mines,
			"auto": op.auto_grenade, "facing": op.facing_deg, "pos": op.global_position})
	result.append(main.loot_piles.size())
	return result


func _fixture(main: Node) -> void:
	main._load_level("yard", false, false)
	main.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.selected.receive_item("m1911", 5)
	main.operators[1].global_position = main.selected.global_position + Vector2(24, 0)


func _run() -> void:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	root.get_node("GameSettings").set_force_touch_hud(true)
	main._ensure_touch_hud()
	for state in ["alert", "paused_alert", "replay"]:
		for action in ["open", "equip", "pass", "drop", "auto", "touch_auto", "nearest_pass", "direct_pass"]:
			_fixture(main)
			main.raid_force_alarm()
			main.sim.paused = state == "paused_alert"
			if state == "replay":
				main._sim_tick()
				main._on_replay_pressed()
			var before := _inventory(main)
			main._update_hud()
			_check(main.bag_button.disabled and main.touch_hud._btns.bag.disabled and main.touch_hud._btns.nade_watch.disabled, state + " HUD reflects equipment lock")
			match action:
				"open":
					var key := InputEventKey.new()
					key.physical_keycode = KEY_I
					key.pressed = true
					main._unhandled_input(key)
					_check(not main.backpack_panel.is_open(), state + " I key rejects backpack")
					main.backpack_panel.dismiss()
				"equip": main.backpack_panel.equip_requested.emit("m1911")
				"pass": main.backpack_panel.pass_requested.emit("grenade")
				"drop": main.backpack_panel.drop_requested.emit("mine")
				"auto": main.backpack_panel.auto_grenade_requested.emit()
				"touch_auto": main.apply_touch_command("nade_watch")
				"nearest_pass": main._transfer_selected_to_nearest()
				"direct_pass":
					var rec: Dictionary = main.raid_transfer(0, 1, "grenade")
					_check(not rec.get("ok", true), state + " public transfer rejects")
			_check(before == _inventory(main), state + " " + action + " preserves inventory and plan")
	for state in ["scout", "sweep"]:
		_fixture(main)
		main.phase = main.Phase.SETUP if state == "scout" else main.Phase.SWEEP
		for op in main.operators:
			op.unlock_plan()
		main._toggle_backpack()
		_check(main.backpack_panel.is_open(), state + " backpack opens")
		main.backpack_panel.equip_requested.emit("m1911")
		_check(main.selected.weapon_id == "m1911", state + " equip succeeds")
		var grenades: int = main.operators[1].grenades
		main.backpack_panel.pass_requested.emit("grenade")
		_check(main.operators[1].grenades == grenades + 1, state + " nearby transfer succeeds")
		var loot: int = main.loot_piles.size()
		main.backpack_panel.drop_requested.emit("mine")
		_check(main.loot_piles.size() == loot + 1, state + " drop creates one pickup")
		var auto: bool = main.selected.auto_grenade
		main.backpack_panel._auto_btn.pressed.emit()
		_check(main.selected.auto_grenade != auto, state + " auto-grenade policy changes")
		main.backpack_panel.dismiss()
	_fixture(main)
	main._toggle_backpack()
	main.raid_force_alarm()
	_check(not main.backpack_panel.is_open(), "alarm dismisses an existing editable backpack")
	var before := _inventory(main)
	main.selected.equip_from_pack("m1911")
	main.selected.drop_from_pack("mine")
	main.selected.transfer_to(main.operators[1], "grenade")
	_check(before == _inventory(main), "locked actor rejects direct inventory mutations")
	if failures == 0:
		print("EQUIPMENT_FREEZE_OK checks=", checks)
	else:
		print("EQUIPMENT_FREEZE_FAILED failures=", failures, " checks=", checks)
	quit(0 if failures == 0 else 1)
