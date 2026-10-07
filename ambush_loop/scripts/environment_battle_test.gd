extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const EnvironmentScene := preload("res://scripts/presentation/environment_scene.gd")
const EnvironmentVisual := preload("res://scripts/presentation/environment_visual.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Picker := preload("res://scripts/presentation/world_picker_3d.gd")
const CASES := preload("res://scripts/campaign_replay_test.gd").CASES
var checks := 0
var failures := 0
var captures: Array = []
var levels: Array = []


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ENVIRONMENT_BATTLE: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for case in CASES:
		settings.mark_tutorial_seen(case[0])
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	await _stash_contract(main)
	if OS.get_environment("AMBUSH_ENV_TEST_SCOPE") == "crate_only":
		root.get_node("AudioDirector").pause_for_background()
		print("ENVIRONMENT_CRATE_VISUAL_OK" if failures == 0 else "ENVIRONMENT_CRATE_VISUAL_FAILED", " checks=", checks, " failures=", failures)
		quit(0 if failures == 0 else 1)
		return
	for case in CASES:
		await _journey(main, case)
	root.get_node("AudioDirector").pause_for_background()
	var proof := {"checks": checks, "failures": failures, "levels": levels, "captures": captures,
		"rendering": DisplayServer.get_name(), "environment_revision": EnvironmentScene.REVISION,
		"scope": "actual 6 levels / 13 authored waves; ref equipment and loot-vacuum fixture, cloud rendering only"}
	var file := FileAccess.open("res://build/environment_battle_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(proof, "\t"))
	file.close()
	print("ENVIRONMENT_BATTLE_OK" if failures == 0 else "ENVIRONMENT_BATTLE_FAILED", " checks=", checks,
		" failures=", failures, " levels=", levels.size(), " captures=", captures.size())
	quit(0 if failures == 0 else 1)


func _stash_contract(main: Node) -> void:
	var stash = main.raid_stashes.front()
	var op: OperatorUnit = main.operators[0]
	# Explicit same-cell search fixture; the real search/take/backpack handlers
	# run unchanged. This is not a pathfinding or physical touch-pickup proof.
	op.global_position = stash.global_position
	main._tick_crate_search(0.2)
	main.presentation_3d.refresh()
	var partial: Dictionary = main._snapshot_data().duplicate(true)
	_check(EnvironmentScene.supported(partial), "current terrain assembly supported")
	var legacy := partial.duplicate(true)
	legacy.environment_layout_revision = EnvironmentScene.LEGACY_LAYOUT_REVISION
	_check(EnvironmentScene.supported(legacy), "original terrain assembly remains supported")
	var legacy_scene := EnvironmentScene.new()
	root.add_child(legacy_scene)
	legacy_scene.build(legacy, 0)
	_check(legacy_scene.get_meta("environment_layout_revision") == EnvironmentScene.LEGACY_LAYOUT_REVISION, "historical assembly identity not rewritten")
	legacy_scene.queue_free()
	legacy.environment_layout_revision = "unknown_terrain_assembly"
	_check(not EnvironmentScene.supported(legacy), "unknown terrain assembly fails closed")
	var recorded: Array = partial.stashes.filter(func(item: Dictionary) -> bool: return item.pos == stash.global_position)
	_check(recorded.size() == 1 and is_equal_approx(float(recorded[0].progress), 0.5), "actual half-search progress copied")
	var key: String = "stashes:" + recorded[0].id
	var visual := main.presentation_3d.objects[key].get_node("EnvironmentVisual") as EnvironmentVisual
	_check(visual != null and visual.pivot != null and visual.pivot.rotation_degrees.x > 45.0, "actual imported crate lid opens at real progress")
	main.presentation_3d.rig.focus = Space.logic_to_world(stash.global_position)
	await _capture(main, "yard_search_half", 35, 55, 12)
	main._tick_crate_search(0.2)
	main.presentation_3d.refresh()
	var empty: Dictionary = main._snapshot_data().duplicate(true)
	_check(stash.collected and empty.environment_objects.size() == 1 and empty.environment_objects[0].progress == 1.0, "actual take retains one copied empty crate")
	var empty_item: Dictionary = empty.environment_objects[0]
	var display := main.presentation_3d.objects["environment_objects:" + empty_item.id].get_node("EnvironmentVisual") as EnvironmentVisual
	_check(display != null and display.pivot.rotation_degrees.x >= 99.0, "collected crate uses imported open lid")
	var hit := Picker.pick(main.presentation_3d.rig.camera, main.presentation_3d.rig.project_logic(empty_item.pos, 0.2), {"blocked": empty.blocked, "environment_objects": empty.environment_objects})
	_check(hit.get("kind", "") == "ground" and hit.get("id", -1) == -1, "decorative empty crate is not an interactive pick target")
	await process_frame
	_check(empty.environment_objects[0].pos == empty_item.pos and not is_instance_valid(stash), "plain empty-crate record outlives queued source node")
	await _capture(main, "yard_search_empty", 35, 55, 12)
	var log := BattleLog.new()
	log.snapshots = [{"tick": 0, "data": partial}, {"tick": 1, "data": empty}]
	main.phase = main.Phase.REPLAY
	main.replay.bind(log)
	for tick in [1, 0, 1]:
		main.replay.set_tick(tick)
		main.presentation_3d.refresh()
		_check(main.presentation_3d.frame.environment_objects.size() == (1 if tick == 1 else 0), "historical crate lifetime resolves forward/backward")
	main.phase = main.Phase.SETUP


func _journey(main: Node, case: Array) -> void:
	main._load_level(case[0], false, false)
	await process_frame
	main.raid_prepare_ref(case[1], case[2])
	if case[0] == "warehouse":
		main._play_hold_pack(1)
	if case[0] in ["depot", "radio"]:
		main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7, 11)))
	var view = main.presentation_3d
	view.rig.reset_view()
	view.refresh()
	_check(view.frame.environment_supported and view._environment_scene != null, case[0] + " actual SCOUT uses accepted environment")
	_check(view._environment_scene.get_meta("theme") == case[0] and view._environment_scene.get_meta("recorded_layout_hash") == hash(main.grid.blocked), "actual scene assembled from copied authored grid")
	_check(_find_asset(view.geometry, EnvironmentScene.LANDMARKS[case[0]]) != null, "actual theme landmark present")
	_check(_visual_only(view.geometry), "environment has no collision/navigation/simulation nodes")
	_check(view.frame.environment_objects.is_empty(), "retry/level reset removes old decorative empties")
	var layout: PackedByteArray = main.grid.blocked.duplicate()
	await _capture(main, case[0] + "_scout", 35, 55)
	if view.frame.has_door:
		main._on_door_pressed()
		view.refresh()
		_check(is_equal_approx(view._environment_scene.door_leaf.rotation_degrees.y, 0.0), "actual locked door closes imported leaf")
		main._on_door_pressed()
		view.refresh()
		_check(is_equal_approx(view._environment_scene.door_leaf.rotation_degrees.y, -90.0), "actual open door rotates imported leaf")
	main.raid_force_alarm()
	view.refresh()
	await _capture(main, case[0] + "_alert", 35, 55)
	var wave_ticks := []
	for wave in main.level.wave_count():
		var ticks := 0
		while main.phase == main.Phase.WATCHING and ticks < 12000:
			main._sim_tick()
			ticks += 1
		_check(main.phase == main.Phase.SWEEP, case[0] + " actual wave %d clears" % wave)
		if main.phase != main.Phase.SWEEP:
			levels.append({"level": case[0], "failed_wave": wave, "reason": main.fail_reason})
			return
		wave_ticks.append(main.sim.tick)
		view.refresh()
		_check(view.frame.blocked == main.grid.blocked and view.frame.environment_supported, "actual SWEEP retains authored layout and revision")
		if wave == 0:
			for yaw in [0, 90, 180, 270]:
				await _capture(main, case[0] + "_sweep_low_yaw%d" % yaw, yaw, 35)
				_occlusion_contract(view)
			await _capture(main, case[0] + "_sweep_high", 35, 65)
			var near_signature: int = _geometry_signature(view.geometry)
			view.rig.view_size = 30
			view.rig.apply_pose()
			view.refresh()
			_check(view._environment_lod == 1 and _all_lod(view.geometry, 1), "actual zoom selects imported environment LOD1")
			view.rig.view_size = 18
			view.rig.apply_pose()
			view.refresh()
			_check(view._environment_lod == 0 and _all_lod(view.geometry, 0) and near_signature == _geometry_signature(view.geometry), "return zoom restores deterministic LOD0 assembly")
		main.raid_vacuum_loot() # same explicit authored-loot fixture as campaign regression.
		main._on_sweep_commit()
	_check(main.phase == main.Phase.WON and main.raid.waves_cleared == main.level.wave_count(), case[0] + " complete authored multi-wave extraction")
	var snapshots: Array = main.battle_log.snapshots.duplicate(true)
	var events: Array = main.battle_log.events.duplicate(true)
	main._on_replay_pressed()
	var live: Dictionary = main._snapshot_data().duplicate(true)
	var live_level_id: String = main.level.level_id
	main.grid.blocked.fill(0) # deliberately poisoned live grid: history must not borrow it.
	main.level.level_id = "live-only-level"
	main.door_locked = not main.door_locked
	var poisoned: Dictionary = main._snapshot_data().duplicate(true)
	var historic_signature := 0
	for snap in [snapshots.front(), snapshots.back(), snapshots.front()]:
		main.replay.set_tick(BattleLog.record_tick(snap))
		main._apply_replay_scrub()
		view.rig.view_size = 24
		view.rig.apply_pose()
		view.refresh()
		_check(view.frame.environment_supported and view.frame.level_id == case[0] and view.frame.blocked == snap.data.blocked, "actual history retains its own environment and grid")
		_check(view._environment_scene.get_meta("recorded_layout_hash") == hash(snap.data.blocked), "actual history geometry ignores poisoned live grid")
		_check(main._snapshot_data() == poisoned, "environment rendering never mutates live state")
		var signature: int = _geometry_signature(view.geometry)
		if historic_signature == 0:
			historic_signature = signature
		else:
			_check(signature == historic_signature, "forward/backward history recreates exact static assembly")
	_check(main.battle_log.snapshots == snapshots and main.battle_log.events == events, "environment cannot rewrite source records/events")
	await _capture(main, case[0] + "_history", 35, 55)
	_compatibility(main, snapshots.front())
	main.grid.blocked = live.blocked.duplicate()
	main.level.level_id = live_level_id
	main.door_locked = live.door_locked
	levels.append({"level": case[0], "waves": wave_ticks.size(), "local_wave_ticks": wave_ticks,
		"terminal_tick": main.battle_log.terminal_tick, "events": events.size(), "blocked_cells": layout.count(1)})
	print("ENVIRONMENT_BATTLE_LEVEL ", case[0], " waves=", wave_ticks.size(), " terminal=", main.battle_log.terminal_tick, " events=", events.size())


