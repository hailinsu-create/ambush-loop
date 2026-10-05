extends Node3D

## M2-I0: read-only 3D presentation adapter for the authoritative yard grid.
## Source assets and coordinate convention are pinned in art/environment_v2/M2_I0_SOURCE.md.
const Adapter := preload("res://scripts/m2_i0_yard_adapter.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const GridScript := preload("res://scripts/grid.gd")
const GROUND_MODEL := "res://art/environment_v2/models/env_ground_concrete_2m_lod0.glb"
const SHELL_MODEL := "res://art/environment_v2/models/env_warehouse_shell_lod0.glb"
const CRATE_MODEL := "res://art/environment_v2/models/env_yard_crate_lod0.glb"
const AMMO_MODEL := "res://art/environment_v2/models/env_ammo_can_lod0.glb"
const ATLAS_MATERIAL := "res://art/environment_v2/materials/environment_v2_atlas.tres"
const GROUND_CELL := Vector2i(15, 13)
const PLATFORM_CELL := Vector2i(15, 12)

var host: Node
var active := false
var camera: Camera3D
var _world: Node3D
var _controls: CanvasLayer
var _toggle: Button
var _atlas: StandardMaterial3D
var _actor_nodes: Dictionary = {}
var _stash_nodes: Dictionary = {}
var _decor_targets: Array[Dictionary] = []
var _intent_preview: Node3D
var _intent_signature := ""
var _bound := false


func _ready() -> void:
	call_deferred("_bind_parent")


func _bind_parent() -> void:
	if get_parent() != null and get_parent().has_method("_load_level"):
		bind(get_parent())


func bind(game: Node) -> void:
	if _bound or game == null:
		return
	_bound = true
	host = game
	if host.level == null or str(host.level.level_id) != "yard":
		print("M2_I0_PREVIEW_DISABLED reason=yard_only")
		return
	_atlas = load(ATLAS_MATERIAL) as StandardMaterial3D
	_build_world()
	_build_controls()
	_set_active(true)
	print("M2_I0_YARD_3D_READY source=eb50a736da09038bda49d96a3e15c33389a83317 height=grid.gd picking=read_only")


func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "I0World"
	add_child(_world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("17212a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9bbca")
	env.ambient_light_energy = 0.8
	environment.environment = env
	_world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56.0, -32.0, 0.0)
	sun.light_color = Color("d2d9d7")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	_world.add_child(sun)
	camera = Camera3D.new()
	camera.name = "I0Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29.0
	camera.position = Vector3(0.0, 24.0, 26.0)
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	_build_ground()
	_build_grid_geometry()
	_build_platform_and_ramp()
	_build_landmarks()
	_sync_actors()
	_sync_stashes()


func _build_ground() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "GroundFallback"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 22.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("555954")
	floor_mat.roughness = 0.94
	plane.material = floor_mat
	floor.mesh = plane
	floor.position.y = -0.08
	_world.add_child(floor)
	var packed := load(GROUND_MODEL) as PackedScene
	if packed == null:
		push_warning("M2_I0_GROUND_ASSET_UNAVAILABLE; using flat fallback")
		return
	var instance := packed.instantiate()
	var source_mesh := _find_mesh(instance)
	if source_mesh == null or source_mesh.mesh == null:
		instance.free()
		push_warning("M2_I0_GROUND_MESH_UNAVAILABLE; using flat fallback")
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = source_mesh.mesh
	multi.instance_count = 20 * 11
	var i := 0
	for z in 11:
		for x in 20:
			var at := Vector3(float(x * 2 - 19), -0.035, float(z * 2 - 10))
			multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, at) * source_mesh.transform)
			i += 1
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "CollaboratorConcreteTiles"
	tiles.multimesh = multi
	if _atlas != null:
		tiles.material_override = _atlas
	_world.add_child(tiles)
	instance.free()


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh != null:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null


