extends SceneTree

## M1-A checks that terrain metadata is additive and that legacy geometry stays
## unchanged until a level explicitly opts into height-aware behavior.

const GridScript := preload("res://scripts/grid.gd")
const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var grid = GridScript.new()
	var from := grid.cell_to_world_center(Vector2i(7, 9))
	var to := grid.cell_to_world_center(Vector2i(12, 9))
	if not grid.is_blocked(8, 8) or grid.is_blocked(12, 8):
		_fail("M1_LEGACY_BLOCKED_BASELINE", 2)
		return
	if grid.has_los(from, to):
		_fail("M1_LEGACY_LOS_BASELINE", 3)
		return
	if grid.get_elevation_tier(12, 8) != GridScript.HEIGHT_GROUND:
		_fail("M1_DEFAULT_GROUND_TIER", 4)
		return
	if grid.occlusion_height_at(8, 8) != GridScript.OCCLUSION_FULL_HEIGHT:
		_fail("M1_LEGACY_BLOCK_DEFAULTS_TO_FULL_OCCLUSION", 5)
		return
	if grid.occlusion_height_at(12, 8) != 0.0:
		_fail("M1_OPEN_CELL_DEFAULTS_TO_NO_OCCLUSION", 6)
		return

	if grid.set_elevation_tier(-1, 8, GridScript.HEIGHT_PLATFORM):
		_fail("M1_ELEVATION_REJECTS_OUT_OF_BOUNDS", 7)
		return
	if grid.set_elevation_tier(12, 8, 2):
		_fail("M1_ELEVATION_REJECTS_UNSUPPORTED_TIER", 8)
		return
	if grid.set_elevation_tier(8, 8, GridScript.HEIGHT_PLATFORM):
		_fail("M1_ELEVATION_REJECTS_BLOCKED_SURFACE", 8)
		return
	if not grid.set_elevation_tier(12, 8, GridScript.HEIGHT_PLATFORM):
		_fail("M1_ELEVATION_ACCEPTS_PLATFORM", 9)
		return
	if grid.set_occlusion_kind(8, 8, 4):
		_fail("M1_OCCLUSION_REJECTS_UNKNOWN_KIND", 10)
		return
	if not grid.set_occlusion_kind(8, 8, GridScript.OCCLUSION_LOW):
		_fail("M1_OCCLUSION_ACCEPTS_LOW", 11)
		return
	if not grid.is_blocked(8, 8) or grid.occlusion_height_at(8, 8) != GridScript.OCCLUSION_LOW_HEIGHT:
		_fail("M1_LOW_OCCLUSION_DOES_NOT_CHANGE_WALKABILITY", 12)
		return
	if grid.has_los(from, to):
		_fail("M1_METADATA_DOES_NOT_CHANGE_LEGACY_LOS", 12)
		return

	var ground := Vector2i(12, 9)
	var platform := Vector2i(12, 8)
	if grid.can_traverse_height(platform, ground):
		_fail("M1_HEIGHT_CHANGE_REQUIRES_RAMP", 13)
		return
	if not grid.set_ramp_link(platform, ground):
		_fail("M1_ADJACENT_RAMP_ACCEPTED", 14)
		return
	if grid.set_ramp_link(Vector2i(8, 8), Vector2i(8, 9)):
		_fail("M1_RAMP_REJECTS_BLOCKED_ENDPOINT", 14)
		return
	if not grid.can_traverse_height(platform, ground) or not grid.can_traverse_height(ground, platform):
		_fail("M1_RAMP_IS_BIDIRECTIONAL", 15)
		return
	if grid.set_ramp_link(Vector2i(12, 8), Vector2i(14, 8)):
		_fail("M1_RAMP_REJECTS_NON_ADJACENT_LINK", 16)
		return

	grid.rebuild("yard")
	if grid.get_elevation_tier(12, 8) != GridScript.HEIGHT_GROUND or grid.has_ramp_link(platform, ground):
		_fail("M1_REBUILD_CLEARS_ADDITIVE_TERRAIN", 17)
		return
	if not grid.is_blocked(8, 8) or grid.has_los(from, to):
		_fail("M1_REBUILD_PRESERVES_LEGACY_GEOMETRY", 18)
		return

	print("M1_HEIGHT_DATA_GATE_OK legacy=1 bounds=1 low=1 ramp=1 rebuild=1")
	quit(0)


func _fail(marker: String, code: int) -> void:
	push_error(marker)
	quit(code)
