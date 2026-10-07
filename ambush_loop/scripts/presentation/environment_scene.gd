extends Node3D

## Visual assembly consumes the recorded grid. Bounds only control cutaway;
## nothing in this class creates tactical blockers, physics or navigation.
const FORMAT := 1
const REVISION := "50ef7883285c4419dbd8339b935433dc6bb5e3f8"
const LEGACY_LAYOUT_REVISION := "six_level_grid_assembly_1"
const LAYOUT_REVISION := "six_level_grid_assembly_2"
const Assets := preload("res://scripts/presentation/asset_library.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const LandmarkCutaway := preload("res://scripts/presentation/landmark_cutaway.gd")
const LANDMARKS := {"yard": "env_warehouse_shell", "warehouse": "env_warehouse_gantry", "pump": "env_pump_skid", "railcut": "env_signal_mast", "depot": "env_depot_tank_pair", "radio": "env_radio_antenna"}
var walls: Array = []
var footprint_rectangles: Array = []
var door_leaf: Node3D
var _door_locked := false
var _batches := {}
var _detail := 0
var _contact_sources: Array = []
var _contact_batches: Array = []
var _contact_assets := {}
var _contact_bounds: Array = []
var _contact_dirty := true
var _cutaway_schema := 0


static func supported(data: Dictionary) -> bool:
	return int(data.get("environment_schema", 0)) == FORMAT and str(data.get("environment_revision", "")) == REVISION and str(data.get("environment_layout_revision", "")) in [LEGACY_LAYOUT_REVISION, LAYOUT_REVISION] and str(data.get("level_id", "")) in LANDMARKS and data.get("blocked") is PackedByteArray and data.blocked.size() == 880


func build(frame: Dictionary, detail: int) -> void:
	_detail = detail
	_cutaway_schema=int(frame.get("environment_cutaway_schema",0))
	set_meta("environment_revision", REVISION)
	set_meta("environment_layout_revision", str(frame.environment_layout_revision))
	set_meta("recorded_layout_hash", hash(frame.blocked))
	set_meta("theme", str(frame.level_id))
	var blocked: PackedByteArray = frame.blocked.duplicate()
	if bool(frame.get("has_door", false)):
		var door: Vector2 = frame.door_pos / 32.0
		var index := floori(door.y) * 40 + floori(door.x)
		if index >= 0 and index < blocked.size():
			blocked[index] = 0 # door leaf renders this cell; never alter the source grid.
	footprint_rectangles = Geometry.blocked_rectangles(blocked)
	var inner: Array = []
	for rect: Rect2i in footprint_rectangles:
		if rect.position.x > 4 and rect.position.y > 4 and rect.end.x < 35 and rect.end.y < 19 and rect.size.x > 1 and rect.size.y > 1:
			inner.append(rect)
	inner.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.get_area() > b.get_area())
	for y in 11:
		for x in 20:
			_batch(_ground(str(frame.level_id), x * 2 + 1, y * 2 + 1), Vector3(x * 2 - 19, 0, y * 2 - 10))
	for rect: Rect2i in footprint_rectangles:
		var center := Vector3(rect.position.x - 20 + rect.size.x * 0.5, 0, rect.position.y - 11 + rect.size.y * 0.5)
		# A low footprint keeps the existing no-go region legible when a wall/roof
		# is cut away. Its size is copied grid geometry, never a GLB-derived rule.
		Geometry.box(self, Vector3(rect.size.x, 0.035, rect.size.y), center + Vector3(0, 0.006, 0), Geometry.material(Color("343b3d")))
		if str(frame.environment_layout_revision) == LAYOUT_REVISION and _low_footprint(frame,rect):
			for y in range(rect.position.y,rect.end.y):
				for x in range(rect.position.x,rect.end.x):
					var crate := _place("env_yard_crate",Vector3(x-19.5,0,y-10.5))
					var dimensions: Array = Assets.asset_record("env_yard_crate").dimensions_m
					crate.scale = Vector3(0.96/float(dimensions[0]),1.0/float(dimensions[1]),0.96/float(dimensions[2]))
					_register_cutaway(crate)
			continue
		if rect in inner:
			var main_rect: bool = rect == inner[0]
			_build_block(str(frame.level_id), rect, center, main_rect)
		else:
			var along_x: bool = rect.size.x >= rect.size.y
			var length: float = rect.size.x if along_x else rect.size.y
			var wall_id := "env_wall_brick_2m" if frame.level_id in ["yard", "warehouse"] else "env_low_wall_2m"
			var wall := _place(wall_id, center, 0 if along_x else PI * 0.5)
			wall.scale.x = length / (2.0 if wall_id == "env_wall_brick_2m" else 2.12)
			if wall_id == "env_wall_brick_2m":
				wall.scale.y = 0.75
			_register_cutaway(wall)
			if frame.level_id not in ["yard", "warehouse"] and length >= 4:
				for i in int(length / 2):
					var at := center + (Vector3.RIGHT if along_x else Vector3.BACK) * (-length * 0.5 + 1 + i * 2)
					var fence := _place("env_fence_section", at + Vector3(0, 1.04, 0), 0 if along_x else PI * 0.5)
					_register_cutaway(fence)
	if frame.level_id == "railcut":
		for y in range(3, 19, 2):
			_batch("env_rail_2m", Vector3(-6.5, -0.27, y - 10.5))
	# Four frozen reuse props and the remaining original inventory have concrete
	# decorative homes within already-blocked cargo footprints.
	if not inner.is_empty():
		var cargo: Rect2i = inner.back()
		var props := ["env_handcart", "env_jerry_can", "env_spare_tire", "env_wooden_barrel", "field_radio", "env_barbed_wire"]
		for i in props.size():
			var x: float = cargo.position.x + 0.5 + (i % cargo.size.x)
			var z: float = cargo.position.y + 0.5 + floori(float(i) / cargo.size.x) % cargo.size.y
			var prop := _place(props[i], Vector3(x - 20, 0.04, z - 11), float(i % 4) * PI * 0.5)
			var dimensions: Array = Assets.asset_record(props[i]).get("dimensions_m", [1, 1, 1])
			var size: float = maxf(float(dimensions[0]), float(dimensions[2]))
			prop.scale = Vector3.ONE * minf(0.88 / maxf(size, 0.1), 1.0)
	for pos in [Vector3(-15.5, 0, -5.5), Vector3(15.5, 0, 6.5)]:
		_place("yard_lamp", pos)
		var lamp := OmniLight3D.new()
		lamp.position = pos + Vector3(0, 2.8, 0)
		lamp.light_color = Color("ffbf76")
		lamp.light_energy = 1.3
		lamp.omni_range = 6.0
		lamp.shadow_enabled = false
		add_child(lamp)
	if bool(frame.get("has_door", false)):
		var at := Space.logic_to_world(frame.door_pos)
		var door_frame := _place("env_door_frame", at)
		door_frame.scale.x = 0.5
		_register_cutaway(door_frame)
		var leaf := _place("env_door_leaf", at)
		leaf.scale.x = 0.5
		door_leaf = leaf.find_child("env_door_leaf__leaf_pivot", true, false) as Node3D
		set_door(bool(frame.door_locked))
		_register_cutaway(leaf, true)
	_flush_batches()