func _build_grid_geometry() -> void:
	var blocker_mesh := BoxMesh.new()
	blocker_mesh.size = Vector3.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blocker_mesh
	var specs: Array[Transform3D] = []
	for y in GridScript.ROWS:
		for x in GridScript.COLS:
			if not host.grid.is_blocked(x, y):
				continue
			var border := x == 0 or x == GridScript.COLS - 1 or y == 0 or y == GridScript.ROWS - 1
			var height := 2.2 if border else 0.52
			var center := Space.logic_to_world(Vector2((x + 0.5) * 32.0, (y + 0.5) * 32.0))
			var scale := Vector3(0.96, height, 0.96)
			specs.append(Transform3D(Basis.from_scale(scale), center + Vector3(0.0, height * 0.5, 0.0)))
	mm.instance_count = specs.size()
	for index in specs.size():
		mm.set_instance_transform(index, specs[index])
	var blockers := MultiMeshInstance3D.new()
	blockers.name = "LogicBlockedCellsReadOnly"
	blockers.multimesh = mm
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("41464a")
	wall_mat.roughness = 0.9
	blockers.material_override = wall_mat
	_world.add_child(blockers)
	_decor_targets.clear()
	for y in GridScript.ROWS:
		for x in GridScript.COLS:
			if not host.grid.is_blocked(x, y):
				continue
			var border := x == 0 or x == GridScript.COLS - 1 or y == 0 or y == GridScript.ROWS - 1
			var height := 2.2 if border else 0.52
			var center := Space.logic_to_world(Vector2((x + 0.5) * 32.0, (y + 0.5) * 32.0))
			_decor_targets.append({
				"valid": true, "actionable": false, "kind": "decoration",
				"id": "blocked:%d:%d" % [x, y], "cell": Vector2i(x, y),
				"bounds": AABB(center + Vector3(-0.5, 0.0, -0.5), Vector3(1.0, height, 1.0)),
			})


func _build_platform_and_ramp() -> void:
	var slab := MeshInstance3D.new()
	slab.name = "Authoritative3x3Platform"
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(3.0, 0.18, 3.0)
	slab.mesh = slab_mesh
	var slab_mat := StandardMaterial3D.new()
	slab_mat.albedo_color = Color("756e5f")
	slab_mat.roughness = 0.86
	slab.material_override = slab_mat
	var center := Space.logic_to_world(Vector2(16.5 * 32.0, 11.5 * 32.0))
	slab.position = center + Vector3(0.0, Adapter.HEIGHT_METRES - 0.09, 0.0)
	_world.add_child(slab)
	var ramp := MeshInstance3D.new()
	ramp.name = "OnlyAuthoredSouthRamp"
	ramp.mesh = _ramp_mesh()
	var ramp_mat := StandardMaterial3D.new()
	ramp_mat.albedo_color = Color("817b70")
	ramp_mat.roughness = 0.9
	ramp.material_override = ramp_mat
	_world.add_child(ramp)


func _ramp_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var west_ground := Vector3(-5.0, 0.0, 3.0)
	var east_ground := Vector3(-4.0, 0.0, 3.0)
	var west_top := Vector3(-5.0, Adapter.HEIGHT_METRES, 2.0)
	var east_top := Vector3(-4.0, Adapter.HEIGHT_METRES, 2.0)
	for vertex in [west_ground, east_ground, west_top, east_ground, east_top, west_top]:
		st.add_vertex(vertex)
	st.generate_normals()
	return st.commit(mesh)


func _build_landmarks() -> void:
	var shell := _place_model(SHELL_MODEL, Vector3(0.5, 0.0, 0.0), Vector3(0.76, 0.78, 0.9), "CollaboratorWarehouseShell")
	if shell == null:
		var building := _box("WarehouseShellFallback", Vector3(4.8, 2.2, 3.8), Vector3(0.5, 1.1, 0.0), Color("605b50"))
		_world.add_child(building)
	for cell in [Vector2i(9, 9), Vector2i(28, 9), Vector2i(18, 15)]:
		var logic := Vector2(cell) * 32.0 + Vector2.ONE * 16.0
		var anchor := Adapter.world_anchor(host.grid, logic)
		var crate := _place_model(CRATE_MODEL, anchor + Vector3(0.0, 0.06, 0.0), Vector3(0.68, 0.58, 0.68), "CollaboratorYardCrate")
		if crate == null:
			_world.add_child(_box("CrateFallback", Vector3(0.68, 0.58, 0.68), anchor + Vector3(0.0, 0.29, 0.0), Color("775b3e")))


