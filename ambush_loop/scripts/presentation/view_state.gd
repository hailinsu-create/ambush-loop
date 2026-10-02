extends RefCounted

## Copy plain values across the presentation seam; never expose Nodes or live containers.
## This adapter does not tick the simulation, mutate actors, or play audio.

static func capture(host: Node) -> Dictionary:
	var frame := {
		"run_id": host.run_id, "tick": host.sim.tick, "phase": int(host.phase),
		"schema": BattleLog.SCHEMA_VERSION, "attempt_id": host.battle_log.attempt_id,
		"wave_id": host.battle_log.wave_id, "local_tick": host.sim.tick,
		"level_id": str(host.level.level_id), "blocked": host.grid.blocked.duplicate(),
		"selected_id": host.selected.op_id if host.selected != null else -1,
		"escape": host.escape_world, "replay": host.phase == host.Phase.REPLAY,
		"ops": [], "enemies": [], "sentries": [], "stashes": [], "covers": [],
		"loot": [], "events": [],
	}
	for slot in host.cover_slots:
		frame.covers.append({"id": slot.get_instance_id(), "pos": slot.global_position,
			"facing": float(slot.get_meta("default_face", 90.0))})
	if frame.replay:
		var snap: Dictionary = host.replay.snapshot_at_or_before(host.replay.scrub_tick)
		frame.tick = host.replay.scrub_tick
		frame.run_id = -1
		frame.schema = int(snap.get("schema", 1))
		frame.attempt_id = str(snap.get("attempt_id", ""))
		frame.wave_id = int(snap.get("wave_id", -1))
		frame.local_tick = int(snap.get("tick", 0))
		frame.events = host.replay.events_up_to(host.replay.scrub_tick).duplicate(true)
		var data: Dictionary = snap.get("data", {})
		# Missing historical fields use neutral defaults, never live actor equipment.
		for op in data.get("ops", []):
			var copy: Dictionary = op.duplicate(true)
			copy["active"] = true
			copy["weapon"] = str(copy.get("weapon", ""))
			copy["cone"] = PackedVector2Array()
			frame.ops.append(copy)
		for enemy in data.get("enemies", []):
			var copy: Dictionary = enemy.duplicate(true)
			copy["active"] = true
			copy["facing"] = float(copy.get("facing", 90.0))
			frame.enemies.append(copy)
	else:
		frame.tick = host.battle_log.timeline_tick(host.sim.tick)
		frame.events = host.battle_log.events.duplicate(true)
		for op in host.operators:
			frame.ops.append({"id": op.op_id, "pos": op.global_position,
				"active": op.visible, "alive": op.alive, "hp": op.hp, "ammo": op.ammo,
				"facing": op.facing_deg, "role": op.role, "moving": op.is_moving(),
				"cone": op.cone.polygon.duplicate() if op.cone != null else PackedVector2Array()})
		for enemy in host.enemies:
			if not is_instance_valid(enemy):
				continue
			frame.enemies.append({"id": enemy.label_id, "pos": enemy.global_position,
				"active": enemy.visible, "alive": enemy.alive, "hp": enemy.hp,
				"facing": enemy.facing_deg, "route": enemy.spawn_route})
		if host.c2 != null:
			for sentry in host.c2.sentries:
				if not is_instance_valid(sentry):
					continue
				frame.sentries.append({"id": sentry.label_id, "pos": sentry.global_position,
					"active": sentry.visible, "alive": not sentry.is_down(),
					"facing": sentry.facing_deg,
					"cone": sentry.cone.polygon.duplicate() if sentry.cone != null else PackedVector2Array()})
		for stash in host.raid_stashes:
			if is_instance_valid(stash) and not stash.collected:
				frame.stashes.append({"id": stash.get_instance_id(), "pos": stash.global_position,
					"kind": stash.kind, "progress": stash.search_progress})
		for loot in host.loot_piles:
			if is_instance_valid(loot) and not loot.collected:
				frame.loot.append({"id": loot.get_instance_id(), "pos": loot.global_position})
	# Consumers may retain frames safely across resets and replay scrubs.
	_freeze(frame)
	return frame


static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child in value.values():
			_freeze(child)
		value.make_read_only()
	elif value is Array:
		for child in value:
			_freeze(child)
		value.make_read_only()
