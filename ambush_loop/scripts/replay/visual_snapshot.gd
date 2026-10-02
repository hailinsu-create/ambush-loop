extends RefCounted

## Presentation history owns copies and object IDs; it never writes to simulation nodes.
## Snapshot format 1 accompanies BattleLog's independent timeline schema.
const FORMAT_VERSION := 1
var _identity := ""
var _objects := {}
var _next_ids := {}


func capture(host: Node) -> Dictionary:
	var identity := "%s:%s" % [host.level.level_id, host.battle_log.attempt_id]
	if identity != _identity:
		_identity = identity
		_objects.clear()
		_next_ids.clear()
	var data := {"visual_schema": FORMAT_VERSION, "phase": int(host.phase),
		"level_id": str(host.level.level_id), "blocked": host.grid.blocked.duplicate(),
		"escape": host.escape_world, "door_locked": host.door_locked,
		"selected_id": host.selected.op_id if host.selected != null else -1,
		"ops": [], "enemies": [], "sentries": [], "covers": [], "stashes": [],
		"loot": [], "barrels": [], "tripwires": [], "mines": [], "grenades": [], "decoys": []}
	for op in host.operators:
		var action := "idle"
		if not op.alive:
			action = "death"
		elif op.is_hauling():
			action = "haul"
		elif op.is_searching():
			action = "pickup"
		elif op.is_moving():
			action = "crouch_walk" if op.stance == OperatorUnit.Stance.CROUCH else ("run" if op.sprinting else "walk")
		elif op.shot_cd > 0.0:
			action = "fire"
		elif op.stance == OperatorUnit.Stance.CROUCH:
			action = "crouch"
		elif op.locked:
			action = "aim"
		data.ops.append({"id": op.op_id, "pos": op.global_position, "active": op.visible,
			"hp": op.hp, "ammo": op.ammo, "alive": op.alive, "facing": op.facing_deg,
			"role": op.role, "weapon": op.weapon_id, "moving": op.is_moving(),
			"stance": op.stance, "sprinting": op.sprinting, "hidden": op.hidden_in_shadow,
			"hauling": op.is_hauling(), "searching": op.is_searching(), "search_t": op.search_t,
			"action": action, "shot_cd": op.shot_cd, "shot_interval": op.shot_interval,
			"locked": op.locked, "fire_mode": op.fire_mode, "fire_permitted": op.fire_permitted,
			"grenades": op.grenades, "mines": op.mines, "decoys": op.decoys,
			"auto_grenade": op.auto_grenade, "nade_mark": op.nade_mark,
			"has_nade_mark": op.has_nade_mark, "inventory": op.pack.items(),
			"ammo_pool": op.ammo_pool.duplicate(true),
			"cone": op.cone.polygon.duplicate() if op.cone != null else PackedVector2Array()})
	for enemy in host.enemies:
		if not is_instance_valid(enemy):
			continue
		var moving: bool = enemy.active and enemy.alive and enemy.route_index < enemy.route.size() and enemy._distract_t <= 0.0
		var action := "death" if not enemy.alive else ("fire" if enemy.returning_fire else ("walk" if moving else "idle"))
		data.enemies.append({"id": enemy.label_id, "pos": enemy.global_position,
			"active": enemy.visible, "alive": enemy.alive, "hp": enemy.hp,
			"facing": enemy.facing_deg, "route": enemy.spawn_route, "moving": moving,
			"alerted": enemy.alerted, "returning_fire": enemy.returning_fire,
			"echo_kit": enemy.echo_kit, "action": action,
			"target_id": enemy.focus_target.op_id if is_instance_valid(enemy.focus_target) else -1})
	if host.c2 != null:
		for sentry in host.c2.sentries:
			if not is_instance_valid(sentry):
				continue
			data.sentries.append({"id": sentry.label_id, "pos": sentry.global_position,
				"active": sentry.visible, "alive": not sentry.is_down(), "facing": sentry.facing_deg,
				"state": sentry.state, "suspicion": sentry.suspicion, "frozen": sentry.frozen,
				"action": "death" if sentry.is_down() else ("idle" if sentry.frozen else "walk"),
				"cone": sentry.cone.polygon.duplicate() if sentry.cone != null else PackedVector2Array()})
	for slot in host.cover_slots:
		var item := _object(slot, "covers")
		item["facing"] = float(slot.get_meta("default_face", 90.0))
		data.covers.append(item)
	for stash in host.raid_stashes:
		if is_instance_valid(stash) and not stash.collected:
			var item := _object(stash, "stashes")
			item.merge({"kind": stash.kind, "amount": stash.amount, "progress": stash.search_progress})
			data.stashes.append(item)
	for loot in host.loot_piles:
		if is_instance_valid(loot) and not loot.collected:
			var item := _object(loot, "loot")
			item.merge({"kind": loot.kind, "amount": loot.ammo_amount})
			data.loot.append(item)
	for barrel in host.barrels:
		if is_instance_valid(barrel):
			var item := _object(barrel, "barrels")
			item.merge({"armed": barrel.armed, "spent": barrel.spent})
			data.barrels.append(item)
	for group in [["tripwires", host.tripwires], ["mines", host.raid_mines]]:
		for trap in group[1]:
			if is_instance_valid(trap):
				var item := _object(trap, group[0])
				item.merge({"armed": trap.armed, "spent": trap.spent})
				data[group[0]].append(item)
	for grenade in host.raid_grenades:
		if is_instance_valid(grenade) and not grenade.spent():
			var item := _object(grenade, "grenades")
			item.merge({"variant": grenade.variant, "origin": grenade._origin,
				"target": grenade.target, "flight": grenade._flight,
				"flight_duration": grenade._flight_t, "fuse": grenade.fuse})
			data.grenades.append(item)
	for decoy in host.raid_decoys:
		if is_instance_valid(decoy) and not decoy.spent:
			var item := _object(decoy, "decoys")
			item.merge({"life": decoy.life, "elapsed": decoy._t})
			data.decoys.append(item)
	return data


func _object(node: Node2D, group: String) -> Dictionary:
	var key := node.get_instance_id()
	if not _objects.has(key):
		var next := int(_next_ids.get(group, 0))
		_objects[key] = "%s:%d" % [group, next]
		_next_ids[group] = next + 1
	return {"id": _objects[key], "pos": node.global_position, "active": node.visible}
