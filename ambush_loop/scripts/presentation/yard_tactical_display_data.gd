extends RefCounted

## Read-only view data for the yard's 2D and 3D tactical overlays.
## Geometry is always queried from OperatorUnit and AmbushGrid.

const SCHEMA_VERSION := 1
const ROUTE_SAMPLE_SPACING_PX := 16.0


static func state_signature(host: Node) -> String:
	if host == null or not is_instance_valid(host):
		return "no-host"
	var bits := PackedStringArray()
	var level = host.get("level")
	var grid = host.get("grid")
	var selected = host.get("selected")
	bits.append("level=%s" % (str(level.get("level_id")) if level != null else "none"))
	bits.append("phase=%d" % int(host.get("phase")))
	bits.append("tool=%d" % int(host.get("tool")))
	bits.append("door=%s" % str(host.get("door_locked")))
	bits.append("grid=%d" % int(grid.get("tactical_revision")) if grid != null else "grid=-1")
	if selected != null and is_instance_valid(selected):
		bits.append("actor=%d:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			selected.get_instance_id(), str(selected.get("op_id")), str(selected.get("global_position")),
			str(selected.get("facing_deg")), str(selected.get("weapon_id")), str(selected.get("ammo")),
			str(selected.get("stance")), str(selected.get("fire_mode")), str(selected.get("fire_permitted")),
			str(selected.get("alive")), str(selected.get("visible")),
		])
	else:
		bits.append("actor=none")
	var enemies: Array = host.get("enemies")
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		bits.append("target=%s:%s:%s:%s:%s" % [
			str(enemy.get("label_id")), str(enemy.get("global_position")), str(enemy.get("alive")),
			str(enemy.get("active")), str(enemy.get("hp")),
		])
	var intent: Dictionary = host.get("_touch_intent")
	if intent.is_empty():
		bits.append("intent=none")
	else:
		var slot = intent.get("slot")
		var slot_id: int = -1
		if slot is Node and is_instance_valid(slot):
			slot_id = slot.get_instance_id()
		bits.append("intent=%s:%s:%s:%s:%s:%s:%d" % [
			str(intent.get("kind", "")), str(intent.get("actor_instance_id", -1)),
			str(intent.get("tool", -1)), str(intent.get("world", Vector2.ZERO)),
			str(intent.get("cells", [])), str(intent.get("sprint", false)), slot_id,
		])
	return "|".join(bits)


