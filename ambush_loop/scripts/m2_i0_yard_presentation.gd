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
var _enemy_nodes: Dictionary = {}
var _fx_nodes: Array[MeshInstance3D] = []
var landmark_nodes: Dictionary = {}
var _tactical_sector: MeshInstance3D
var _tactical_coverage: MultiMeshInstance3D
var _tactical_panel: PanelContainer
var _tactical_info: Label
var _tactical_signature: String = ""
const FX_CAP := 16
const TACTICAL_SAMPLE_CAP := 192


func _ready() -> void:
	call_deferred("_bind_parent")


func _bind_parent() -> void:
	if get_parent() != null and get_parent().has_method("_load_level"):
		bind(get_parent())


func bind(game: Node) -> void:
	if _bound or game == null:
		return
	host = game
	if host.level == null or str(host.level.level_id) != "yard":
		print("M2_I0_PREVIEW_DISABLED reason=yard_only")
		return
	_bound = true
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
	_build_tactical_landmarks()
	_build_tactical_display_nodes()
	_build_fx_pool()
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
	_build_tactical_info_panel(root)


func _build_tactical_info_panel(parent: Control) -> void:
	_tactical_panel = PanelContainer.new()
	_tactical_panel.name = "SelectedTacticalInfoPanel"
	_tactical_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tactical_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tactical_panel.offset_left = -396.0
	_tactical_panel.offset_right = -16.0
	_tactical_panel.offset_top = 72.0
	_tactical_panel.offset_bottom = 230.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("101a20", 0.96)
	panel_style.border_color = Color("48c9ba", 0.92)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_bottom = 10.0
	_tactical_panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(_tactical_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	_tactical_panel.add_child(column)
	var heading := Label.new()
	heading.text = "战术信息 · 当前队员"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("8ce3d7"))
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(heading)
	_tactical_info = Label.new()
	_tactical_info.name = "SelectedTacticalInfo"
	_tactical_info.add_theme_font_size_override("font_size", 16)
	_tactical_info.add_theme_color_override("font_color", Color("e4eee9"))
	_tactical_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tactical_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_tactical_info)
	_tactical_panel.visible = false


func _set_active(value: bool) -> void:
	active = value and host != null and host.level != null and str(host.level.level_id) == "yard"
	if camera != null:
		camera.current = active
	if _world != null:
		_world.visible = active
	if host != null:
		var legacy_world := host.get_node_or_null("World") as Node2D
		if legacy_world != null:
			legacy_world.visible = not active
	if _toggle != null:
		_toggle.text = "返回 2D 院子" if active else "查看 3D 院子"


func pick_at(screen: Vector2) -> Dictionary:
	if not active or host == null or host.phase == host.Phase.REPLAY:
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
			body.add_child(_box("FacingCue", Vector3(0.09, 0.09, 0.35), Vector3(0, 0.25, -0.30), Color("dfd7ac")))
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
	if host == null or not is_instance_valid(host) or host.level == null:
		return
	if str(host.level.level_id) != "yard":
		if active: _set_active(false)
		if _controls != null: _controls.visible = false
		return
	if not _bound: bind(host)
	if _controls != null: _controls.visible = not host._result_overlay_active()
	sync_presentation()


func sync_presentation() -> void:
	if host == null or _world == null: return
	var display_tick: int = host.replay.scrub_tick if host.phase == host.Phase.REPLAY else host.sim.tick
	if host.phase == host.Phase.REPLAY:
		_sync_recorded(host.replay.snapshot_at_or_before(display_tick).get("data", {}))
		for node in _stash_nodes.values(): node.visible = false
		_clear_intent_preview()
		_clear_tactical_display()
	else:
		_sync_actors()
		_sync_enemies()
		_sync_stashes()
		for node in _stash_nodes.values(): node.visible = true
		_sync_intent_preview()
		_sync_tactical_display()
	_sync_event_fx(display_tick)
	if landmark_nodes.has("permission"):
		landmark_nodes["permission"].text = "手动许可 · 入区不自动开火" if host.yard_manual_permission else "自动许可 · 入区后待伏开火"


func tactical_display_snapshot() -> Dictionary:
	## 3D reads the same cached, authoritative query as the 2D yard overlay.
	if host == null or not is_instance_valid(host) or not host.has_method("yard_tactical_display_data"):
		return {}
	return host.call("yard_tactical_display_data")


