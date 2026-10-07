extends Node

const Layout := preload("res://scripts/ui/touch_intent_layout.gd")
const Commands := preload("res://scripts/input/command_router.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Picker := preload("res://scripts/presentation/world_picker_3d.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const Pathfinder := preload("res://scripts/raid/pathfinder.gd")

var view: Node
var pending: Dictionary = {}
var panel: HBoxContainer
var confirm_button: Button
var cancel_button: Button
var marker: MeshInstance3D
var path_preview: MeshInstance3D
var face_handle: Button
var face_contact := -1


func bind(presenter: Node) -> void:
	view = presenter
	var layer := CanvasLayer.new()
	layer.layer = 51
	add_child(layer)
	panel = HBoxContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(panel)
	face_handle = Button.new()
	face_handle.text = "射向"
	face_handle.size = Vector2(56, 48)
	face_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(face_handle)
	confirm_button = Button.new()
	confirm_button.custom_minimum_size = Vector2(112, 48)
	panel.add_child(confirm_button)
	cancel_button = Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(72, 48)
	panel.add_child(cancel_button)
	confirm_button.pressed.connect(confirm)
	cancel_button.pressed.connect(cancel)
	var material := Geometry.material(Color(1.0, 0.8, 0.25, 0.85), true)
	material.no_depth_test = true
	marker = Geometry.ring(view.proxies, 0.58, 0.065, Vector3.ZERO, material)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	path_preview = MeshInstance3D.new()
	path_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	path_preview.material_override = material
	view.proxies.add_child(path_preview)
	cancel()


func scope() -> Array:
	var host: Node = view.host
	var actor_id := 0
	if is_instance_valid(host.selected):
		actor_id = host.selected.get_instance_id()
	return [view.frame.get("run_id"), view.frame.get("attempt_id"),
		view.frame.get("level_id"), host.phase, actor_id, host.tool]


func stage(pick: Dictionary) -> bool:
	cancel()
	var host: Node = view.host
	if not host._is_command_phase() or host._modal_blocks_input():
		return false
	if not bool(pick.get("valid", false)) or not Space.contains_logic(pick.get("pos", Vector2.INF)):
		return false
	if pick.get("kind") == "op":
		return Commands.dispatch(host, "primary", pick)
	if not is_instance_valid(host.selected) or not host.selected.visible or not host.selected.alive or host.selected.locked:
		return false
	pending = {"pick": pick.duplicate(true), "scope": scope(), "command": "primary"}
	confirm_button.text = "确认占位" if pick.get("kind") == "covers" else "确认指令"
	match host.tool:
		host.Tool.TRIPWIRE: confirm_button.text = "确认布雷"
		host.Tool.GRENADE: confirm_button.text = "确认投掷"
		host.Tool.DECOY: confirm_button.text = "确认诱饵"
	if host.tool == host.Tool.DEPLOY and pick.get("kind") in ["ground", "stashes", "loot"]:
		var cells := Pathfinder.find_path(host.grid, host.selected.grid_cell(), host.grid.world_to_cell(pick.pos))
		if cells.is_empty():
			cancel()
			return false
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		var previous: Vector2 = host.selected.global_position
		for cell in cells:
			var next: Vector2 = host.grid.cell_to_world_center(cell)
			mesh.surface_add_vertex(Space.logic_to_surface(view.frame, previous, 0.09))
			mesh.surface_add_vertex(Space.logic_to_surface(view.frame, next, 0.09))
			previous = next
		mesh.surface_end()
		path_preview.mesh = mesh
		path_preview.show()
		confirm_button.text = "确认移动"
	marker.position = Space.logic_to_surface(view.frame, pick.pos, 0.08)
	marker.visible = true
	panel.show()
	position_panel()
	return true


func confirm() -> void:
	# Resolve against a fresh authoritative frame, not a previous render tick.
	view.refresh()
	if pending.is_empty():
		return
	var host: Node = view.host
	if pending.scope != scope() or host._modal_blocks_input() or not host._is_command_phase():
		cancel()
		return
	if not is_instance_valid(host.selected) or not host.selected.visible or not host.selected.alive or host.selected.locked:
		cancel()
		return
	var pick: Dictionary = pending.pick.duplicate(true)
	if pick.get("kind", "ground") != "ground":
		var found := false
		for item in view.frame.get(pick.kind, []):
			if item.get("id") == pick.get("id") and item.get("pos") == pick.pos and bool(item.get("active", true)) and bool(item.get("alive", true)):
				found = true
				break
		if not found:
			cancel()
			return
	# Clear before dispatch: double activation can never execute a second command.
	var command := str(pending.get("command", "primary"))
	cancel()
	Commands.dispatch(host, command, pick)


func cancel() -> void:
	if face_contact >= 0 and is_instance_valid(view):
		view.gestures.suppressed_contacts[face_contact] = true
	face_contact = -1
	pending.clear()
	if is_instance_valid(panel):
		panel.hide()
	if is_instance_valid(marker):
		marker.hide()
	if is_instance_valid(path_preview):
		path_preview.hide()
		path_preview.mesh = null


func _process(_delta: float) -> void:
	update_handle()
	if pending.is_empty():
		return
	if pending.scope != scope() or view.host._modal_blocks_input():
		cancel()
		return
	position_panel()


func update_handle() -> void:
	var host: Node = view.host
	face_handle.visible = host._want_touch() and host._is_command_phase() and not host._modal_blocks_input() \
		and is_instance_valid(host.selected) and host.selected.visible and host.selected.alive and not host.selected.locked \
		and host.tool == host.Tool.DEPLOY and (pending.is_empty() or pending.get("command") == "face")
	if not face_handle.visible or face_contact >= 0:
		return
	var direction := Vector2.from_angle(deg_to_rad(host.selected.facing_deg))
	var face_pos: Vector2 = host.selected.global_position + direction * 64.0
	var screen: Vector2 = view.rig.project_logic(face_pos, Space.height_at(view.frame, face_pos))
	var bounds := get_viewport().get_visible_rect().size
	face_handle.position = Vector2(clampf(screen.x - 28, 8, maxf(8, bounds.x - 64)),
		clampf(screen.y - 24, 90, maxf(90, bounds.y - 196)))
	# If another UI owns this location, leave direction adjustment to the rail.
	face_handle.visible = not panel.visible or not panel.get_global_rect().intersects(face_handle.get_global_rect())


func consume_face_touch(event: InputEvent) -> bool:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return false
	if not view.gestures.suppressed_contacts.is_empty():
		return false
	if event is InputEventScreenTouch and event.pressed:
		if face_contact >= 0:
			view.gestures.suppressed_contacts[event.index] = true
			cancel()
			return true
		if not face_handle.visible or not face_handle.get_global_rect().has_point(event.position):
			return false
		if not view.gestures.contacts.is_empty():
			return false
		cancel()
		face_contact = event.index
		view.gestures.block_emulated_mouse = true
		stage_face(event.position)
		return true
	if face_contact < 0 or event.index != face_contact:
		return false
	if event is InputEventScreenDrag:
		stage_face(event.position)
		return true
	face_contact = -1
	if event.canceled:
		cancel()
	else:
		stage_face(event.position)
	return true


func stage_face(screen: Vector2) -> void:
	# Direction is measured on the selected actor's plane, not a foreground roof.
	var camera: Camera3D = view.rig.camera
	var plane := Plane(Vector3.UP, Space.height_at(view.frame, view.host.selected.global_position))
	var ground: Variant = plane.intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if not ground is Vector3:
		return
	var target := Space.world_to_logic(ground)
	var origin: Vector2 = view.host.selected.global_position
	if not Space.contains_logic(target) or origin.distance_squared_to(target) < 1.0:
		return
	pending = {"pick": {"valid": true, "pos": target, "kind": "ground"},
		"scope": scope(), "command": "face"}
	confirm_button.text = "确认射向"
	marker.position = Space.logic_to_surface(view.frame, target, 0.08)
	marker.show()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Space.logic_to_surface(view.frame, origin, 0.09))
	mesh.surface_add_vertex(Space.logic_to_surface(view.frame, target, 0.09))
	mesh.surface_end()
	path_preview.mesh = mesh
	path_preview.show()
	panel.show()
	position_panel()


func position_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var obstacles: Array = []
	if view._camera_panel.visible:
		obstacles.append(view._camera_panel.get_global_rect())
	# Resident north HUD and bottom command rail must stay accessible.
	obstacles.append(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 84)))
	obstacles.append(Rect2(Vector2(0, maxf(0, viewport_size.y - 140)), Vector2(viewport_size.x, 140)))
	var placement := Layout.choose_position(view.rig.project_logic(pending.pick.pos, Space.height_at(view.frame, pending.pick.pos)),
		viewport_size, Vector2(188, 48), Vector4(8, 8, 8, 8), obstacles)
	panel.position = placement.position
