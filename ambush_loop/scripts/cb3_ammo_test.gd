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
		push_error("CB3_AMMO: " + label)

func _reset(op: OperatorUnit) -> void:
	op.explicit_ammo = true
	op.locked = false
	op.alive = true
	op.wipe_inventory()

func _run() -> void:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	var a: OperatorUnit = main.operators[0]
	var b: OperatorUnit = main.operators[1]
	_reset(a)
	_reset(b)
	a.receive_item("kar98k", 1)
	a.receive_item("rifle_ammo", 6)
	_check(a.ammo == 7, "exact authored 1+6, no equipment grant")
	for repeat in 20:
		a.apply_weapon("knife", true)
		a.apply_weapon("kar98k", true)
		_check(a.ammo == 7, "equip roundtrip does not mint ammo %d" % repeat)
	a.ammo = 0
	for repeat in 10:
		a.apply_weapon("knife", true)
		a.apply_weapon("kar98k", true)
		_check(a.ammo == 0, "empty roundtrip remains empty %d" % repeat)
	a.receive_ammo(9)
	_check(a.ammo == 9, "exact refill")
	a.receive_item("mg42", 0)
	a.receive_item("mg_ammo", 50)
	_check(a.ammo == 9, "different family does not alter held magazine")
	a.apply_weapon("mg42", false)
	_check(a.ammo == 50, "all 50 rounds survive legacy magazine capacity")
	var transfer: Dictionary = a.transfer_to(b, "mg42")
	_check(transfer.ok and b.ammo == 50 and int(a.ammo_pool.get("mg", 0)) == 0, "real transfer moves pool once")
	var dropped: Dictionary = b.drop_from_pack("mg42")
	_check(dropped.ok and dropped.amount == 50, "real drop exports exact remaining ammo")
	a.receive_item(dropped.kind, dropped.amount)
	a.apply_weapon("mg42", false)
	_check(a.ammo == 50, "drop pickup conservation")
	a.ammo = 0
	a.apply_weapon("knife", false)
	a.apply_weapon("mg42", false)
	transfer = a.transfer_to(b, "mg42")
	_check(transfer.ok and b.ammo == 0, "empty gun transfer cannot create one round")
	b.locked = true
	var before := {"weapon": b.weapon_id, "ammo": b.ammo, "pool": b.ammo_pool.duplicate(true), "pack": b.pack.items()}
	_check(not b.drop_from_pack("mg42").ok and not b.equip_from_pack("mg42").ok and not b.transfer_to(a, "mg42").ok, "locked equipment actions remain rejected")
	_check(before == {"weapon": b.weapon_id, "ammo": b.ammo, "pool": b.ammo_pool.duplicate(true), "pack": b.pack.items()}, "lock rejection has no side effects")
	_reset(b)
	_check(b.ammo == 0 and b.ammo_pool.is_empty(), "wipe clears previous stashed magazine")
	b.receive_item("mg42", 0)
	_check(b.ammo == 0, "reacquire after reset not failed-attempt magazine")
	_reset(a)
	_check(not a.receive_item("ammo", 8).ok and a.melee, "generic ammo with knife cannot grant a free pistol")
	a.explicit_ammo = false
	a.apply_weapon("rifle", true)
	_check(a.ammo > 0, "other five legacy contracts remain opt-in unchanged")
	print("CB3_AMMO_CHECKED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