func _sync_tactical_display() -> void:
	var signature := ""
	if host != null and is_instance_valid(host) and host.has_method("yard_tactical_display_signature"):
		signature = str(host.call("yard_tactical_display_signature"))
	else:
		signature = str(tactical_display_snapshot().get("state_signature", ""))
	if signature == _tactical_signature:
		return
	var data := tactical_display_snapshot()
	signature = str(data.get("state_signature", signature))
	_tactical_signature = signature
	if not bool(data.get("available", false)):
		_set_tactical_display_visible(false)
		return
	var actor: Dictionary = data.get("actor", {})
	if actor.is_empty():
		_set_tactical_display_visible(false)
		return
	var sector: Dictionary = data.get("nominal_sector", {})
	var has_firearm := not bool(actor.get("melee", true)) and float(sector.get("range_px", 0.0)) > 0.0
	_tactical_sector.visible = has_firearm
	_tactical_coverage.visible = has_firearm
	_tactical_info.visible = true
	if has_firearm:
		_rebuild_nominal_sector(sector)
		_rebuild_route_query_markers(data.get("route_samples", []))
	else:
		_tactical_sector.mesh = null
		_tactical_coverage.multimesh.instance_count = 0
	_tactical_info.text = _tactical_summary(data)
	_tactical_panel.visible = true


func _set_tactical_display_visible(value: bool) -> void:
	if _tactical_sector != null:
		_tactical_sector.visible = value
	if _tactical_coverage != null:
		_tactical_coverage.visible = value
	if _tactical_info != null:
		_tactical_info.visible = value
	if _tactical_panel != null:
		_tactical_panel.visible = value


func _clear_tactical_display() -> void:
	_tactical_signature = ""
	_set_tactical_display_visible(false)


func _rebuild_nominal_sector(sector: Dictionary) -> void:
	var origin: Vector2 = sector.get("origin", Vector2.ZERO)
	var facing := float(sector.get("facing_deg", 0.0))
	var half_angle := float(sector.get("half_angle_deg", 0.0))
	var range_px := float(sector.get("range_px", 0.0))
	var center := Adapter.world_anchor(host.grid, origin, 0.055)
	if not center.is_finite() or range_px <= 0.0 or half_angle <= 0.0:
		_tactical_sector.mesh = null
		_tactical_sector.visible = false
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 32
	var start_angle := deg_to_rad(facing - half_angle)
	var span := deg_to_rad(half_angle * 2.0)
	for index in SEGMENTS:
		var angle_a := start_angle + span * float(index) / float(SEGMENTS)
		var angle_b := start_angle + span * float(index + 1) / float(SEGMENTS)
		var logic_a := origin + Vector2(cos(angle_a), sin(angle_a)) * range_px
		var logic_b := origin + Vector2(cos(angle_b), sin(angle_b)) * range_px
		var point_a := Adapter.world_anchor(host.grid, logic_a, 0.055)
		var point_b := Adapter.world_anchor(host.grid, logic_b, 0.055)
		if not point_a.is_finite() or not point_b.is_finite():
			continue
		st.add_vertex(center)
		st.add_vertex(point_a)
		st.add_vertex(point_b)
	_tactical_sector.mesh = st.commit()


func _rebuild_route_query_markers(raw_samples: Array) -> void:
	var candidates: Array[Dictionary] = []
	for sample in raw_samples:
		if candidates.size() >= TACTICAL_SAMPLE_CAP:
			break
		if not sample is Dictionary:
			continue
		var logic: Vector2 = sample.get("position", Vector2.INF)
		var anchor := Adapter.world_anchor(host.grid, logic, 0.075)
		if not anchor.is_finite():
			continue
		candidates.append({"anchor": anchor, "clear": bool(sample.get("geometry_clear", false))})
	var markers: MultiMesh = _tactical_coverage.multimesh
	markers.instance_count = candidates.size()
	for index in candidates.size():
		var record: Dictionary = candidates[index]
		markers.set_instance_transform(index, Transform3D(Basis.IDENTITY, record["anchor"]))
		markers.set_instance_color(index, Color("4fe3d0") if bool(record["clear"]) else Color("e0a86b", 0.58))
	_tactical_coverage.visible = not candidates.is_empty()


