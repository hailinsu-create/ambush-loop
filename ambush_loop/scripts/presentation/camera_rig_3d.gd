extends Node3D

const Space := preload("res://scripts/presentation/world_space.gd")
const DEFAULT_YAW := 35.0
const DEFAULT_PITCH := 55.0
const DEFAULT_SIZE := 24.0
const MIN_PITCH := 35.0
const MAX_PITCH := 65.0
const MIN_SIZE := 12.0
const MAX_SIZE := 36.0

var camera := Camera3D.new()
var focus := Vector3.ZERO
var yaw_deg := DEFAULT_YAW
var pitch_deg := DEFAULT_PITCH
var view_size := DEFAULT_SIZE


func _ready() -> void:
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.1
	camera.far = 160.0
	add_child(camera)
	camera.make_current()
	apply_pose()


func reset_view() -> void:
	focus = Vector3.ZERO
	yaw_deg = DEFAULT_YAW
	pitch_deg = DEFAULT_PITCH
	view_size = DEFAULT_SIZE
	apply_pose()


func apply_pose() -> void:
	yaw_deg = fposmod(yaw_deg, 360.0)
	pitch_deg = clampf(pitch_deg, MIN_PITCH, MAX_PITCH)
	view_size = clampf(view_size, MIN_SIZE, MAX_SIZE)
	focus.x = clampf(focus.x, -Space.HALF_MAP.x - 2.0, Space.HALF_MAP.x + 2.0)
	focus.z = clampf(focus.z, -Space.HALF_MAP.y - 2.0, Space.HALF_MAP.y + 2.0)
	focus.y = 0.0
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 60.0
	camera.look_at(focus, Vector3.UP)
	camera.size = view_size


func ground_at(screen: Vector2) -> Variant:
	if not screen.is_finite():
		return null
	var ray := camera.project_ray_normal(screen)
	if absf(ray.y) < 0.0001:
		return null
	var origin := camera.project_ray_origin(screen)
	var distance := -origin.y / ray.y
	if distance < 0.0:
		return null
	return origin + ray * distance


func pan_between(from: Vector2, to: Vector2) -> void:
	var before: Variant = ground_at(from)
	var after: Variant = ground_at(to)
	if before is Vector3 and after is Vector3:
		focus += before - after
		apply_pose()


func zoom_at(screen: Vector2, factor: float) -> void:
	if not is_finite(factor) or factor <= 0.0:
		return
	var anchor: Variant = ground_at(screen)
	view_size /= factor
	apply_pose()
	var moved: Variant = ground_at(screen)
	if anchor is Vector3 and moved is Vector3:
		focus += anchor - moved
		apply_pose()


func project_logic(pos: Vector2, height: float = 0.0) -> Vector2:
	return camera.unproject_position(Space.logic_to_world(pos, height))