func _compatibility(main: Node, source: Dictionary) -> void:
	var log := BattleLog.new()
	log.snapshots = [source.duplicate(true)]
	for key in ["environment_schema", "environment_revision", "environment_layout_revision", "environment_objects"]:
		log.snapshots[0].data.erase(key)
	main.replay.bind(log)
	main.presentation_3d.refresh()
	_check(not main.presentation_3d.frame.environment_supported and main.presentation_3d._environment_scene == null, "old complete record retains original graybox environment")
	_check(main.presentation_3d.frame.blocked == source.data.blocked, "legacy fallback uses recorded grid")
	log.snapshots[0].data.environment_schema = 1
	log.snapshots[0].data.environment_revision = "unknown-environment"
	log.snapshots[0].data.environment_layout_revision = EnvironmentScene.LAYOUT_REVISION
	var retained: Array = log.snapshots.duplicate(true)
	main.replay.bind(log)
	main.presentation_3d.refresh()
	_check(not main.presentation_3d.frame.environment_supported and main.presentation_3d._environment_scene == null, "unknown environment revision cannot borrow accepted live assets")
	_check(log.snapshots == retained, "unknown environment recording stays intact")
	log.snapshots[0].data.environment_revision = EnvironmentScene.REVISION
	log.snapshots[0].data.environment_layout_revision = "unknown-layout"
	main.replay.bind(log)
	main.presentation_3d.refresh()
	_check(not main.presentation_3d.frame.environment_supported and main.presentation_3d._environment_scene == null, "unknown layout version cannot acquire current assembly")