func _tactical_summary(data: Dictionary) -> String:
	var actor: Dictionary = data.get("actor", {})
	var lines := PackedStringArray()
	lines.append("%s · %s · %d 发" % [str(actor.get("name", "队员")), str(actor.get("weapon_id", "")), int(actor.get("ammo", 0))])
	var sector: Dictionary = data.get("nominal_sector", {})
	if bool(actor.get("melee", true)):
		lines.append("近战装备 · 无枪械射界")
	else:
		lines.append("名义射界 %.1f 格 / ±%.0f° · 朝 %.0f°" % [float(sector.get("range_px", 0.0)) / 32.0, float(sector.get("half_angle_deg", 0.0)), float(sector.get("facing_deg", 0.0))])
		lines.append("青点：射界/视线通 · 琥珀点：未通")
	var route_parts := PackedStringArray()
	for route in data.get("route_summary", []):
		if not route is Dictionary:
			continue
		var route_id := str(route.get("route_id", ""))
		var name := "主路" if route_id == "main" else ("侧翼" if route_id == "flank" else ("备选" if route_id == "alternate" else "路线"))
		route_parts.append("%s %d/%d" % [name, int(route.get("covered_samples", 0)), int(route.get("total_samples", 0))])
	if not route_parts.is_empty():
		lines.append("路线覆盖 " + " · ".join(route_parts))
	var target_states: Array = data.get("target_states", [])
	if not target_states.is_empty():
		var target: Dictionary = target_states[0]
		var reason := str(target.get("block_reason", ""))
		lines.append("目标 %d：%s" % [int(target.get("id", -1)), _tactical_reason_label(reason, bool(target.get("geometry_clear", false)))])
	return "\n".join(lines)


func _tactical_reason_label(reason: String, geometry_clear: bool) -> String:
	if reason.is_empty():
		return "交战条件满足 · 冷却另计" if geometry_clear else "待复核"
	match reason:
		"hold": return "未获开火许可"
		"ammo": return "弹药不足"
		"range": return "超出射程"
		"cone": return "不在朝向范围"
		"los": return "被地形遮挡"
		_: return "不可射（%s）" % reason


func _new_enemy(key: String) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.name = "Enemy_" + key
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.24
	mesh.height = 1.22
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c16751")
	body.material_override = material
	body.add_child(_box("FacingCue", Vector3(0.09, 0.09, 0.35), Vector3(0, 0.25, -0.30), Color("ffd098")))
	_world.add_child(body)
	_enemy_nodes[key] = body
	return body


func _sync_enemies() -> void:
	for node in _enemy_nodes.values(): node.visible = false
	for enemy in host.enemies:
		if not is_instance_valid(enemy): continue
		var key := str(enemy.label_id)
		var body: MeshInstance3D = _enemy_nodes[key] if _enemy_nodes.has(key) else _new_enemy(key)
		body.visible = enemy.alive and enemy.active
		body.position = Adapter.world_anchor(host.grid, enemy.global_position, 0.68)
		body.rotation.y = Space.facing_yaw(enemy.facing_deg)


func _sync_recorded(data: Dictionary) -> void:
	for node in _actor_nodes.values(): node.visible = false
	for node in _enemy_nodes.values(): node.visible = false
	# Operators are instantiated by initial yard binding. No live fields are read here.
	for record in data.get("ops", []):
		var key := str(record.get("id", -1))
		if not _actor_nodes.has(key): continue
		var body: MeshInstance3D = _actor_nodes[key]
		body.visible = bool(record.get("alive", false)) and bool(record.get("visible", true))
		body.position = Adapter.recorded_anchor(record.get("pos", Vector2.ZERO), int(record.get("tier", 0)), 0.68)
		body.rotation.y = Space.facing_yaw(float(record.get("facing", 90.0)))
	for record in data.get("enemies", []):
		var key := str(record.get("id", -1))
		var body: MeshInstance3D = _enemy_nodes[key] if _enemy_nodes.has(key) else _new_enemy(key)
		body.visible = bool(record.get("alive", false)) and bool(record.get("active", true))
		body.position = Adapter.recorded_anchor(record.get("pos", Vector2.ZERO), int(record.get("tier", 0)), 0.68)
		body.rotation.y = Space.facing_yaw(float(record.get("facing", 90.0)))