static func build(host: Node, signature: String) -> Dictionary:
	var data := {
		"schema": SCHEMA_VERSION,
		"state_signature": signature,
		"available": false,
		"phase": "setup" if host != null and int(host.get("phase")) == 0 else "inactive",
		"actor": {},
		"nominal_sector": {},
		"route_samples": [],
		"route_summary": [],
		"coverage_points": PackedVector2Array(),
		"target_states": [],
		"movement_preview": {},
	}
	if host == null or not is_instance_valid(host):
		return data
	var level = host.get("level")
	var grid = host.get("grid")
	var op = host.get("selected")
	if level == null or str(level.get("level_id")) != "yard" or int(host.get("phase")) != 0:
		return data
	if grid == null or op == null or not is_instance_valid(op):
		return data
	data["available"] = true
	var actor_position: Vector2 = op.get("global_position")
	var actor := {
		"id": int(op.get("op_id")),
		"instance_id": op.get_instance_id(),
		"name": str(op.get("display_name")),
		"position": actor_position,
		"facing_deg": float(op.get("facing_deg")),
		"weapon_id": str(op.get("weapon_id")),
		"ammo": int(op.get("ammo")),
		"melee": bool(op.get("melee")),
		"range_px": float(op.get("range_px")),
		"half_angle_deg": float(op.get("half_angle_deg")),
		"stance": int(op.get("stance")),
		"fire_mode": int(op.get("fire_mode")),
		"fire_permitted": bool(op.get("fire_permitted")),
		"alive": bool(op.get("alive")),
		"visible": bool(op.get("visible")),
		"moving": bool(op.call("is_moving")) if op.has_method("is_moving") else false,
	}
	data["actor"] = actor
	data["nominal_sector"] = {
		"origin": actor_position,
		"facing_deg": actor["facing_deg"],
		"range_px": actor["range_px"],
		"half_angle_deg": actor["half_angle_deg"],
		"geometry_only": true,
		"authority": "OperatorUnit.in_fire_geometry",
	}
	data["movement_preview"] = _movement_preview(host, op, grid)
	if not bool(actor["alive"]) or not bool(actor["visible"]) or bool(actor["melee"]):
		return data

	var active_routes: Array = host.call("_active_routes")
	var coverage_points := PackedVector2Array()
	var seen: Dictionary = {}
	var route_samples: Array[Dictionary] = []
	var route_summary: Array[Dictionary] = []
	for route_index in active_routes.size():
		var raw_route: Variant = active_routes[route_index]
		if not raw_route is PackedVector2Array:
			continue
		var route: PackedVector2Array = raw_route
		var route_id := _route_id(route_index)
		var hits := 0
		var total := 0
		for point in _sample_polyline(route, ROUTE_SAMPLE_SPACING_PX):
			var geometry_clear := bool(op.call("in_fire_geometry", point, grid))
			route_samples.append({
				"route_id": route_id,
				"position": point,
				"geometry_clear": geometry_clear,
				"query": "OperatorUnit.in_fire_geometry",
			})
			total += 1
			if not geometry_clear:
				continue
			hits += 1
			if not seen.has(point):
				seen[point] = true
				coverage_points.append(point)
		route_summary.append({"route_id": route_id, "covered_samples": hits, "total_samples": total})
	data["route_samples"] = route_samples
	data["route_summary"] = route_summary
	data["coverage_points"] = coverage_points
	data["target_states"] = _target_states(host, op, grid)
	return data


static func _movement_preview(host: Node, op: Object, grid: Object) -> Dictionary:
	var intent: Dictionary = host.get("_touch_intent")
	if intent.is_empty() or int(intent.get("actor_instance_id", -1)) != op.get_instance_id():
		return {}
	if int(intent.get("tool", -1)) != int(host.get("tool")):
		return {}
	var kind := str(intent.get("kind", "move"))
	var target: Vector2 = intent.get("world", op.get("global_position"))
	var slot = intent.get("slot")
	if kind == "cover" and slot is Node2D and is_instance_valid(slot):
		target = slot.global_position
	var cell: Vector2i = grid.call("world_to_cell", target)
	var cells: Array = intent.get("cells", []).duplicate(true)
	return {
		"valid": true,
		"kind": kind,
		"actor_id": int(op.get("op_id")),
		"actor_instance_id": op.get_instance_id(),
		"target_id": "%s:%d:%d" % [kind, cell.x, cell.y],
		"position": target,
		"cells": cells,
		"sprint": bool(intent.get("sprint", false)),
		"tool": int(intent.get("tool", -1)),
	}


static func _target_states(host: Node, op: Object, grid: Object) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var enemies: Array = host.get("enemies")
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or not bool(enemy.get("alive")) or not bool(enemy.get("active")):
			continue
		var target: Vector2 = enemy.get("global_position")
		var geometry_clear := bool(op.call("in_fire_geometry", target, grid))
		var reason := str(op.call("engage_block_reason", target, grid))
		out.append({
			"id": int(enemy.get("label_id")),
			"position": target,
			"geometry_clear": geometry_clear,
			"geometry_query": "OperatorUnit.in_fire_geometry",
			"fire_ready": reason.is_empty(),
			"block_reason": reason,
		})
	return out


static func _route_id(index: int) -> String:
	match index:
		0:
			return "main"
		1:
			return "flank"
		_:
			return "route_%d" % index


static func _sample_polyline(points: PackedVector2Array, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	if points.size() == 1:
		out.append(points[0])
		return out
	for index in range(points.size() - 1):
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var distance := a.distance_to(b)
		var steps := maxi(1, int(ceil(distance / spacing)))
		for step in steps:
			out.append(a.lerp(b, float(step) / float(steps)))
		if index == points.size() - 2:
			out.append(b)
	return out
