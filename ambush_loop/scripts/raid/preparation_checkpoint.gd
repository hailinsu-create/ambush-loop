extends RefCounted

## In-memory, pre-alarm only. Never load battle progress or grant extra supply.
const VERSION := 2
const Weapons := preload("res://scripts/raid/weapon_catalog.gd")
const FIELDS := ["ammo", "grenades", "mines", "decoys", "stance", "auto_grenade", "has_ammo_pack", "ammo_pack_used", "visible", "follow_lead", "hp", "alive"]
var snapshot: Dictionary = {}

func clear() -> void:
	snapshot.clear()

func _signature(main) -> String:
	if main.level == null or main.level.level_id != "yard": return ""
	var rules := [VERSION, main.YARD_PERMISSION_CONTRACT, main.level.level_id, main.level.stashes, main.level.waves, main.level.route_cells, main.level.starting_loadouts, main.level.ambush_zone, main.grid.blocked, main.grid.elevation_tier, main.grid.occlusion_kind, main.grid.ramp_links]
	for weapon in ["kar98k", "mg42", "kar98k_zf", "grenade"]: rules.append(Weapons.def(weapon))
	return str(rules).sha256_text()

func available(main) -> bool:
	return not snapshot.is_empty() and str(snapshot.get("signature", "")) == _signature(main)

func capture(main) -> void:
	clear()
	if main.level == null or main.level.level_id != "yard" or main.phase != main.Phase.SETUP: return
	var crew: Array = []
	for op in main.operators:
		var record := {"id": op.op_id, "position": op.global_position, "facing": op.facing_deg, "weapon": op.weapon_id, "ammo_pool": op.ammo_pool.duplicate(true), "pack": op.pack.slots.duplicate(true), "slot": op.slot.slot_id if op.slot else -1, "fire_mode": op.fire_mode, "has_mark": op.has_nade_mark, "mark": op.nade_mark}
		for field in FIELDS: record[field] = op.get(field)
		crew.append(record)
	var crates: Array = []
	for stash in main.raid_stashes:
		if is_instance_valid(stash) and not stash.collected: crates.append({"cell": stash.cell, "kind": stash.kind, "amount": stash.amount})
	snapshot = {"signature": _signature(main), "manual_permission": main.yard_manual_permission, "crew": crew, "crates": crates, "selected": main.selected.op_id if main.selected else -1, "plan": main.last_plan.duplicate_plan()}

func restore(main) -> bool:
	if not available(main) or main.phase != main.Phase.FAILED: return false
	var state := snapshot.duplicate(true)
	# Validate all IDs/cells before mutating live state.
	if state.crew.size() != main.operators.size(): return false
	for record in state.crew:
		var op = main._op_by_id(int(record.id))
		var cell: Vector2i = main.grid.world_to_cell(record.position)
		if op == null or main.grid.is_blocked(cell.x, cell.y): return false
	main.last_plan = state.plan.duplicate_plan()
	main._checkpoint_restoring = true
	main._start_setup(true, false, true)
	main.yard_manual_permission = bool(state.get("manual_permission", false))
	main.frozen_plan.clear()
	for slot in main.cover_slots: slot.occupied_by = null
	for record in state.crew:
		var op = main._op_by_id(int(record.id))
		op.stop_move()
		op.cancel_search()
		op.grenade_cd = 0.0
		op.ammo = 0
		op.ammo_pool.clear()
		if op.weapon_id != str(record.weapon): op.apply_weapon(str(record.weapon), false)
		op.ammo_pool = record.ammo_pool.duplicate(true)
		op.pack.slots = record.pack.duplicate(true)
		for field in FIELDS: op.set(field, record[field])
		op.global_position = record.position
		op.slot = main._slot_by_id(int(record.slot)) if int(record.slot) >= 0 else null
		if op.slot: op.slot.occupied_by = op
		op.locked = false
		op.set_fire_mode(int(record.fire_mode))
		op.set_facing(float(record.facing))
		op.apply_stance_speed()
		op._update_hp_bar()
		if bool(record.has_mark): op.set_nade_mark(record.mark)
		else: op.clear_nade_mark()
	for position in state.plan.tripwire_positions:
		var wire = main._make_tripwire(position)
		main.entities.add_child(wire)
		main.tripwires.append(wire)
	main._clear_stashes()
	for crate in state.crates:
		var stash = main.RaidStashScript.new()
		main.entities.add_child(stash)
		stash.global_position = main.grid.cell_to_world_center(crate.cell)
		stash.setup(str(crate.kind), int(crate.amount), crate.cell)
		main.raid_stashes.append(stash)
	main.selected = main._op_by_id(int(state.selected))
	main._checkpoint_restoring = false
	main._refresh_selection_visual()
	main._update_cover_previews()
	main._update_observation_rings()
	main._update_tripwire_ghost()
	main._build_plan_ghosts()
	main._refresh_killzone_preview()
	main._update_role_cards()
	main._update_hud()
	return true
