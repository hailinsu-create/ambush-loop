extends RefCounted

## Original static industrial miniature. Geometry is built once; batches share materials.
## All solid trim stays inside the existing blocked cells/platform, never adds collision.
const Space := preload("res://scripts/presentation/world_space.gd")
const Layout := preload("res://scripts/presentation/yard_wall_layout.gd")
const GROUND_SHADER := preload("res://art/yard_v1/concrete.gdshader")
const WALL_SHADER := preload("res://art/yard_v1/brick.gdshader")
const WAREHOUSE_CELL := Vector2i(20, 10)

var materials: Dictionary = {}
var batches: Dictionary = {}
var warehouse_cells := Rect2i()
var build_count := 0
var lamp_bounds := AABB()

func _init() -> void:
	for spec in [["steel", "394c59", 0.62, 0.45], ["edge", "81908e", 0.90, 0.0],
		["wood", "766247", 0.92, 0.0], ["paint", "c9a866", 0.88, 0.0],
		["slab", "727d80", 0.92, 0.0], ["dark", "1e303b", 0.85, 0.0],
		["door", "526973", 0.70, 0.25]]:
		var surface := StandardMaterial3D.new()
		surface.albedo_color = Color(str(spec[1]))
		surface.roughness = float(spec[2])
		surface.metallic = float(spec[3])
		materials[str(spec[0])] = surface
	var concrete := ShaderMaterial.new()
	concrete.shader = GROUND_SHADER
	materials["concrete"] = concrete
	var brick := ShaderMaterial.new()
	brick.shader = WALL_SHADER
	materials["brick"] = brick
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color("ffe0a0")
	lamp.emission_enabled = true
	lamp.emission = Color("ffd089")
	lamp.emission_energy_multiplier = 1.6
	materials["lamp"] = lamp

func material(key: String) -> Material:
	return materials[key]

func find_warehouse(grid: RefCounted) -> Rect2i:
	for rectangle in Layout.rectangles(grid, 40, 22):
		var cells: Rect2i = rectangle.cells
		if cells.has_point(WAREHOUSE_CELL):
			warehouse_cells = cells
			break
	return warehouse_cells

func build(world: Node3D, grid: RefCounted, supply_position: Vector2) -> void:
	if build_count > 0: return
	build_count += 1
	find_warehouse(grid)
	for rectangle in Layout.rectangles(grid, 40, 22):
		var cells: Rect2i = rectangle.cells
		var center := Space.logic_to_world((Vector2(cells.position) + Vector2(cells.size) * 0.5) * 32.0)
		var height := float(rectangle.height)
		_box("edge", Vector3(cells.size.x - 0.10, 0.065, cells.size.y - 0.10), center + Vector3(0, height - 0.05, 0))
		_box("dark", Vector3(cells.size.x - 0.05, 0.08, cells.size.y - 0.05), center + Vector3(0, 0.05, 0))
	_build_warehouse()
	_build_dock(grid)
	_build_supply_light(world, grid, supply_position)
	_flush(world)

func _build_warehouse() -> void:
	if warehouse_cells.size == Vector2i.ZERO: return
	var footprint := Vector2(warehouse_cells.size)
	var center := Space.logic_to_world((Vector2(warehouse_cells.position) + footprint * 0.5) * 32.0)
	var width := footprint.x - 0.12
	var depth := footprint.y - 0.12
	_box("brick", Vector3(width, 2.16, depth), center + Vector3(0, 1.08, 0))
	_box("dark", Vector3(width - 0.05, 0.12, depth - 0.05), center + Vector3(0, 2.20, 0))
	_box("steel", Vector3(width - 0.05, 0.055, depth - 0.05), center + Vector3(0, 2.28, 0))
	var front := center + Vector3(0, 0, depth * 0.5 - 0.005)
	_box("steel", Vector3(2.4, 1.75, 0.05), front + Vector3(0, 0.88, 0))
	_box("door", Vector3(2.14, 1.50, 0.06), front + Vector3(0, 0.80, 0.003))
	for rib in 9:
		_box("edge", Vector3(2.10, 0.025, 0.012), front + Vector3(0, 0.15 + rib * 0.16, 0.037))
	_box("paint", Vector3(2.58, 0.17, 0.025), front + Vector3(0, 1.90, 0.021))
	for side in [-1.0, 1.0]:
		_box("steel", Vector3(0.14, 2.14, 0.14), center + Vector3(side * (width * 0.5 - 0.10), 1.07, depth * 0.5 - 0.10))
		_box("dark", Vector3(0.70, 0.40, 0.028), front + Vector3(side * (width * 0.5 - 0.63), 1.55, 0))
		for slat in 4:
			_box("edge", Vector3(0.62, 0.02, 0.02), front + Vector3(side * (width * 0.5 - 0.63), 1.39 + slat * 0.095, 0.02))

