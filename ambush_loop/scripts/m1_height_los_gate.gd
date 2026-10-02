extends SceneTree

const GridScript := preload("res://scripts/grid.gd")
const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
var failures: PackedStringArray = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _expect(value: bool, marker: String) -> void:
	if not value:
		failures.append(marker)
		push_error(marker)


func _run() -> void:
	var grid = GridScript.new()
	grid.blocked.fill(0)
	grid.elevation_tier.fill(GridScript.HEIGHT_GROUND)
	grid.occlusion_kind.fill(GridScript.OCCLUSION_INHERIT)
	grid.ramp_links.clear()
	var a := Vector2i(6, 6)
	var b := Vector2i(10, 6)
	var from: Vector2 = grid.cell_to_world_center(a)
	var to: Vector2 = grid.cell_to_world_center(b)
	_expect(grid.has_height_los(from, to) and grid.has_los(from, to), "M1C_OPEN_FLAT_COMPATIBLE")
	_expect(grid.has_height_los(from, from), "M1C_VALID_SAME_CELL")
	grid.set_blocked(8, 6, true)
	_expect(grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_LOW), "M1C_LOW_FIXTURE")
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(to, from), "M1C_GROUND_LOW_BLOCKED")
	_expect(not grid.has_los(from, to), "M1C_LEGACY_QUERY_UNCHANGED_LOW")
	_expect(grid.set_elevation_tier(a.x, a.y, GridScript.HEIGHT_PLATFORM), "M1C_PLATFORM_A")
	_expect(grid.set_elevation_tier(b.x, b.y, GridScript.HEIGHT_PLATFORM), "M1C_PLATFORM_B")
	_expect(grid.has_height_los(from, to) and grid.has_height_los(to, from), "M1C_PLATFORM_LOW_CLEAR")
	_expect(not grid.has_los(from, to), "M1C_LEGACY_QUERY_UNCHANGED_HIGH")
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_FULL)
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(to, from), "M1C_FULL_BLOCKS_HIGH")
	grid.set_blocked(8, 6, false)
	_expect(not grid.has_height_los(from, to), "M1C_EXPLICIT_FULL_INDEPENDENT_OF_COLLISION")
	grid.set_blocked(8, 6, true)
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_INHERIT)
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(to, from), "M1C_LEGACY_FULL")
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_NONE)
	_expect(grid.has_height_los(from, to) and grid.is_blocked(8, 6), "M1C_NONE_DOES_NOT_CHANGE_WALKABILITY")
	grid.set_blocked(8, 6, false)
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_LOW)
	grid.set_elevation_tier(b.x, b.y, GridScript.HEIGHT_GROUND)
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(to, from), "M1C_CONTACT_AT_LOW_TOP_BLOCKS")
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_NONE)
	grid.set_occlusion_kind(7, 6, GridScript.OCCLUSION_LOW)
	_expect(grid.has_height_los(from, to) and grid.has_height_los(to, from), "M1C_INTERPOLATED_NEAR_HIGH_CLEAR")
	grid.set_occlusion_kind(7, 6, GridScript.OCCLUSION_NONE)
	grid.set_occlusion_kind(9, 6, GridScript.OCCLUSION_LOW)
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(to, from), "M1C_INTERPOLATED_NEAR_LOW_BLOCKED")
	# Sweep diagonal tie cases and endpoint tiers to catch directional rasterization.
	for tier in [GridScript.HEIGHT_GROUND, GridScript.HEIGHT_PLATFORM]:
		grid.set_elevation_tier(a.x, a.y, tier)
		for y in range(5, 12):
			var endpoint: Vector2 = grid.cell_to_world_center(Vector2i(12, y))
			grid.set_elevation_tier(12, y, tier)
			_expect(grid.has_height_los(from, endpoint) == grid.has_height_los(endpoint, from), "M1C_REVERSE_SYMMETRIC_%s_%s" % [tier, y])
	grid.occlusion_kind.fill(GridScript.OCCLUSION_NONE)
	_expect(grid.has_height_los(from, to), "M1C_FAIL_CLOSED_FIXTURE_CLEAR")
	_expect(not grid.has_height_los(Vector2(-0.1, 1), to), "M1C_NEGATIVE_SUBCELL_FAIL_CLOSED")
	_expect(not grid.has_height_los(from, Vector2(GridScript.COLS * GridScript.TILE, 1)), "M1C_OUT_OF_BOUNDS_FAIL_CLOSED")
	_expect(not grid.has_height_los(Vector2(NAN, 1), to), "M1C_NAN_FAIL_CLOSED")
	_expect(not grid.has_height_los(from, Vector2(INF, 1)), "M1C_INF_FAIL_CLOSED")
	grid.set_blocked(a.x, a.y, true)
	_expect(not grid.has_height_los(from, to) and not grid.has_height_los(from, from), "M1C_BLOCKED_ENDPOINT_FAIL_CLOSED")
	grid.set_blocked(a.x, a.y, false)
	grid.elevation_tier[grid.idx(a.x, a.y)] = 2
	_expect(not grid.has_height_los(from, to), "M1C_INVALID_TIER_FAIL_CLOSED")
	grid.elevation_tier[grid.idx(a.x, a.y)] = GridScript.HEIGHT_GROUND
	_expect(grid.has_height_los(from, to), "M1C_INVALID_OCCLUSION_FIXTURE_CLEAR")
	grid.occlusion_kind[grid.idx(8, 6)] = 255
	_expect(not grid.has_height_los(from, to), "M1C_INVALID_OCCLUSION_FAIL_CLOSED")
	grid.occlusion_kind[grid.idx(8, 6)] = GridScript.OCCLUSION_NONE
	_expect(grid.has_height_los(from, to), "M1C_INVALID_OCCLUSION_RECOVERY")
	if not failures.is_empty():
		quit(2)
		return
	print("M1_HEIGHT_LOS_GATE_OK ground_low_blocked=1 platform_low_clear=1 full_blocks_high=1 reverse_symmetric=1 legacy_full=1 fail_closed=1 interpolation=1 legacy_query_unchanged=1")
	quit(0)