func _capture(main: Node, name: String, yaw: float, pitch: float, size: float = 24) -> void:
	var view = main.presentation_3d
	view.rig.yaw_deg = yaw
	view.rig.pitch_deg = pitch
	view.rig.view_size = size
	view.rig.apply_pose()
	view.refresh()
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://build/asset_review/pr15-environment-battle"
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(name + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "actual framebuffer saved: " + name)
	captures.append({"path": path, "sha256": FileAccess.get_sha256(path), "phase": main.phase,
		"level": view.frame.level_id, "wave": view.frame.wave_id, "tick": view.frame.tick,
		"yaw": yaw, "pitch": pitch, "view_size": size,
		"draw_calls": root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"triangles": root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)})
	print("ENVIRONMENT_BATTLE_CAPTURE ", path)


func _occlusion_contract(view: Node) -> void:
	var targets := []
	for group in ["ops", "enemies", "sentries", "loot"]:
		for item in view.frame[group]:
			if bool(item.get("active", true)):
				targets.append(Space.logic_to_world(item.pos, 0.12))
	for target: Vector3 in targets:
		var screen: Vector2 = view.rig.camera.unproject_position(target)
		if not root.get_visible_rect().has_point(screen):
			continue
		var origin: Vector3 = view.rig.camera.project_ray_origin(screen)
		for wall in view.walls:
			if wall.get("mode", "") == "hide" and wall.bounds.intersects_segment(origin, target) != null:
				_check(not wall.mesh.visible, "actual imported wall/roof cannot obscure actor/corpse/loot ground anchor")


func _find_asset(node: Node, id: String) -> Node:
	if node.get_meta("asset_id", "") == id:
		return node
	for child in node.get_children():
		var found := _find_asset(child, id)
		if found != null:
			return found
	return null


func _visual_only(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D or node is Node2D:
		return false
	for child in node.get_children():
		if not _visual_only(child):
			return false
	return true


func _all_lod(node: Node, lod: int) -> bool:
	if node.has_meta("asset_lod") and int(node.get_meta("asset_lod")) != lod:
		return false
	for child in node.get_children():
		if not _all_lod(child, lod):
			return false
	return true


func _geometry_signature(node: Node) -> int:
	var rows := []
	_signature_rows(node, rows)
	return hash(rows)


func _signature_rows(node: Node, rows: Array) -> void:
	if node.has_meta("asset_id"):
		rows.append([node.get_meta("asset_id"), node.get_meta("asset_lod"), node.transform])
	if node is MultiMeshInstance3D:
		for i in node.multimesh.instance_count:
			rows.append(node.multimesh.get_instance_transform(i))
	for child in node.get_children():
		_signature_rows(child, rows)