func _build_dock(grid: RefCounted) -> void:
	## Derive edge from the authored tier; geometry does not create walkable surfaces.
	var tier_cells: Array[Vector2i] = []
	for y in 22:
		for x in 40:
			if grid.get_elevation_tier(x, y) == 1: tier_cells.append(Vector2i(x,y))
	for cell in tier_cells:
		var center := Space.logic_to_world((Vector2(cell) + Vector2.ONE * 0.5) * 32.0)
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if tier_cells.has(cell + direction): continue
			if grid.has_ramp_link(cell, cell + direction): continue
			var along_x: bool = direction.y != 0
			var edge := center + Vector3(direction.x * 0.46, 0.40, direction.y * 0.46)
			_box("steel", Vector3(0.95 if along_x else 0.07, 0.78, 0.07 if along_x else 0.95), edge)
			_box("paint", Vector3(0.95 if along_x else 0.08, 0.05, 0.08 if along_x else 0.95), edge + Vector3(0, 0.40, 0))

func _build_supply_light(world: Node3D, grid: RefCounted, supply_position: Vector2) -> void:
	var supply_cell: Vector2i = grid.world_to_cell(supply_position)
	var mount := supply_cell
	var nearest := INF
	for y in 22:
		for x in 40:
			if not grid.is_blocked(x,y): continue
			var distance := Vector2(Vector2i(x,y) - supply_cell).length_squared()
			if distance < nearest:
				nearest = distance
				mount = Vector2i(x,y)
	var at := Space.logic_to_world((Vector2(mount) + Vector2.ONE * 0.5) * 32.0)
	lamp_bounds = AABB(at + Vector3(-0.28, 0, -0.18), Vector3(0.56, 1.90, 0.36))
	_box("steel", Vector3(0.09, 1.75, 0.09), at + Vector3(0, 0.87, 0))
	_box("dark", Vector3(0.56, 0.14, 0.36), at + Vector3(0, 1.83, 0))
	_box("lamp", Vector3(0.46, 0.05, 0.28), at + Vector3(0, 1.75, 0))
	var light := OmniLight3D.new()
	light.name = "SupplyWarmLamp"
	light.position = at + Vector3(0, 1.65, 0)
	light.light_color = Color("ffcb8c")
	light.light_energy = 1.25
	light.omni_range = 5.0
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	world.add_child(light)
	var stripe := Space.logic_to_world(supply_position, 0.012)
	_box("paint", Vector3(1.2, 0.012, 0.07), stripe + Vector3(0, 0, 0.55))
	_box("paint", Vector3(0.07, 0.012, 1.2), stripe + Vector3(-0.55, 0, 0))

func _box(key: String, dimensions: Vector3, position: Vector3) -> void:
	if not batches.has(key): batches[key] = []
	batches[key].append(Transform3D(Basis.from_scale(dimensions), position))

func _flush(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "IndustrialHeroCluster"
	world.add_child(root)
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	for key in batches:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = cube
		multimesh.instance_count = batches[key].size()
		for index in batches[key].size(): multimesh.set_instance_transform(index, batches[key][index])
		var node := MultiMeshInstance3D.new()
		node.name = "Static_" + str(key)
		node.multimesh = multimesh
		node.material_override = material(str(key))
		root.add_child(node)