func _place_model(path: String, at: Vector3, scale: Vector3, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("M2_I0_ASSET_UNAVAILABLE " + path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		return null
	node.name = node_name
	node.position = at
	node.scale = scale
	_apply_atlas(node)
	_world.add_child(node)
	return node


func _apply_atlas(node: Node) -> void:
	if _atlas != null and node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			node.set_surface_override_material(surface, _atlas)
	for child in node.get_children():
		_apply_atlas(child)


func _box(node_name: String, dimensions: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var box := BoxMesh.new()
	box.size = dimensions
	node.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	node.material_override = material
	node.position = at
	return node


func _build_controls() -> void:
	_controls = CanvasLayer.new()
	_controls.name = "I0Controls"
	_controls.layer = 60
	add_child(_controls)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.add_child(root)
	_toggle = Button.new()
	_toggle.text = "返回 2D 院子"
	_toggle.custom_minimum_size = Vector2(156.0, 48.0)
	_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toggle.offset_left = -396.0
	_toggle.offset_right = -240.0
	_toggle.offset_top = 16.0
	_toggle.offset_bottom = 64.0
	root.add_child(_toggle)
	_toggle.pressed.connect(func() -> void: _set_active(not active))


func _set_active(value: bool) -> void:
	active = value and host != null and host.level != null and str(host.level.level_id) == "yard"
	if camera != null:
		camera.current = active
	if host != null:
		var legacy_world := host.get_node_or_null("World") as Node2D
		if legacy_world != null:
			legacy_world.visible = not active
	if _toggle != null:
		_toggle.text = "返回 2D 院子" if active else "查看 3D 院子"


func pick_at(screen: Vector2) -> Dictionary:
	if not active or host == null:
		return {}
	return Adapter.pick(camera, screen, host.grid, _pick_targets())


func screen_to_logic(screen: Vector2) -> Vector2:
	var candidate := pick_at(screen)
	if candidate.is_empty():
		return Vector2.INF
	return candidate.get("pos", Vector2.INF)


func _pick_targets() -> Array:
	var targets := _decor_targets.duplicate()
	for op in host.operators:
		if op == null or not is_instance_valid(op) or not op.visible or not op.alive:
			continue
		var logic: Vector2 = op.global_position
		var anchor := Adapter.world_anchor(host.grid, logic)
		var cell: Vector2i = op.grid_cell()
		targets.append({
			"valid": true, "actionable": true, "kind": "operator", "id": int(op.op_id),
			"cell": cell, "tier": int(host.grid.get_elevation_tier(cell.x, cell.y)), "pos": logic,
			"bounds": AABB(anchor + Vector3(-0.34, 0.0, -0.34), Vector3(0.68, 1.45, 0.68)),
		})
	for stash in host.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var logic: Vector2 = stash.global_position
		var anchor := Adapter.world_anchor(host.grid, logic, 0.02)
		targets.append({
			"valid": true, "actionable": true, "kind": "stash", "id": str(stash.get_instance_id()),
			"cell": stash.cell, "tier": int(host.grid.get_elevation_tier(stash.cell.x, stash.cell.y)), "pos": logic,
			"bounds": AABB(anchor + Vector3(-0.34, 0.0, -0.34), Vector3(0.68, 0.72, 0.68)),
		})
	return targets


func _sync_actors() -> void:
	if host == null or _world == null:
		return
	var seen: Dictionary = {}
	for op in host.operators:
		if op == null or not is_instance_valid(op):
			continue
		var key := str(op.op_id)
		seen[key] = true
		if not _actor_nodes.has(key):
			var body := MeshInstance3D.new()
			body.name = "Operator_%s" % key
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.22
			capsule.height = 1.22
			body.mesh = capsule
			var material := StandardMaterial3D.new()
			material.albedo_color = [Color("86936e"), Color("65776f"), Color("738391")][clampi(int(op.role), 0, 2)]
			material.roughness = 0.86
			body.material_override = material
			_world.add_child(body)
			_actor_nodes[key] = body
		var visual: MeshInstance3D = _actor_nodes[key]
		visual.visible = op.visible and op.alive
		var anchor := Adapter.world_anchor(host.grid, op.global_position)
		visual.position = anchor + Vector3(0.0, 0.68, 0.0)
		visual.rotation.y = Space.facing_yaw(float(op.facing_deg))
	for key in _actor_nodes.keys():
		if not seen.has(key):
			_actor_nodes[key].queue_free()
			_actor_nodes.erase(key)


func _sync_stashes() -> void:
	if host == null or _world == null:
		return
	var seen: Dictionary = {}
	for stash in host.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var key := str(stash.get_instance_id())
		seen[key] = true
		if not _stash_nodes.has(key):
			var node := _place_model(AMMO_MODEL, Vector3.ZERO, Vector3(0.55, 0.55, 0.55), "Supply_%s" % key)
			if node == null:
				node = _box("SupplyFallback", Vector3(0.42, 0.48, 0.42), Vector3.ZERO, Color("a27d49"))
				_world.add_child(node)
			_stash_nodes[key] = node
		var logic: Vector2 = stash.global_position
		var anchor := Adapter.world_anchor(host.grid, logic)
		_stash_nodes[key].position = anchor + Vector3(0.0, 0.05, 0.0)
	for key in _stash_nodes.keys():
		if not seen.has(key):
			_stash_nodes[key].queue_free()
		_stash_nodes.erase(key)


func _sync_intent_preview() -> void:
	if host == null or _world == null:
		return
	var intent: Variant = host.get("_touch_intent")
	if not intent is Dictionary or intent.is_empty():
		_clear_intent_preview()
		return
	var kind := str(intent.get("kind", "move"))
	var target: Vector2 = intent.get("world", Vector2.ZERO)
	if kind == "cover":
		var slot := intent.get("slot") as Node2D
		if slot != null and is_instance_valid(slot):
			target = slot.global_position
	var cells: Array = intent.get("cells", [])
	var signature := "%s|%.2f|%.2f|%s" % [kind, target.x, target.y, str(cells)]
	if signature == _intent_signature and _intent_preview != null and is_instance_valid(_intent_preview):
		return
	_clear_intent_preview()
	_intent_signature = signature
	_intent_preview = Node3D.new()
	_intent_preview.name = "I0TouchIntentPreview"
	_world.add_child(_intent_preview)
	var color := Color("9bdc75")
	if kind in ["tripwire", "grenade", "decoy"]:
		color = Color("ffc35b")
	elif kind == "context":
		color = Color("70d8ff")
	if kind == "move" and host.selected != null and is_instance_valid(host.selected):
		var previous: Vector2 = host.selected.global_position
		for cell in cells:
			var next: Vector2 = host.grid.cell_to_world_center(cell)
			_add_intent_segment(previous, next, color)
			previous = next
		if not cells.is_empty():
			target = previous
	var anchor := Adapter.world_anchor(host.grid, target, 0.04)
	if not anchor.is_finite():
		_clear_intent_preview()
		return
	var ring_node := MeshInstance3D.new()
	ring_node.name = "IntentTargetRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.44
	ring_mesh.outer_radius = 0.54
	ring_node.mesh = ring_mesh
	ring_node.position = anchor + Vector3(0.0, 0.035, 0.0)
	ring_node.rotation.x = PI * 0.5
	ring_node.material_override = _intent_material(color)
	_intent_preview.add_child(ring_node)
	var marker := MeshInstance3D.new()
	marker.name = "IntentTargetMarker"
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.22
	marker_mesh.height = 0.44
	marker.mesh = marker_mesh
	marker.position = anchor + Vector3(0.0, 0.28, 0.0)
	marker.material_override = _intent_material(color)
	_intent_preview.add_child(marker)


func _add_intent_segment(from_logic: Vector2, to_logic: Vector2, color: Color) -> void:
	var from_world := Adapter.world_anchor(host.grid, from_logic, 0.08)
	var to_world := Adapter.world_anchor(host.grid, to_logic, 0.08)
	var delta := to_world - from_world
	if not from_world.is_finite() or not to_world.is_finite() or delta.length() < 0.02:
		return
	var segment := MeshInstance3D.new()
	segment.name = "IntentPathSegment"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.025
	mesh.height = delta.length()
	segment.mesh = mesh
	segment.position = (from_world + to_world) * 0.5
	segment.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
	segment.material_override = _intent_material(color)
	_intent_preview.add_child(segment)


func _intent_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


func _clear_intent_preview() -> void:
	if _intent_preview != null and is_instance_valid(_intent_preview):
		_intent_preview.queue_free()
	_intent_preview = null
	_intent_signature = ""


func _process(_delta: float) -> void:
	if not _bound or host == null or not is_instance_valid(host) or host.level == null or str(host.level.level_id) != "yard":
		return
	_sync_actors()
	_sync_stashes()
	_sync_intent_preview()


func _exit_tree() -> void:
	if host != null and is_instance_valid(host):
		var legacy_world := host.get_node_or_null("World") as Node2D
		if legacy_world != null:
			legacy_world.visible = true
