extends Node3D

const Assets := preload("res://scripts/presentation/asset_library.gd")
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var lamp := OmniLight3D.new()
var environment := Environment.new()
var yaw := 35.0
var pitch := 55.0
var size := 14.0
var focus := Vector3.ZERO
var dragging := false
var _caption: Label
var _roof: Node3D


func _exit_tree() -> void:
	Assets.release_materials()


func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(world)
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	for x in range(-2, 3):
		for z in range(-3, 3):
			var tile := "ground_concrete" if z < 1 else ("ground_asphalt" if x < 1 else "ground_earth")
			place(tile, Vector3(x * 2, 0, z * 2))
	var warehouse := place("warehouse_fragment", Vector3(0,0,-3))
	warehouse.rotation.y = PI
	for mesh in warehouse.get_children():
		if "roof" in mesh.name:
			_roof = mesh
	place("supply_crate", Vector3(-1.7,0,1.3))
	place("supply_crate", Vector3(-2.5,0,2.4)).rotation.y = 0.13
	place("sandbag_stack", Vector3(-3.4,0,1.0)).rotation.y = 0.2
	place("sandbag_stack", Vector3(-3.4,0,1.45)).rotation.y = 0.2
	place("oil_drum", Vector3(1.2,0,1.6))
	place("oil_drum", Vector3(1.75,0,2.1))
	place("supply_crate", Vector3(0,0,2.8))
	place("field_radio", Vector3(0,0.735,2.8)).rotation.y = PI
	place("yard_lamp", Vector3(3.0,0,0.6))
	lamp.position = Vector3(3.0,3.28,0.07)
	lamp.light_color = Color("ffb366")
	lamp.light_energy = 3.5
	lamp.omni_range = 6.0
	add_child(lamp)
	var layer := CanvasLayer.new()
	add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(28, 24)
	_caption.add_theme_font_size_override("font_size", 18)
	layer.add_child(_caption)
	set_lighting(true)
	apply_pose()


func place(id: String, at: Vector3) -> Node3D:
	var node := Assets.instantiate(id)
	add_child(node)
	node.position = at
	return node


func set_lighting(dusk: bool) -> void:
	environment.background_color = Color("151b24") if dusk else Color("393e43")
	environment.ambient_light_color = Color("93accb") if dusk else Color.WHITE
	environment.ambient_light_energy = 0.45 if dusk else 0.6
	sun.light_color = Color("a7bedb") if dusk else Color.WHITE
	sun.light_energy = 0.8 if dusk else 1.0
	lamp.visible = dusk
	_caption.text = "AMBUSH LOOP / ASSET STUDY 01\n%s · 5 props / warehouse / 3 ground materials\nMiddle drag: orbit   Wheel: zoom   L: lighting   R: roof" % ("DUSK" if dusk else "NEUTRAL")


func show_roof(on: bool) -> void:
	if is_instance_valid(_roof):
		_roof.visible = on


func show_lod(lod: int) -> void:
	for old in get_children():
		if not old.has_meta("asset_id"):
			continue
		var node := Assets.instantiate(str(old.get_meta("asset_id")), lod)
		add_child(node)
		node.transform = old.transform
		old.free()
		for mesh in node.get_children():
			if "roof" in mesh.name:
				_roof = mesh


func apply_pose() -> void:
	var y := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	camera.position = focus + Vector3(sin(y)*cos(p),sin(p),cos(y)*cos(p))*35.0
	camera.look_at(focus, Vector3.UP)
	camera.size = size


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			size = clampf(size * (0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 4.0, 24.0)
			apply_pose()
	if event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.35
		apply_pose()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_L:
			set_lighting(not lamp.visible)
		if event.physical_keycode == KEY_R and _roof != null:
			show_roof(not _roof.visible)
