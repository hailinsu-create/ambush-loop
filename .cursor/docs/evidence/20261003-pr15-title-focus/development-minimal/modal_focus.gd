extends RefCounted
## Focusable controls of the current modal, excluding hidden/disabled entries.

static func controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.find_children("*", "Control", true, false):
		var control := child as Control
		if control.focus_mode == Control.FOCUS_NONE or not control.is_visible_in_tree():
			continue
		if control is BaseButton and control.disabled:
			continue
		result.append(control)
	return result


static func loop(node: Node) -> void:
	var entries := controls(node)
	for index in entries.size():
		var previous := entries[(index - 1 + entries.size()) % entries.size()].get_path()
		var next := entries[(index + 1) % entries.size()].get_path()
		entries[index].focus_next = next
		entries[index].focus_previous = previous
		entries[index].focus_neighbor_top = previous
		entries[index].focus_neighbor_bottom = next
		entries[index].focus_neighbor_left = previous
		entries[index].focus_neighbor_right = next


static func ensure(node: Node, preferred: Control = null) -> void:
	var entries := controls(node)
	var focus := node.get_viewport().gui_get_focus_owner()
	if focus in entries:
		return
	if preferred in entries:
		preferred.grab_focus()
	elif not entries.is_empty():
		entries[0].grab_focus()
