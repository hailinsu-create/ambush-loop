extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const GridScript := preload("res://scripts/grid.gd")
const ReplayScript := preload("res://scripts/replay/replay_player.gd")
var failures: PackedStringArray = []
var fired_count := 0
var return_count := 0


func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")


func _expect(value: bool, marker: String) -> void:
	if not value:
		failures.append(marker)
		push_error(marker)


func _run() -> void:
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		quit(2)
		return
	for _i in 14:
		await process_frame
	var main = current_scene
	main.set_process(false)
	var grid = main.grid
	grid.blocked.fill(0)
	grid.elevation_tier.fill(GridScript.HEIGHT_GROUND)
	grid.occlusion_kind.fill(GridScript.OCCLUSION_INHERIT)
	grid.ramp_links.clear()
	for unit in main.operators:
		unit.visible = false
	var op: OperatorUnit = main.operators[0]
	op.visible = true
	op.set_process(false)
	op.slot = null
	op.apply_weapon("rifle", true)
	op.global_position = grid.cell_to_world_center(Vector2i(6, 6))
	op.facing_deg = 0.0
	op.fire_permitted = true
	var enemy: EnemyRunner = main._make_enemy(99)
	main.entities.add_child(enemy)
	enemy.setup(99, PackedVector2Array(), grid)
	enemy.global_position = grid.cell_to_world_center(Vector2i(10, 6))
	# A finite authored-path remainder is required by production target priority.
	# Empty routes return INF and are intentionally never selected for friendly fire.
	enemy.route = PackedVector2Array([enemy.global_position])
	enemy.route_index = 1
	enemy.active = true
	enemy.set_process(false)
	main.enemies.clear()
	main.enemies.append(enemy)
	enemy.return_fired.connect(main._on_return_fired)
	op.fired_shot.connect(func(_o, _p): fired_count += 1)
	enemy.return_fired.connect(func(_e, _o): return_count += 1)
	main.pending_spawns.clear()
	main.tripwires.clear()
	main.barrels.clear()
	main.escape_world = Vector2(1200, 650)
	main.phase = main.Phase.WATCHING
	grid.set_blocked(8, 6, true)
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_LOW)
	var target := enemy.global_position
	var initial_ammo := op.ammo
	var initial_hp := enemy.hp
	_expect(not op.in_fire_geometry(target, grid), "C2_GROUND_TARGET_PREVIEW_DENIED")
	_expect(op.engage_block_reason(target, grid) == "los" and not op.can_engage(target, grid), "C2_GROUND_ELIGIBILITY_DENIED")
	_expect(not op.try_fire(enemy, grid), "C2_GROUND_TRY_FIRE_DENIED")
	_expect(op.ammo == initial_ammo and enemy.hp == initial_hp and fired_count == 0, "C2_DENIED_NO_SIDE_EFFECTS")
	# Real production simulation creates the authoritative BattleLog events.
	enemy.alerted = true
	enemy.focus_target = op
	main.battle_log.clear()
	main._sim_tick()
	_expect(main.battle_log.first_of_type("fire").is_empty() and main.battle_log.first_of_type("return_fire").is_empty(), "C2_GROUND_NO_RECORDED_SHOTS")
	_expect(op.hp == OperatorUnit.MAX_HP and return_count == 0, "C2_GROUND_RETURN_DENIED")
	grid.set_elevation_tier(6, 6, GridScript.HEIGHT_PLATFORM)
	grid.set_elevation_tier(10, 6, GridScript.HEIGHT_PLATFORM)
	_expect(op.in_fire_geometry(target, grid) and op.can_engage(target, grid), "C2_HIGH_TARGET_PREVIEW_AND_AUTHORITY")
	# Legacy wedge cannot encode different target tiers: deliberately NOT parity.
	var clipped := op._los_clip_distance(Vector2.RIGHT)
	_expect(clipped > 0.0 and clipped < op.global_position.distance_to(target), "C2_LEGACY_CONE_NON_AUTHORITATIVE")
	_expect(not op.in_fire_sector(target), "C2_TOOL_SECTOR_LEGACY")
	_expect(op._obs_clip_distance(Vector2.RIGHT, op.range_px) < op.global_position.distance_to(target), "C2_OBSERVATION_LEGACY")
	_expect(not grid.has_los(target, op.global_position), "C2_NONFIRE_GEOMETRY_LEGACY")
	main.battle_log.clear()
	var before_op_hp := op.hp
	var damage := op.damage_per_shot
	main._sim_tick()
	_expect(fired_count == 1 and op.ammo == initial_ammo - 1 and is_equal_approx(enemy.hp, initial_hp - damage), "C2_HIGH_NORMAL_SHOT_AND_DAMAGE")
	_expect(return_count == 1 and is_equal_approx(op.hp, before_op_hp - EnemyRunner.RETURN_DAMAGE), "C2_HIGH_NORMAL_RETURN_DAMAGE")
	_expect(not main.battle_log.first_of_type("fire").is_empty() and not main.battle_log.first_of_type("return_fire").is_empty(), "C2_REAL_RECORDED_SHOTS")
	var replay = ReplayScript.new()
	replay.bind(main.battle_log)
	var recorded_events: Array = main.battle_log.events.duplicate(true)
	var recorded_hp := op.hp
	var recorded_ammo := op.ammo
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_FULL)
	_expect(replay.events_up_to(main.sim.tick) == recorded_events, "C2_REPLAY_EVENTS_NOT_RESIMULATED")
	_expect(op.hp == recorded_hp and op.ammo == recorded_ammo, "C2_REPLAY_READ_ONLY")
	op.shot_cd = 0.0
	enemy.return_cd = 0.0
	main.battle_log.clear()
	main._sim_tick()
	_expect(op.engage_block_reason(target, grid) == "los" and not op.in_fire_geometry(target, grid), "C2_FULL_HIGH_DENIED")
	_expect(main.battle_log.first_of_type("fire").is_empty() and main.battle_log.first_of_type("return_fire").is_empty(), "C2_FULL_NO_RECORDED_SHOTS")
	_expect(fired_count == 1 and return_count == 1 and op.ammo == recorded_ammo and op.hp == recorded_hp, "C2_FULL_NO_SIDE_EFFECTS")
	grid.set_occlusion_kind(8, 6, GridScript.OCCLUSION_LOW)
	var saved_range := op.range_px
	op.range_px = 100.0
	_expect(op.engage_block_reason(target, grid) == "range" and not op.in_fire_geometry(target, grid), "C2_RANGE_STILL_REQUIRED")
	op.range_px = saved_range
	op.facing_deg = 180.0
	_expect(op.engage_block_reason(target, grid) == "cone", "C2_FACING_STILL_REQUIRED")
	op.facing_deg = 0.0
	op.fire_permitted = false
	_expect(op.engage_block_reason(target, grid) == "hold", "C2_HOLD_STILL_REQUIRED")
	op.fire_permitted = true
	op.ammo = 0
	_expect(op.engage_block_reason(target, grid) == "ammo", "C2_AMMO_STILL_REQUIRED")
	op.ammo = recorded_ammo
	op.melee = true
	# Preserve range to isolate LOS, rather than obtaining a vacuous knife-range denial.
	_expect(op.engage_block_reason(target, grid) == "los" and not op.in_fire_geometry(target, grid), "C2_MELEE_LEGACY_LOS")
	grid.set_blocked(8, 6, false)
	_expect(op.can_engage(target, grid) and op.in_fire_geometry(target, grid), "C2_MELEE_OPEN_POSITIVE")
	op.melee = false
	op.grid = null
	_expect(not op.in_fire_geometry(target, null) and op.engage_block_reason(target, null) == "los", "C2_FRIENDLY_NO_GRID_FAIL_CLOSED")
	enemy.grid = null
	enemy.return_cd = 0.0
	enemy._try_return_fire()
	_expect(return_count == 1, "C2_ENEMY_NO_GRID_FAIL_CLOSED")
	if not failures.is_empty():
		quit(2)
		return
	print("M1_HEIGHT_FIRE_GATE_OK height_fire_authority=1 friendly_low_blocked=1 friendly_high_clear=1 enemy_low_blocked=1 enemy_high_clear=1 full_blocks_high=1 target_preview_matches=1 cone_non_authoritative=1 replay_event_source=1 damage_unchanged=1 range_unchanged=1 melee_legacy=1 nonfire_los_unchanged=1")
	quit(0)
