extends RefCounted

const Space := preload("res://scripts/presentation/world_space.gd")

## All 3D pointer commands reuse the original gameplay operations and phase gates.
static func dispatch(host: Node, command: String, pick: Dictionary) -> bool:
	if not host._is_command_phase() or host._modal_blocks_input():
		return false
	if not bool(pick.get("valid", false)):
		return false
	var pos: Vector2 = pick.get("pos", Vector2.INF)
	if not Space.contains_logic(pos):
		return false
	match command:
		"primary":
			if str(pick.get("kind", "")) == "op":
				for i in host.operators.size():
					var op = host.operators[i]
					if op.op_id == int(pick.get("id", -1)) and op.visible and op.alive:
						host._select_op(i)
						return true
				return false
			host._handle_setup_click(pos)
			return true
		"face":
			var op = host.selected
			if op == null or not op.visible or not op.alive or op.locked:
				return false
			var direction: Vector2 = pos - op.global_position
			if direction.length_squared() < 0.001:
				return false
			op.set_facing(rad_to_deg(direction.angle()))
			host._announce_plan_edit()
			host._refresh_killzone_preview()
			return true
	return false
