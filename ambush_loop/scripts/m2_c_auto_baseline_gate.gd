extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(180.0).timeout.connect(func(): quit(3))
	var main = await _open_yard("AUTO_BASELINE")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	main.raid_force_alarm()
	_run_battle(main)
	_expect(main.phase == main.Phase.WON, "M2_C_AUTO_BASELINE_REAL_WIN")
	var state: Array = []
	for op in main.operators: state.append([op.op_id, op.global_position, op.facing_deg, op.hp, op.alive, op.weapon_id, op.ammo, op.ammo_pool, op.pack.slots])
	var signature := str([main.battle_log.events, main.battle_log.terminal_tick, main.battle_log.terminal_reason, state]).sha256_text()
	print("M2_C_AUTO_BASELINE_SHA=" + signature)
	# Measured before C on D1 3d46d88, run 90e09a4986804d07bbc995a6ab95a3f7.
	_expect(signature == "eebea14acdbc017cae9b39b759a7c52725eef1df58cbef205a5780b6bea9db53", "M2_C_AUTO_PRE_C_AUTHORITATIVE_PARITY")
	if failures.is_empty(): quit(0)
	else: _finish_failed()
