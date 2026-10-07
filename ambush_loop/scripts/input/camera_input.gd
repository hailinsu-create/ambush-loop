extends RefCounted

## Track complete touch lifetimes, including releases over UI. A gesture never
## becomes a tactical tap again until every finger has left the screen.
const TAP_SLOP := 14.0
var contacts: Dictionary = {}
var ui_contacts: Dictionary = {}
var pending_id := -1
var press_position := Vector2.ZERO
var tap_cancelled := false
var multi_latched := false
var block_emulated_mouse := false
var middle_down := false
var suppressed_contacts: Dictionary = {}


func cancel(reset_contacts: bool = false) -> void:
	if reset_contacts:
		suppressed_contacts.clear()
	else:
		for id in contacts:
			suppressed_contacts[id] = true
	contacts.clear()
	ui_contacts.clear()
	pending_id = -1
	tap_cancelled = true
	multi_latched = false
	middle_down = false


func touch(event: InputEvent, rig: Node3D, over_ui: bool) -> Dictionary:
	var result := {"handled": false, "tap": false, "position": Vector2.ZERO}
	if not suppressed_contacts.is_empty():
		if event is InputEventScreenTouch:
			if event.pressed:
				suppressed_contacts[event.index] = true
			else:
				suppressed_contacts.erase(event.index)
			result.handled = not over_ui
		elif event is InputEventScreenDrag:
			result.handled = not over_ui
		return result
	if event is InputEventScreenTouch:
		var id: int = event.index
		if event.pressed:
			if contacts.is_empty():
				multi_latched = false
				tap_cancelled = over_ui
				pending_id = -1 if over_ui else id
				press_position = event.position
				block_emulated_mouse = not over_ui
			contacts[id] = event.position
			if over_ui:
				ui_contacts[id] = true
			if contacts.size() > 1:
				multi_latched = true
				tap_cancelled = true
				pending_id = -1
			result.handled = not over_ui
		else:
			if not contacts.has(id):
				return result
			result.handled = not ui_contacts.has(id)
			result.tap = id == pending_id and not tap_cancelled and not multi_latched \
				and not over_ui and not event.canceled \
				and press_position.distance_to(event.position) <= TAP_SLOP
			result.position = event.position
			contacts.erase(id)
			ui_contacts.erase(id)
			if contacts.is_empty():
				pending_id = -1
				multi_latched = false
				tap_cancelled = false
		return result
	if not event is InputEventScreenDrag or not contacts.has(event.index):
		return result
	result.handled = not ui_contacts.has(event.index)
	var previous: Array = contacts.values()
	contacts[event.index] = event.position
	if contacts.size() == 2 and ui_contacts.is_empty():
		var current: Array = contacts.values()
		var old_mid: Vector2 = (previous[0] + previous[1]) * 0.5
		var new_mid: Vector2 = (current[0] + current[1]) * 0.5
		var old_span: Vector2 = previous[1] - previous[0]
		var new_span: Vector2 = current[1] - current[0]
		rig.pan_between(old_mid, new_mid)
		if old_span.length() > 8.0 and new_span.length() > 8.0:
			var anchor: Variant = rig.ground_at(new_mid)
			rig.yaw_deg -= rad_to_deg(old_span.angle_to(new_span))
			rig.apply_pose()
			var moved: Variant = rig.ground_at(new_mid)
			if anchor is Vector3 and moved is Vector3:
				rig.focus += anchor - moved
				rig.apply_pose()
			rig.zoom_at(new_mid, new_span.length() / old_span.length())
	elif event.position.distance_to(press_position) > TAP_SLOP:
		tap_cancelled = true
	return result


func mouse(event: InputEvent, rig: Node3D) -> bool:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				middle_down = event.pressed
				return true
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					rig.zoom_at(event.position, 1.10 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.10)
				return true
	if event is InputEventMouseMotion and middle_down:
		if event.shift_pressed:
			rig.pan_between(event.position - event.relative, event.position)
		else:
			rig.yaw_deg -= event.relative.x * 0.35
			rig.apply_pose()
		return true
	if event is InputEventMagnifyGesture:
		rig.zoom_at(event.position, event.factor)
		return true
	return false
