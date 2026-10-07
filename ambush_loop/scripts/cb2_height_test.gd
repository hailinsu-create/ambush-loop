extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const Grid := preload("res://scripts/grid.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Paths := preload("res://scripts/raid/pathfinder.gd")
const Picker := preload("res://scripts/presentation/world_picker_3d.gd")
var checks := 0
var failures := 0

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("CB2_HEIGHT: " + label)

func _run() -> void:
	var grid := Grid.new()
	var high := Vector2i(16, 11)
	var ground := Vector2i(16, 13)
	var a := grid.cell_to_world_center(high)
	var b := grid.cell_to_world_center(ground)
	_expect(grid.get_elevation_tier(high.x, high.y) == 1, "yard highpoint exists")
	_expect(not grid.can_traverse_height(Vector2i(16, 12), ground), "cliff cannot be crossed")
	_expect(grid.can_traverse_height(Vector2i(15, 12), Vector2i(15, 13)), "ramp legal")
	var path := Paths.find_path(grid, ground, high)
	_expect(not path.is_empty(), "highpoint reachable")
	for i in range(1, path.size()):
		_expect(grid.can_traverse_height(path[i-1], path[i]), "every path edge legal")
	var frame := {"height_schema": 1, "elevation_tier": grid.elevation_tier.duplicate()}
	_expect(Space.logic_to_surface(frame, a).y == 1.0, "actor and recorded terrain share high anchor")
	_expect(Space.logic_to_surface(frame, b).y == 0.0, "ground anchor stays zero")
	_expect(Space.logic_to_surface({}, a).y == 0.0, "legacy replay explicitly flat")
	frame["blocked"] = grid.blocked.duplicate()
	frame["occlusion_kind"] = grid.occlusion_kind.duplicate()
	frame["ramp_links"] = grid.ramp_links.duplicate()
	_expect(Space.terrain_supported(frame), "complete recorded terrain valid")
	var bad := frame.duplicate(true)
	bad.height_schema = 2
	_expect(not Space.terrain_supported(bad), "unknown terrain rejected")
	bad = frame.duplicate(true)
	bad.elevation_tier[0] = 255
	_expect(not Space.terrain_supported(bad), "corrupt terrain rejected")
	root.size = Vector2i(1280,720)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 30.0
	await process_frame
	for yaw in range(0,360,45):
		var angle := deg_to_rad(float(yaw))
		camera.position = Vector3(sin(angle)*20.0,20.0,cos(angle)*20.0)
		camera.look_at(Vector3.ZERO)
		frame["ops"] = []
		var at := camera.unproject_position(Space.logic_to_surface(frame,a))
		var pick := Picker.pick(camera,at,frame)
		_expect(pick.get("valid",false) and pick.get("pos",Vector2.ZERO).distance_to(a)<0.1, "high ground pick at yaw %d" % yaw)
		frame.ops = [{"id":333,"pos":a,"active":true,"alive":true}]
		at = camera.unproject_position(Space.logic_to_surface(frame,a,1.1))
		pick = Picker.pick(camera,at,frame)
		_expect(pick.get("id",-1)==333, "high actor pick at yaw %d" % yaw)
	camera.free()
	grid.elevation_tier.fill(0)
	_expect(Space.logic_to_surface(frame, a).y == 1.0, "recorded terrain independent of live world")
	grid.blocked.fill(0)
	grid.occlusion_kind.fill(Grid.OCCLUSION_INHERIT)
	grid.ramp_links.clear()
	a = grid.cell_to_world_center(Vector2i(6, 6))
	b = grid.cell_to_world_center(Vector2i(10, 6))
	grid.set_blocked(8, 6, true)
	grid.set_occlusion_kind(8, 6, Grid.OCCLUSION_LOW)
	_expect(not grid.has_height_los(a, b), "ground cannot fire through low wall")
	grid.set_elevation_tier(6, 6, 1)
	grid.set_elevation_tier(10, 6, 1)
	_expect(grid.has_height_los(a, b) and grid.has_height_los(b, a), "highpoint clears low wall reciprocally")
	grid.set_occlusion_kind(8, 6, Grid.OCCLUSION_FULL)
	_expect(not grid.has_height_los(a, b), "full wall blocks highpoint")
	_expect(not grid.has_height_los(Vector2(NAN, 1), b), "invalid coordinates fail closed")
	print("CB2_HEIGHT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 2)