func _build_tactical_landmarks() -> void:
	for route in ["main", "flank"]:
		var points: Array = host.route_world.get(route, [])
		if not points.is_empty():
			_landmark(route, points[0], "主路入口" if route == "main" else "侧翼入口", Color("e09953"))
	_landmark("exit", host.grid.cell_to_world_center(host.level.escape_cell), "撤离 / 敌军越界", Color("73c8ca"))
	var zone: Rect2 = host.level.ambush_zone
	var corners := [zone.position, zone.position + Vector2(zone.size.x, 0), zone.end, zone.position + Vector2(0, zone.size.y)]
	for i in 4:
		var a := Adapter.recorded_anchor(corners[i], 0, 0.04)
		var b := Adapter.recorded_anchor(corners[(i + 1) % 4], 0, 0.04)
		var delta := b - a
		var edge := _box("PermissionBoundary_%d" % i, Vector3(delta.length(), 0.025, 0.035), (a + b) * 0.5, Color("c8ab69"))
		edge.rotation.y = -atan2(delta.z, delta.x)
		_world.add_child(edge)
	_landmark("permission", zone.get_center(), "自动许可 · 入区后待伏开火", Color("c8ab69"))


func _landmark(key: String, logic: Vector2, title: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = "Landmark_" + key
	label.text = title
	label.font_size = 36
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.position = Adapter.world_anchor(host.grid, logic, 1.6)
	_world.add_child(label)
	landmark_nodes[key] = label


func _build_fx_pool() -> void:
	for i in FX_CAP:
		var node := _box("RecordedEventFX_%d" % i, Vector3(0.1, 0.1, 0.1), Vector3.ZERO, Color("ffdd88"))
		node.visible = false
		_world.add_child(node)
		_fx_nodes.append(node)


func _build_tactical_display_nodes() -> void:
	_tactical_sector = MeshInstance3D.new()
	_tactical_sector.name = "SelectedNominalFireSector"
	var sector_material := StandardMaterial3D.new()
	sector_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sector_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sector_material.albedo_color = Color("36d9cf", 0.20)
	sector_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sector_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_tactical_sector.material_override = sector_material
	_tactical_sector.visible = false
	_world.add_child(_tactical_sector)

	_tactical_coverage = MultiMeshInstance3D.new()
	_tactical_coverage.name = "SelectedRouteFireQueries"
	var markers := MultiMesh.new()
	markers.transform_format = MultiMesh.TRANSFORM_3D
	markers.use_colors = true
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.085
	marker_mesh.height = 0.17
	markers.mesh = marker_mesh
	_tactical_coverage.multimesh = markers
	var marker_material := StandardMaterial3D.new()
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.vertex_color_use_as_albedo = true
	_tactical_coverage.material_override = marker_material
	_tactical_coverage.visible = false
	_world.add_child(_tactical_coverage)

func _recorded_event_anchor(ev: Dictionary, enemy: bool) -> Vector3:
	var snap: Dictionary = {}
	for candidate in host.battle_log.snapshots:
		if int(candidate.get("tick", -1)) > int(ev.get("tick", 0)): break
		snap = candidate
	var collection: Array = snap.get("data", {}).get("enemies" if enemy else "ops", [])
	for record in collection:
		if int(record.get("id", -2)) == int(ev.get("actor_id", -1)):
			return Adapter.recorded_anchor(record.get("pos", Vector2.ZERO), int(record.get("tier", 0)), 0.9)
	return Adapter.recorded_anchor(ev.get("position", Vector2.ZERO), 0, 0.9)


func _sync_event_fx(tick: int) -> void:
	for node in _fx_nodes: node.visible = false
	var count := 0
	for ev in host.battle_log.events:
		var kind := str(ev.get("type", ""))
		if kind not in ["fire", "kill", "return_fire"]: continue
		var age := tick - int(ev.get("tick", 0))
		if age < 0 or age >= (12 if kind == "kill" else 6): continue
		if count >= FX_CAP: break
		var node := _fx_nodes[count]
		node.position = _recorded_event_anchor(ev, kind != "fire")
		node.scale = Vector3.ONE * (4.0 if kind == "kill" else 2.0)
		node.visible = true
		count += 1


func _exit_tree() -> void:
	if host != null and is_instance_valid(host):
		var legacy_world := host.get_node_or_null("World") as Node2D
		if legacy_world != null:
			legacy_world.visible = true
