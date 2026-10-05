extends SceneTree
## Controlled historical consumer / real Window geometry, never a fresh win.
const Guard := preload("res://scripts/test_storage_guard.gd")
const RECORD_SHA := "28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266"
const FIELDS := ["attempt_id", "events", "snapshots", "terminal_tick", "terminal_reason", "playback_schema", "playback_snapshots", "playback_terminal_tick"]
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var rows: Array = []
var sample := ""

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("EVENT_LOG_LAYOUT: " + sample + " " + label)

func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func _settle() -> void:
	for _i in 6:
		await process_frame

func _record_hash() -> String:
	var data := {}
	for field: String in FIELDS:
		data[field] = main.battle_log.get(field)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes(data))
	return hash.finish().hex_encode()

func _mouse(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await _settle()

func _run() -> void:
	var path := OS.get_environment("AMBUSH_TEST_RECORD")
	if path.is_empty() or FileAccess.get_sha256(path) != RECORD_SHA:
		_check(false, "requires unchanged original warehouse record")
		quit(2)
		return
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var history := BattleLog.new()
	for field: String in FIELDS:
		history.set(field, raw[field])
	var settings := root.get_node("GameSettings")
	settings.pending_level_id = "warehouse"
	settings.mark_tutorial_seen("warehouse")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await _settle()
	main = current_scene
	view = main.presentation_3d
	if view == null:
		_check(false, "3D presenter fixture required")
		quit(2)
		return
	main.battle_log = history
	main.phase = main.Phase.WON # Explicit cold replay fixture; no natural win.
	main._on_replay_pressed()
	main.replay.pause()
	main._toggle_event_log()
	var domain: Dictionary = main._snapshot_data().duplicate(true)
	for spec in [[1280, 720, 1.0, false], [1280, 720, 1.0, true], [1280, 720, 2.0, false], [1280, 720, 2.0, true], [1600, 900, 2.0, true], [960, 540, 1.0, true]]:
		sample = "%d_%d_%d_%s" % [spec[0], spec[1], int(spec[2]*100), spec[3]]
		root.size = Vector2i(spec[0], spec[1])
		root.position = Vector2i.ZERO
		root.content_scale_factor = spec[2]
		settings.set_force_touch_hud(spec[3])
		main.replay.set_tick(10788)
		main._apply_replay_scrub()
		main._update_hud()
		view.refresh()
		await _settle()
		if main._compact_hud() and not view._camera_panel.is_visible_in_tree():
			await _mouse(view._camera_toggle.get_global_rect().get_center())
		var list_rect: Rect2 = main.event_list.get_global_rect()
		var camera: Rect2 = view._camera_panel.get_global_rect()
		var usable: Rect2 = root.get_visible_rect()
		_check(main.event_log.is_visible_in_tree() and main.event_list.is_visible_in_tree(), "original log remains visible")
		_check(view._camera_panel.is_visible_in_tree(), "camera palette remains available alongside log")
		_check(usable.grow(0.5).encloses(list_rect), "whole log viewport fits usable viewport")
		_check(usable.grow(0.5).encloses(camera), "whole camera palette fits usable viewport")
		_check(not list_rect.grow(-0.5).intersects(camera.grow(-0.5)), "camera and log hit areas are disjoint")
		var points: Array = []
		for fraction in [0.05, 0.5, 0.95]:
			main.replay.set_tick(10788)
			main._apply_replay_scrub()
			await _settle()
			var list: ItemList = main.event_list
			var found := false
			for index in list.item_count:
				var ev: Dictionary = main._event_list_items[index]
				if ev.type != "fire":
					continue
				var ir := list.get_item_rect(index)
				var local := Vector2(ir.position.x + ir.size.x * fraction, ir.get_center().y - list.get_v_scroll_bar().value)
				var at := list.global_position + local
				if not list.get_global_rect().has_point(at) or list.get_item_at_position(local, true) != index:
					continue
				var angles := Vector2(view.rig.yaw_deg, view.rig.pitch_deg)
				await _mouse(at)
				_check(main.replay.scrub_tick == int(ev.playback_tick) and not main.replay.playing, "original left/center/right item click seeks exact saved event")
				_check(main.replay_focus_actor == int(ev.actor_id) and main.replay_focus_type == "fire" and view._event_ring.visible, "original item click focuses historical actor")
				_check(angles == Vector2(view.rig.yaw_deg, view.rig.pitch_deg), "log click never rotates/tilts camera")
				points.append({"fraction":fraction, "point":[at.x, at.y], "event_id":ev.event_id, "tick":main.replay.scrub_tick})
				found = true
				break
			_check(found, "visible fire row available for each hit position")
		_check(_record_hash() == RECORD_SHA and main._snapshot_data() == domain, "layout/input keeps original record and simulation state")
		var output := {"sample":sample, "display":DisplayServer.get_name(), "window":[root.size.x, root.size.y], "scale":root.content_scale_factor, "usable":_rect(usable), "log":_rect(list_rect), "camera":_rect(camera), "points":points}
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position, root.size))
			var image_path := "res://build/asset_review/pr15-runtime/event_log_"+sample+".png"
			_check(image.save_png(image_path) == OK, "actual Window capture saved")
			output["capture"] = image_path
			output["capture_sha256"] = FileAccess.get_sha256(image_path)
		rows.append(output)
	var dir := "res://build/asset_review/pr15-runtime"
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir+"/event-log-layout-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"controlled historical consumer, no fresh producer; synthetic viewport mouse routing, not trusted native/Web input", "checks":checks, "failures":failures, "rows":rows}, "  "))
	print("EVENT_LOG_LAYOUT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
