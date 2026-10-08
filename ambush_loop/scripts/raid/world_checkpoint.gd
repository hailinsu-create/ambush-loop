extends RefCounted

## Complete in-memory pre-alarm world. Never persists campaign progress or Nodes.
const VERSION := 3
const Weapons := preload("res://scripts/raid/weapon_catalog.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Sentry := preload("res://scripts/c2/sentry.gd")
const OP_FIELDS := ["ammo","grenades","mines","decoys","stance","auto_grenade","has_ammo_pack","ammo_pack_used","visible","follow_lead","hp","alive","fire_mode","fire_permitted","shot_cd","grenade_cd","sprinting","hidden_in_shadow","move_path","_path_i","search_t"]
const SENTRY_FIELDS := ["route","route_i","dir","state","facing_deg","suspicion","last_seen","_look_t","_ko_t","frozen"]
const MAIN_FIELDS := ["door_locked","_night_hp_lost","_night_timer","_pose_command_clock_s","_command_record_acc_s"]
const C2_FIELDS := ["skill_cds","binoculars_t","quiet_yard","spotted_bark","cam_follow","quiet_reward_granted"]
const TERRAIN_FIELDS := ["blocked","elevation_tier","occlusion_kind","ramp_links","continuous_surface","door_cell","door_locked"]
const STASH_FIELDS := ["kind","amount","cell","search_progress"]
const LOOT_FIELDS := ["kind","ammo_amount","collected"]
const MINE_FIELDS := ["armed","spent","damage"]
const WIRE_FIELDS := ["armed","spent"]
const GRENADE_FIELDS := ["fuse","radius","damage","target","_origin","_flight","_flight_t","_done","cooked","cook_max","bounced","variant"]
const DECOY_FIELDS := ["radius","life","spent","_t"]
var snapshot: Dictionary = {}

func clear() -> void:
	snapshot.clear()

static func _read(node: Object, fields: Array) -> Dictionary:
	var record := {}
	for field in fields:
		var value: Variant = node.get(field)
		record[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return record

static func _apply(node: Object, record: Dictionary, fields: Array) -> void:
	for field in fields:
		var value: Variant = record[field]
		node.set(field, value.duplicate(true) if value is Array or value is Dictionary else value)

static func _nodes(nodes: Array, fields: Array) -> Array:
	var records := []
	for node in nodes:
		if is_instance_valid(node):
			var record := _read(node, fields)
			record.pos = node.global_position
			records.append(record)
	return records

static func _matches(record: Dictionary, node: Object, fields: Array) -> bool:
	if not record.has_all(fields): return false
	for field in fields:
		var expected := typeof(node.get(field))
		var actual := typeof(record[field])
		if expected != actual and not (expected == TYPE_FLOAT and actual == TYPE_INT):
			return false
	return true

func _signature(main: Node) -> String:
	if main.level == null or main.level.level_id != "yard":
		return ""
	var rules := [VERSION,main.level.level_id,main.level.explicit_ammo,main.level.cover_defs,main.level.stashes,main.level.waves,main.level.route_cells,main.level.starting_loadouts,main.level.ambush_zone,main.level.wall_extra,main.level.door_cell]
	for weapon in ["kar98k","mg42","kar98k_zf","smg","mp40","thompson","grenade","mine"]:
		rules.append(Weapons.def(weapon))
	return str(rules).sha256_text()

static func _plain(value: Variant) -> bool:
	if value is Object or value is Callable or value is Signal:
		return false
	if value is float:
		return is_finite(value)
	if value is Vector2:
		return value.is_finite()
	if value is Dictionary:
		for key in value:
			if not _plain(key) or not _plain(value[key]): return false
	elif value is Array or value is PackedVector2Array:
		for child in value:
			if not _plain(child): return false
	return true

func available(main: Node) -> bool:
	if snapshot.get("version",-1) != VERSION or snapshot.get("signature","") != _signature(main) or not _plain(snapshot):
		return false
	if not snapshot.has_all(["crew","stashes","loot","sentries","bodies","body_seq","terrain","main","c2","plan","selected","empty_stashes","mines","wires","grenades","decoys","barrels"]): return false
	for key in ["terrain", "main", "c2", "plan"]:
		if not snapshot[key] is Dictionary: return false
	for key in ["crew", "stashes", "loot", "sentries", "bodies", "empty_stashes", "mines", "wires", "grenades", "decoys", "barrels"]:
		if not snapshot[key] is Array or snapshot[key].size() > 64: return false
	if not snapshot.selected is int or not snapshot.body_seq is int: return false
	if not snapshot.plan.has_all(["deployments", "tripwires", "door_locked"]): return false
	if not snapshot.plan.deployments is Array or not snapshot.plan.tripwires is Array: return false
	if not _matches(snapshot.main,main,MAIN_FIELDS) or not _matches(snapshot.c2,main.c2,C2_FIELDS) or not _matches(snapshot.terrain,main.grid,TERRAIN_FIELDS): return false
	for pos in snapshot.plan.tripwires:
		if not pos is Vector2: return false
	if not snapshot.crew is Array or snapshot.crew.size() != main.operators.size(): return false
	var terrain: Dictionary = snapshot.terrain.duplicate(true)
	terrain.height_schema = 2
	if not Space.terrain_supported(terrain): return false
	var ids := {}
	var occupied := {}
	for record in snapshot.crew:
		if not record is Dictionary or not record.has_all(OP_FIELDS + ["id","pos","weapon","pool","pack","slot","facing","haul","search","has_mark","mark"]): return false
		if not record.id is int or not record.slot is int or not record.haul is int or not record.search is int or not record.has_mark is bool or not record.mark is Vector2 or not record.weapon is String: return false
		if not (record.facing is float or record.facing is int): return false
		if ids.has(record.id) or main._op_by_id(record.id) == null or not record.pos is Vector2 or not record.pack is Array or record.pack.size() > 6 or not record.pool is Dictionary: return false
		if not _matches(record,main._op_by_id(record.id),OP_FIELDS): return false
		for amount in record.pool.values():
			if not amount is int or amount < 0: return false
		ids[record.id] = true
		if record.visible and record.alive and not main.grid.in_bounds(main.grid.world_to_cell(record.pos).x,main.grid.world_to_cell(record.pos).y): return false
		if record.slot >= 0 and main._slot_by_id(record.slot) == null: return false
		if record.slot >= 0:
			if occupied.has(record.slot): return false
			occupied[record.slot] = true
		if record.haul < -1 or record.haul >= snapshot.loot.size() or record.search < -1 or record.search >= snapshot.stashes.size(): return false
		if record.ammo < 0 or not (record.weapon == "knife" or Weapons.is_firearm(record.weapon)): return false
	for group in [["stashes",STASH_FIELDS],["loot",LOOT_FIELDS],["sentries",SENTRY_FIELDS],["mines",MINE_FIELDS],["wires",WIRE_FIELDS],["grenades",GRENADE_FIELDS],["decoys",DECOY_FIELDS],["barrels",WIRE_FIELDS]]:
		if not snapshot[group[0]] is Array or snapshot[group[0]].size() > 64: return false
		for record in snapshot[group[0]]:
			if not record is Dictionary or not record.has_all(group[1] + ["pos"]) or not record.pos is Vector2: return false
	for body in snapshot.bodies:
		if not body is Dictionary or not body.has_all(["body","loot_index"]) or not body.body is Dictionary or body.loot_index < -1 or body.loot_index >= snapshot.loot.size(): return false
		if not body.body.has_all(["pos","id","scope_id","death_age_s","transition_age_s","transition","source_group","source_actor_id"]): return false
		if not body.body.pos is Vector2 or not body.body.transition is Dictionary: return false
	for key in ["mines", "grenades"]:
		for record in snapshot[key]:
			if not record.get("source") is Dictionary: return false
			if not record.source.is_empty() and (not record.source.has_all(["owner_id","created_pos"]) or not record.source.created_pos is Vector2 or not record.source.owner_id is int or main._op_by_id(record.source.owner_id) == null): return false
	return snapshot.main.has_all(MAIN_FIELDS) and snapshot.c2.has_all(C2_FIELDS) and snapshot.terrain.has_all(TERRAIN_FIELDS)

func capture(main: Node) -> void:
	if main.level == null or main.level.level_id != "yard" or main.phase != main.Phase.SETUP or main.raid.wave_index != 0:
		return
	# Close presentation ages before copying the plain body records.
	main._snapshot_data()
	var stashes: Array = main.raid_stashes.filter(func(node): return is_instance_valid(node) and not node.collected)
	var loot: Array = main.loot_piles.filter(func(node): return is_instance_valid(node))
	var crew := []
	for op in main.operators:
		var record := _read(op, OP_FIELDS)
		record.merge({"id":op.op_id,"pos":op.global_position,"facing":op.facing_deg,"weapon":op.weapon_id,"pool":op.ammo_pool.duplicate(true),"pack":op.pack.slots.duplicate(true),"slot":op.slot.slot_id if op.slot else -1,"haul":loot.find(op.hauled_loot),"search":stashes.find(op.search_stash),"has_mark":op.has_nade_mark,"mark":op.nade_mark})
		crew.append(record)
	var sentries := []
	for sentry in main.c2.sentries:
		if is_instance_valid(sentry):
			var record := _read(sentry,SENTRY_FIELDS)
			record.merge({"id":sentry.label_id,"pos":sentry.global_position})
			sentries.append(record)
	var bodies := []
	var seam = main.visual_snapshot.corpses
	for body in seam.records.values():
		bodies.append({"body":body.duplicate(true),"loot_index":loot.find(seam.links[body.id].get_ref())})
	snapshot = {"version":VERSION,"signature":_signature(main),"crew":crew,"stashes":_nodes(stashes,STASH_FIELDS),"loot":_nodes(loot,LOOT_FIELDS),"sentries":sentries,"bodies":bodies,"body_seq":seam._seq,"empty_stashes":main.visual_snapshot._empty_stashes.duplicate(true),"main":_read(main,MAIN_FIELDS),"c2":_read(main.c2,C2_FIELDS),"terrain":_read(main.grid,TERRAIN_FIELDS),"selected":main.selected.op_id if main.selected else -1,"plan":{"deployments":main.last_plan.deployments.duplicate(true),"tripwires":main.last_plan.tripwire_positions.duplicate(),"door_locked":main.last_plan.door_locked},"wires":_nodes(main.tripwires,WIRE_FIELDS),"barrels":_nodes(main.barrels,WIRE_FIELDS),"decoys":_nodes(main.raid_decoys,DECOY_FIELDS),"mines":_tools(main,main.raid_mines,MINE_FIELDS),"grenades":_tools(main,main.raid_grenades,GRENADE_FIELDS)}

static func _tools(main: Node, nodes: Array, fields: Array) -> Array:
	var records := []
	for tool in nodes:
		if is_instance_valid(tool):
			var record := _read(tool,fields)
			record.pos = tool.global_position
			record.source = main.visual_snapshot.tool_fx._tools.get(tool.get_instance_id(),{}).get("born",{}).duplicate(true)
			records.append(record)
	return records

func restore(main: Node) -> bool:
	if main.phase != main.Phase.FAILED or not available(main):
		return false
	var state := snapshot.duplicate(true)
	main._checkpoint_restoring = true
	# Preserve the failed attempt object for historical replay; start a fresh log.
	main.battle_log = BattleLog.new()
	main._start_setup(true,false)
	# Discard the provisional boot frame, not its identity. The first frame of
	# this new attempt must describe the restored world, never the fresh map.
	main.battle_log.playback_snapshots.clear()
	_apply(main,state.main,MAIN_FIELDS)
	_apply(main.grid,state.terrain,TERRAIN_FIELDS)
	main.grid.tactical_revision += 1
	if main.c2.shadows:
		main.c2.shadows.setup(main.grid, str(main.level.level_id))
	_apply(main.c2,state.c2,C2_FIELDS)
	main.c2._clear_sentries()
	for record in state.sentries:
		var sentry := Sentry.new()
		main.entities.add_child(sentry)
		sentry.setup(record.id,record.route,main.grid)
		if record.state in [Sentry.State.KO,Sentry.State.BOUND]: sentry.knock_out()
		if record.state == Sentry.State.BOUND: sentry.bind_gag()
		_apply(sentry,record,SENTRY_FIELDS)
		sentry.global_position = record.pos
		sentry.spotted.connect(main.c2._on_sentry_spotted)
		sentry._rebuild_cone()
		main.c2.sentries.append(sentry)
	main._clear_stashes()
	for record in state.stashes:
		var stash = main.RaidStashScript.new()
		main.entities.add_child(stash)
		stash.setup(record.kind,record.amount,record.cell)
		stash.global_position = record.pos
		stash.set_search_progress(record.search_progress)
		main.raid_stashes.append(stash)
	main.visual_snapshot._empty_stashes = state.empty_stashes.duplicate(true)
	for record in state.loot:
		var loot = main._spawn_loot_at(record.pos,maxi(record.ammo_amount,1),record.kind)
		_apply(loot,record,LOOT_FIELDS)
		loot.visible = not record.collected
	for slot in main.cover_slots: slot.occupied_by = null
	for record in state.crew:
		var op = main._op_by_id(record.id)
		op.ammo = 0
		op.ammo_pool.clear()
		op.apply_weapon(record.weapon,false)
		op.ammo_pool = record.pool.duplicate(true)
		op.pack.slots = record.pack.duplicate(true)
		_apply(op,record,OP_FIELDS)
		op.global_position = record.pos
		op.slot = main._slot_by_id(record.slot) if record.slot >= 0 else null
		if op.slot: op.slot.occupied_by = op
		op.locked = false
		op.search_stash = main.raid_stashes[record.search] if record.search >= 0 else null
		op.hauled_loot = main.loot_piles[record.haul] if record.haul >= 0 else null
		op.set_facing(record.facing)
		if record.has_mark: op.set_nade_mark(record.mark)
		else: op.clear_nade_mark()
		op.apply_stance_speed()
		op._apply_body_modulate()
		op._update_hp_bar()
		op._refresh_tag()
	_restore_bodies(main,state)
	_restore_tools(main,state)
	main.last_plan = PlanState.new()
	main.last_plan.deployments = state.plan.deployments.duplicate(true)
	main.last_plan.tripwire_positions = state.plan.tripwires.duplicate()
	main.last_plan.door_locked = state.plan.door_locked
	main.frozen_plan.clear()
	main.selected = main._op_by_id(state.selected)
	main._restored_this_setup = true
	main.plan_restore_hint = "完整准备已恢复 · 物资、岗哨、尸体与搜索进度保留"
	main._checkpoint_restoring = false
	main._refresh_door_visual()
	main._refresh_selection_visual()
	main._update_cover_previews()
	main._update_observation_rings()
	main._build_plan_ghosts()
	main._refresh_killzone_preview()
	main._update_hud()
	main.battle_log.add_command_snapshot(0,main._snapshot_data())
	return true

static func _restore_bodies(main: Node, state: Dictionary) -> void:
	var seam = main.visual_snapshot.corpses
	seam._seq = state.body_seq
	for stored in state.bodies:
		var record: Dictionary = stored.body.duplicate(true)
		var loot = main.loot_piles[stored.loot_index] if stored.loot_index >= 0 else main._spawn_loot_at(record.pos,1,"ammo")
		if stored.loot_index < 0:
			loot.ammo_amount = 0
			loot.collected = true
			loot.visible = false
		record.id = "%s:body:%d" % [seam.scope,seam.records.size()]
		record.scope_id = seam.scope
		record.death_base_s = record.death_age_s
		record.transition_base_s = record.transition_age_s
		record.last_domain = "command"
		record.last_clock = main._pose_command_clock_s
		if not record.transition.is_empty():
			record.transition.attempt_id = main.battle_log.attempt_id
			record.transition.event_id = "%s:corpse:0:%d" % [seam.scope,record.transition.seq]
		seam.records[record.id] = record
		seam.links[record.id] = weakref(loot)
		for sentry in main.c2.sentries:
			if record.source_group == "sentries" and sentry.label_id == record.source_actor_id:
				seam.actor_links[sentry.get_instance_id()] = record.id

static func _restore_tools(main: Node, state: Dictionary) -> void:
	main._clear_tripwires()
	main._clear_barrels()
	for group in [["wires",WIRE_FIELDS],["barrels",WIRE_FIELDS],["mines",MINE_FIELDS],["grenades",GRENADE_FIELDS],["decoys",DECOY_FIELDS]]:
		for record in state[group[0]]:
			var node: Node2D
			match group[0]:
				"wires": node = main._make_tripwire(record.pos)
				"barrels": node = main._make_barrel(record.pos)
				"mines": node = main.RaidMineScript.new()
				"grenades": node = main.RaidGrenadeScript.new()
				"decoys": node = main.RaidDecoyScript.new()
			main.entities.add_child(node)
			node.global_position = record.pos
			if group[0] == "grenades":
				node.setup(record._origin,record.target,record.fuse,record.radius,record.damage,record.variant)
				node.detonated.connect(main._on_recorded_grenade_boom.bind(node))
			if group[0] == "decoys": node.setup(record.radius,record.life)
			_apply(node,record,group[1])
			node.global_position = record.pos
			if group[0] in ["mines","grenades"] and not record.source.is_empty():
				var owner = main._op_by_id(record.source.owner_id)
				main.visual_snapshot.tool_fx.register(main,node,owner,"mine" if group[0] == "mines" else "grenade")
				var entry: Dictionary = main.visual_snapshot.tool_fx._tools.get(node.get_instance_id(),{})
				if not entry.is_empty(): entry.born.created_pos = record.source.created_pos
			match group[0]:
				"wires": main.tripwires.append(node)
				"barrels": main.barrels.append(node)
				"mines": main.raid_mines.append(node)
				"grenades": main.raid_grenades.append(node)
				"decoys": main.raid_decoys.append(node)