func _low_footprint(frame: Dictionary, rect: Rect2i) -> bool:
	var kinds: PackedByteArray = frame.get("occlusion_kind",PackedByteArray())
	if kinds.size() != 880:
		return false
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if kinds[y*40+x] != 2:
				return false
	return true


func _build_block(theme: String, rect: Rect2i, center: Vector3, main_rect: bool) -> void:
	var id: String = LANDMARKS[theme]
	if theme == "yard":
		var shell := _place("env_warehouse_shell", center)
		shell.scale = Vector3(float(rect.size.x) / 6.38, 1, float(rect.size.y) / 4.44)
		_register_cutaway(shell)
		var roof := _place("env_warehouse_roof", center)
		roof.scale = shell.scale
		_register_cutaway(roof)
		return
	if theme == "warehouse":
		var gantry := _place(id, center)
		gantry.scale = Vector3(minf(float(rect.size.x) / 4.5, 1.2), 1, float(rect.size.y) / 3.65)
		_register_cutaway(gantry)
		for y in rect.size.y:
			for x in rect.size.x:
				_batch("env_yard_crate", Vector3(rect.position.x + x - 19.5, 0.04, rect.position.y + y - 10.5))
		return
	if main_rect or theme in ["pump", "depot"]:
		var landmark := _place(id, center)
		var size: Array = Assets.asset_record(id).dimensions_m
		var fit := minf(minf(float(rect.size.x) / float(size[0]), float(rect.size.y) / float(size[2])), 1.3)
		landmark.scale = Vector3(fit, 1, fit)
		_register_cutaway(landmark)
		if theme == "pump":
			var pipe := _place("env_pipe_elbow", center + Vector3(0, 0, minf(rect.size.y * 0.35, 1.2)), PI * 0.5)
			_register_cutaway(pipe)
		return
	# Secondary equipment compounds keep their authored no-go footprint without
	# fabricating a second landmark or making visual open space look navigable.
	for y in rect.size.y:
		for x in rect.size.x:
			if (x + y) % 2 == 0:
				_batch("env_yard_crate", Vector3(rect.position.x + x - 19.5, 0.04, rect.position.y + y - 10.5))
	var low := _place("env_low_wall_2m", center)
	low.scale.x = float(rect.size.x) / 2.12
	_register_cutaway(low)


func set_door(locked: bool) -> bool:
	var changed := _door_locked != locked
	_door_locked = locked
	_contact_dirty = _contact_dirty or changed
	if door_leaf != null:
		door_leaf.rotation_degrees.y = 0.0 if locked else -90.0
	return changed


static func _ground(theme: String, x: int, y: int) -> String:
	var outside := x < 4 or x > 35 or y < 4 or y > 18
	match theme:
		"railcut": return "env_ground_earth_2m" if outside else "env_ground_gravel_2m"
		"pump": return "env_ground_steel_2m" if x > 16 and x < 29 and y > 8 and y < 14 else "env_ground_concrete_2m"
		"warehouse", "radio": return "env_ground_cobble_2m" if outside else "env_ground_concrete_2m"
		"depot": return "env_ground_gravel_2m" if outside else "env_ground_concrete_2m"
	return "env_ground_earth_2m" if outside else "env_ground_concrete_2m"


func _place(id: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var node := Assets.instantiate(id, _detail)
	if node == null:
		node = Node3D.new() # Loader emits the failure; keep a managed empty root.
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	return node


func _register_cutaway(node: Node, moving: bool = false) -> void:
	_contact_sources.append(node)
	if _cutaway_schema==LandmarkCutaway.FORMAT and node.get_meta("asset_id","")=="env_radio_antenna":
		node.set_meta("cutaway_parts",LandmarkCutaway.split(node))
	_register_wall_meshes(node,moving)


func _register_wall_meshes(node: Node, moving: bool) -> void:
	if node is MeshInstance3D:
		walls.append({"mesh": node, "bounds": node.global_transform * node.get_meta("cutaway_bounds",node.get_aabb()), "mode": "hide", "moving": moving})
	for child in node.get_children():
		_register_wall_meshes(child, moving)


func contact_bounds() -> Array:
	# Fixed LOD0 geometry from this frame's versioned assembly. Cutaway visibility
	# and camera LOD never remove a solid surface or change body placement.
	if _contact_dirty:
		_contact_bounds = _contact_batches.duplicate()
		for node: Node3D in _contact_sources:
			for bounds: AABB in _asset_contact_bounds(str(node.get_meta("asset_id",""))):
				_contact_bounds.append(node.global_transform*bounds)
		_contact_dirty = false
	return _contact_bounds


func _asset_contact_bounds(id: String) -> Array:
	var key := id+(":"+str(_door_locked) if id=="env_door_leaf" else "")
	if not _contact_assets.has(key):
		var source := Assets.instantiate(id,0)
		var bounds: Array = []
		if source != null:
			if id=="env_door_leaf":
				var pivot := source.find_child("env_door_leaf__leaf_pivot",true,false) as Node3D
				if pivot != null:
					pivot.rotation_degrees.y=0.0 if _door_locked else -90.0
			_collect_bounds(source,source.transform.affine_inverse(),bounds)
			source.free()
		_contact_assets[key]=bounds
	return _contact_assets[key]


func _collect_bounds(node: Node, transform: Transform3D, result: Array) -> void:
	if node is Node3D:
		transform=transform*node.transform
	if node is MeshInstance3D:
		result.append(transform*node.get_aabb())
	for child in node.get_children():
		_collect_bounds(child,transform,result)


func _batch(id: String, at: Vector3, yaw: float = 0.0) -> void:
	# Cargo is batched in small spatial groups: an obscured body hides a nearby
	# group rather than every cargo pile in the map. Ground never cuts away.
	var key := id + (":%d:%d" % [floori(at.x / 4.0), floori(at.z / 4.0)] if id == "env_yard_crate" else "")
	if not _batches.has(key):
		_batches[key] = {"id": id, "poses": []}
	_batches[key].poses.append(Transform3D(Basis(Vector3.UP, yaw), at))


func _flush_batches() -> void:
	for key in _batches:
		var id: String = _batches[key].id
		var poses: Array = _batches[key].poses
		var source := Assets.instantiate(id, _detail)
		if source == null:
			continue
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_append_mesh(tool, source, Transform3D.IDENTITY)
		var mesh := tool.commit()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = poses.size()
		for i in multi.instance_count:
			multi.set_instance_transform(i, poses[i])
		var display := MultiMeshInstance3D.new()
		display.name = "Batch_" + key.replace(":", "_")
		display.multimesh = multi
		display.material_override = Assets.material_for_slot("environment_v2_atlas")
		display.set_meta("asset_id", id)
		display.set_meta("asset_lod", _detail)
		add_child(display)
		if id == "env_yard_crate":
			walls.append({"mesh": display, "bounds": multi.get_aabb(), "mode": "hide"})
			for pose: Transform3D in poses:
				for bounds: AABB in _asset_contact_bounds(id):
					_contact_batches.append(pose*bounds)
		source.free()
	_batches.clear()


func _append_mesh(tool: SurfaceTool, node: Node, transform: Transform3D) -> void:
	if node is Node3D:
		transform = transform * node.transform
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			tool.append_from(node.mesh, surface, transform)
	for child in node.get_children():
		_append_mesh(tool, child, transform)
