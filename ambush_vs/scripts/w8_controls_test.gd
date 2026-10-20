extends SceneTree

## PLAY-UX controls acceptance (audit PR-1…5). Sim/golden untouched.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const GestureRouter := preload("res://view/gesture_router.gd")

var _failed := 0
var _passed := 0
var _fake_ms: int = 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_gesture_tap_on_release()
	_test_gesture_touch_mouse_dedupe()
	_test_gesture_drag_cancels_tap()
	_test_gesture_long_press()
	_test_gesture_drag_back_cancels()
	await _test_map_router_wired()
	await _test_selection_hit_and_portraits()
	await _test_wait_reaim_one_order()
	await _test_aim_snap_and_magnifier()
	await _test_setup_toolbar_and_trip()
	await _test_hud_touch_sizing()
	await _test_scout_path_preview()
	await _test_undo_cancel()
	await _test_climb_placement_feedback()
	await _test_climb_wait_status()
	await _test_climb_access_controls()
	await _test_climb_fractional_seconds()
	await _test_return_fire_assist_controls()
	await _test_camera_zoom_pan()
	await _test_info_card()
	await _test_desktop_shortcuts()
	await _test_briefing_and_phase_tips()
	await _test_hud_layout_no_overlap()
	await _test_phase_camera_frames_content()
	print("W8_CONTROLS_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _mk_router() -> GestureRouter:
	var r := GestureRouter.new()
	_fake_ms = 1000
	r.now_ms_fn = func(): return _fake_ms
	r.bounds = Rect2(0, 0, 800, 600)
	r.slop_px = GestureRouter.TAP_SLOP_PX
	return r


func _touch(pos: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = index
	return e


func _drag(pos: Vector2, relative: Vector2 = Vector2.ZERO, index: int = 0) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.position = pos
	e.relative = relative
	e.index = index
	return e


func _mouse(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	return e


func _test_gesture_tap_on_release() -> void:
	var r := _mk_router()
	var taps := []
	r.tapped.connect(func(p): taps.append(p))
	r.feed(_touch(Vector2(100, 100), true))
	_assert(taps.is_empty(), "no tap on press")
	r.feed(_touch(Vector2(100, 100), false))
	_assert(taps.size() == 1, "tap once on release got=%d" % taps.size())


func _test_gesture_touch_mouse_dedupe() -> void:
	var r := _mk_router()
	var taps := []
	r.tapped.connect(func(p): taps.append(p))
	# Real touch pair + synthetic mouse pair (emulate_mouse_from_touch).
	r.feed(_touch(Vector2(50, 50), true))
	r.feed(_mouse(Vector2(50, 50), true))
	r.feed(_touch(Vector2(50, 50), false))
	r.feed(_mouse(Vector2(50, 50), false))
	_assert(taps.size() == 1, "touch+mouse dedupe → 1 tap got=%d" % taps.size())


func _test_gesture_drag_cancels_tap() -> void:
	var r := _mk_router()
	var taps := []
	var box := {"drags": 0, "ended": 0}
	r.tapped.connect(func(p): taps.append(p))
	r.drag_started.connect(func(_a, _b): box["drags"] = int(box["drags"]) + 1)
	r.drag_ended.connect(func(_p, _s, _c): box["ended"] = int(box["ended"]) + 1)
	r.feed(_touch(Vector2(10, 10), true))
	r.inject_move(Vector2(10 + 40, 10))
	r.feed(_touch(Vector2(10 + 40, 10), false))
	_assert(taps.is_empty(), "drag 40px → no tap")
	_assert(int(box["drags"]) == 1, "drag started once got=%d" % box["drags"])
	_assert(int(box["ended"]) == 1, "drag ended once got=%d" % box["ended"])


func _test_gesture_long_press() -> void:
	var r := _mk_router()
	var taps := []
	var longs := []
	r.tapped.connect(func(p): taps.append(p))
	r.long_pressed.connect(func(p): longs.append(p))
	r.feed(_touch(Vector2(20, 20), true))
	_fake_ms = 1000 + GestureRouter.LONG_PRESS_MS + 10
	r.poll_long_press()
	r.feed(_touch(Vector2(20, 20), false))
	_assert(longs.size() == 1, "long_press once got=%d" % longs.size())
	_assert(taps.is_empty(), "long_press suppresses tap")


func _test_gesture_drag_back_cancels() -> void:
	var r := _mk_router()
	var box := {"cancelled": false, "ended": 0, "start_dist": -1.0}
	r.drag_ended.connect(func(p, s, c):
		box["cancelled"] = c
		box["ended"] = int(box["ended"]) + 1
		box["start_dist"] = p.distance_to(s)
	)
	r.feed(_touch(Vector2(100, 100), true))
	r.inject_move(Vector2(160, 100))
	_assert(r.state == GestureRouter.State.DRAGGING, "in DRAGGING before release")
	r.feed(_touch(Vector2(105, 100), false)) ## back within slop
	_assert(int(box["ended"]) == 1, "drag_ended fired got=%d" % box["ended"])
	_assert(bool(box["cancelled"]), "drag back near origin cancels dist=%s" % box["start_dist"])


func _test_map_router_wired() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "controls scene err=%s" % err)
	for _i in range(120):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		var map = scene.map_view
		_assert(map.gesture != null, "map has GestureRouter")
		map.tap_emit_count = 0
		var taps := {"n": 0}
		map.cell_tapped.connect(func(_c): taps["n"] = int(taps["n"]) + 1)
		# Empty cell tap via router (far from operators).
		var pos: Vector2 = map.cell_to_screen(2.0, 2.0)
		map.inject_input(_touch(pos, true))
		_assert(int(taps["n"]) == 0 and map.tap_emit_count == 0, "map no tap on press")
		map.inject_input(_touch(pos, false))
		_assert(map.tap_emit_count == 1, "map tap on release count=%d" % map.tap_emit_count)
		# Dedupe on map.
		map.tap_emit_count = 0
		var before: int = map.tap_emit_count
		map.inject_input(_touch(pos, true))
		map.inject_input(_mouse(pos, true))
		map.inject_input(_touch(pos, false))
		map.inject_input(_mouse(pos, false))
		_assert(map.tap_emit_count == before + 1, "map touch+mouse = 1 tap got=%d" % map.tap_emit_count)
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "greybox scene not ready for map router test")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_selection_hit_and_portraits() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "selection scene err=%s" % err)
	for _i in range(180):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		var map = scene.map_view
		_assert(is_equal_approx(float(map.unit_hit_radius_cells), 0.8), "hit radius 0.8")
		_assert(float(map.sel_ring_width) / maxf(float(map.unsel_ring_width), 0.01) >= 2.0 - 1e-6,
			"sel/unsel ring width ratio ≥2 got=%s/%s" % [map.sel_ring_width, map.unsel_ring_width])
		# Place first op, then tap 0.7 cells away → select, coords unchanged.
		var ops: Array = scene.plan.get("operators", [])
		_assert(ops.size() >= 1, "has operators")
		var oid := str(ops[0]["id"])
		scene.scripted_place_operator(oid, 5, 9, 0.0)
		_assert(str(scene.selected_op_id) == "", "scripted place clears selection")
		var ox := float(ops[0]["x"])
		var oy := float(ops[0]["y"])
		var tap_pos: Vector2 = map.cell_to_screen(ox + 0.7, oy)
		map.inject_input(_touch(tap_pos, true))
		map.inject_input(_touch(tap_pos, false))
		_assert(str(scene.selected_op_id) == oid, "select nearest within 0.8 cell")
		_assert(is_equal_approx(float(ops[0]["x"]), ox) and is_equal_approx(float(ops[0]["y"]), oy),
			"tap select does not move unit")
		var facing0 := float(ops[0]["facing_deg"])
		# Wobble <22 px must not change facing (tap, not drag).
		var center: Vector2 = map.cell_to_screen(ox, oy)
		map.inject_input(_touch(center, true))
		map.gesture.inject_move(center + Vector2(10, 0))
		map.inject_input(_touch(center + Vector2(10, 0), false))
		_assert(is_equal_approx(float(ops[0]["facing_deg"]), facing0), "wobble <22px does not change facing")
		# Portrait strip selects.
		_assert(scene.portrait_strip != null, "portrait strip exists")
		scene._on_portrait_pressed(oid)
		_assert(str(scene.selected_op_id) == oid, "portrait selects op")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "selection scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_setup_toolbar_and_trip() -> void:
	## PR-4: tool chips, trigger chips don't switch tool, trip one-drag, ghost place, entry-as-placed.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "toolbar scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		_assert(scene.tool_bar != null, "tool bar exists")
		_assert(scene.trigger_chip_row != null, "trigger chips exist")
		_assert(str(scene.setup_tool) == "op", "default tool op")
		_assert(scene.can_start_wait() == true, "entry-as-placed can start (see_first)")
		var tool_before := str(scene.setup_tool)
		scene._on_trigger_chip("mine_detonate")
		_assert(str(scene.setup_tool) == tool_before,
			"trigger chip does not switch tool got tool=%s" % scene.setup_tool)
		_assert(str(scene.plan.get("trigger", {}).get("type", "")) == "mine_detonate", "trigger type mine")
		# Mine tool: illegal cell no-op; legal places + returns to op.
		scene._on_tool_chip("mine")
		_assert(str(scene.setup_tool) == "mine", "tool chip mine")
		_assert(not scene.map_view.legal_cells.is_empty(), "mine legal highlights")
		var mines0: int = scene.plan.get("mines", []).size()
		scene._place_mine_at(Vector2i(0, 0)) ## wall / illegal
		_assert(scene.plan.get("mines", []).size() == mines0, "illegal mine cell no place")
		# Find a walkable cell.
		var wx := 8
		var wy := 4
		for y in range(scene.grid.height):
			for x in range(scene.grid.width):
				if scene.grid.walkable(x, y):
					wx = x
					wy = y
					break
		scene._on_tool_chip("mine")
		scene._place_mine_at(Vector2i(wx, wy))
		_assert(scene.plan.get("mines", []).size() == 1, "legal mine placed")
		_assert(str(scene.setup_tool) == "op", "mine place returns tool to op")
		# Trip line one drag (10,7)→(12,7); mid-drag trigger untouched.
		scene._on_tool_chip("trigger")
		_assert(str(scene.setup_tool) == "trigger", "tool chip trigger")
		var trig0: Dictionary = scene.plan.get("trigger", {}).duplicate(true)
		trig0.erase("a")
		trig0.erase("b")
		scene.plan["trigger"] = trig0
		var map = scene.map_view
		var a_pos: Vector2 = map.cell_to_screen(10.0, 7.0)
		var b_pos: Vector2 = map.cell_to_screen(12.0, 7.0)
		map.inject_input(_touch(a_pos, true))
		map.gesture.inject_move(a_pos + Vector2(30, 0))
		# Mid-drag: no a/b committed.
		_assert(not scene.plan.get("trigger", {}).has("a"), "trip mid-drag no a")
		_assert(not scene.plan.get("trigger", {}).has("b"), "trip mid-drag no b")
		map.gesture.inject_move(b_pos)
		map.inject_input(_touch(b_pos, false))
		var trig: Dictionary = scene.plan.get("trigger", {})
		_assert(trig.has("a") and trig.has("b"), "trip committed a/b")
		_assert(int(trig["a"]["x"]) == 10 and int(trig["a"]["y"]) == 7, "trip a=(10,7)")
		_assert(int(trig["b"]["x"]) == 12 and int(trig["b"]["y"]) == 7, "trip b=(12,7)")
		_assert(str(scene.setup_tool) == "op", "trip returns tool to op")
		# Ghost place: select → tap empty once → coords unchanged; second tap moves.
		var ops: Array = scene.plan.get("operators", [])
		var oid := str(ops[0]["id"])
		scene.selected_op_id = oid
		map.selected_op_id = oid
		var ox := int(ops[0]["x"])
		var oy := int(ops[0]["y"])
		var empty := Vector2i(6, 5)
		if not scene.grid.walkable(empty.x, empty.y):
			empty = Vector2i(wx, wy)
		# Avoid dropping on another operator.
		for opx in ops:
			if int(opx["x"]) == empty.x and int(opx["y"]) == empty.y:
				empty = Vector2i(7, 5)
		var epos: Vector2 = map.cell_to_screen(float(empty.x), float(empty.y))
		map.inject_input(_touch(epos, true))
		map.inject_input(_touch(epos, false))
		_assert(int(ops[0]["x"]) == ox and int(ops[0]["y"]) == oy, "ghost tap does not move")
		_assert(scene.pending_place_cell == empty, "ghost pending cell set")
		map.inject_input(_touch(epos, true))
		map.inject_input(_touch(epos, false))
		_assert(int(ops[0]["x"]) == empty.x and int(ops[0]["y"]) == empty.y, "confirm tap places")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "toolbar scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_aim_snap_and_magnifier() -> void:
	## P0-2: AimSnap 5° step + landmark snap; magnifier show/hide; one facing submit.
	const AimSnap := preload("res://sim/aim_snap.gd")
	## Pure snap math (no scene). 70° from (13,7) is far from 巷口/门/路口 → 5° step.
	var step := AimSnap.snap_facing(72.0, 13.0, 7.0, {})
	_assert(not bool(step.get("snapped", true)), "far-from-landmark uses step path snapped=%s label=%s" % [
		step.get("snapped"), step.get("label")])
	_assert(is_equal_approx(float(step["deg"]), 70.0), "5° step 72°→70° got=%s" % step.get("deg"))
	## From plan-A Kar cell toward 巷口 (~11°) → snap label 巷口.
	var alley := AimSnap.snap_facing(12.0, 13.0, 7.0, {})
	_assert(bool(alley.get("snapped", false)), "near 巷口 snaps")
	_assert(str(alley.get("label", "")) == "巷口", "snap label 巷口 got=%s" % alley.get("label"))
	_assert(str(alley.get("label", "")).find("高") < 0 and str(alley.get("label", "")).find("barn") < 0,
		"snap label never high-slot hint")

	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "aim-snap scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		scene.apply_layout_size(1280, 720)
		await process_frame
		scene._load_preset("A")
		scene._start_wait()
		await process_frame
		if scene.sim == null:
			continue
		scene.paused = true
		var map = scene.map_view
		map.reset_camera()
		map._fit_cell_px()
		await process_frame
		var oid := str(scene.sim.operators[1]["id"]) ## Kar @ (13,7) → 巷口
		var op = scene.sim.operators[1]
		var facing0 := float(op["facing_deg"])
		scene.selected_op_id = oid
		map.selected_op_id = oid
		scene._facing_submit_count = 0
		map.aim_magnifier_show_count = 0
		map.aim_magnifier_hide_count = 0
		var origin: Vector2 = map.cell_to_screen(float(op["x"]), float(op["y"]))
		var drag_px: float = maxf(80.0, map.cell_px * 2.5)
		## Drag toward ~11° (巷口) — should snap + show magnifier.
		map.inject_input(_touch(origin, true))
		_assert(not map.aim_magnifier_visible, "magnifier hidden before drag moves")
		var alley_ang := deg_to_rad(11.0)
		for s in range(8):
			var p := origin + Vector2(cos(alley_ang), -sin(alley_ang)) * (drag_px * float(s + 1) / 8.0)
			map.gesture.inject_move(p)
		_assert(map.aim_magnifier_visible, "magnifier visible while aiming")
		_assert(map.aim_magnifier_show_count >= 1, "magnifier show counted got=%d" % map.aim_magnifier_show_count)
		_assert(str(map.aim_snap_label) != "", "snap label set mid-drag got='%s'" % map.aim_snap_label)
		_assert(str(map.aim_snap_label).find("高") < 0, "snap label neutral mid-drag")
		_assert(is_equal_approx(float(op["facing_deg"]), facing0), "facing unchanged mid-aim-snap")
		_assert(scene._facing_submit_count == 0, "no submit mid-drag")
		var end := origin + Vector2(cos(alley_ang), -sin(alley_ang)) * drag_px
		map.inject_input(_touch(end, false))
		_assert(scene._facing_submit_count == 1, "release submits facing once got=%d" % scene._facing_submit_count)
		_assert(not map.aim_magnifier_visible, "magnifier hides on release")
		_assert(map.aim_magnifier_hide_count >= 1, "magnifier hide counted")
		## Second drag → cancel by returning near origin: still only one total submit.
		var submits_after: int = int(scene._facing_submit_count)
		var f2 := float(op["facing_deg"])
		map.inject_input(_touch(origin, true))
		map.gesture.inject_move(origin + Vector2(drag_px, 0))
		_assert(map.aim_magnifier_visible, "magnifier returns on second drag")
		map.inject_input(_touch(origin + Vector2(5, 0), false))
		_assert(int(scene._facing_submit_count) == submits_after, "cancel does not submit again")
		_assert(is_equal_approx(float(op["facing_deg"]), f2), "cancel keeps facing")
		_assert(not map.aim_magnifier_visible, "magnifier hides on cancel")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "aim-snap scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_wait_reaim_one_order() -> void:
	## Drag 90° with many motions → exactly one request_operator_facing.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "reaim scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		# Load plan A and enter wait without finishing night.
		scene.apply_layout_size(1280, 720)
		await process_frame
		scene._load_preset("A")
		scene._start_wait()
		await process_frame
		if scene.sim == null:
			continue
		scene.paused = true
		var map = scene.map_view
		map.reset_camera()
		map._fit_cell_px()
		await process_frame
		## MG @ (5,9) facing 0°: 90° target is far from landmarks so snap stays on 5° step (=90°).
		var oid := str(scene.sim.operators[0]["id"])
		var op = scene.sim.operators[0]
		var facing0 := float(op["facing_deg"])
		scene.selected_op_id = oid
		map.selected_op_id = oid
		scene._facing_submit_count = 0
		var origin: Vector2 = map.cell_to_screen(float(op["x"]), float(op["y"]))
		## Keep drag radius in cells so aim angle stays stable if cell_px shrinks.
		var drag_px: float = maxf(80.0, map.cell_px * 2.5)
		map.inject_input(_touch(origin, true))
		# 20 motion steps sweeping ~90°.
		for s in range(20):
			var ang := deg_to_rad(facing0 + float(s + 1) * 4.5)
			var p := origin + Vector2(cos(ang), -sin(ang)) * drag_px
			map.gesture.inject_move(p)
			# During drag, sim facing must stay.
			_assert(is_equal_approx(float(op["facing_deg"]), facing0), "facing unchanged mid-drag step %d" % s)
		var end := origin + Vector2(cos(deg_to_rad(facing0 + 90.0)), -sin(deg_to_rad(facing0 + 90.0))) * drag_px
		map.inject_input(_touch(end, false))
		_assert(scene._facing_submit_count == 1, "exactly one turn order got=%d" % scene._facing_submit_count)
		var facing1 := float(op["facing_deg"])
		var delta := absf(facing1 - facing0)
		while delta > 180.0:
			delta = absf(delta - 360.0)
		_assert(int(op.get("turn_ticks_left", 0)) == 40,
			"90° → 40 ticks got=%s facing %s→%s Δ=%s" % [op.get("turn_ticks_left"), facing0, facing1, delta])
		# Cancel path: drag out then back.
		scene._facing_submit_count = 0
		var f2 := float(op["facing_deg"])
		map.inject_input(_touch(origin, true))
		map.gesture.inject_move(origin + Vector2(80, 0))
		map.inject_input(_touch(origin + Vector2(5, 0), false))
		_assert(scene._facing_submit_count == 0, "drag-back cancels turn order")
		_assert(is_equal_approx(float(op["facing_deg"]), f2), "facing unchanged on cancel")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "reaim scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_hud_touch_sizing() -> void:
	## PR-5: primary/portrait ≥88 design-px; body text ≥22; pause confirm; long-press detonate.
	## Panel chips are compact (CHIP_MIN) so the right column fits without overlap.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "hud scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.thumb_bar == null:
			continue
		scene.apply_layout_size(1280, 720)
		await process_frame
		await process_frame
		var scale_pt := 0.542 ## 844×390 phone CSS pt vs 1280×720 design
		var primary: Array = []
		if scene.thumb_bar:
			for c in scene.thumb_bar.get_children():
				if c is BaseButton and (c as BaseButton).is_visible_in_tree():
					primary.append(c)
		if scene.portrait_strip:
			for c in scene.portrait_strip.get_children():
				if c is BaseButton and (c as BaseButton).is_visible_in_tree():
					primary.append(c)
		var bad_btn := ""
		for b in primary:
			var ms: Vector2 = b.custom_minimum_size
			var dim := minf(ms.x if ms.x > 0.0 else b.size.x, ms.y if ms.y > 0.0 else b.size.y)
			if dim < 88.0 - 1e-3:
				bad_btn = "%s min=%s size=%s" % [b.name, ms, b.size]
				break
			if dim * scale_pt < 44.0 - 1e-3:
				bad_btn = "%s scaled=%s" % [b.name, dim * scale_pt]
				break
		_assert(bad_btn == "", "primary/portrait buttons ≥88 design-px (%s)" % bad_btn)
		_assert(scene.right_column != null, "opaque right column exists")
		_assert(scene.right_scroll != null, "right column scrolls")
		var bad_lab := ""
		for lab in [scene.label_info, scene.label_phase, scene.label_alert]:
			if lab == null or not lab.visible:
				continue
			var fs := int(lab.get_theme_font_size("font_size"))
			if fs < 22:
				bad_lab = "%s font=%d" % [lab.name, fs]
				break
			if float(fs) * scale_pt < 12.0 - 1e-3:
				bad_lab = "%s pt=%s" % [lab.name, float(fs) * scale_pt]
				break
		_assert(bad_lab == "", "body labels ≥22 design-px / ≥12pt (%s)" % bad_lab)
		_assert(scene.btn_restart_wait == null or not scene.btn_restart_wait.visible,
			"wait panel restart hidden")
		_assert(scene.pause_menu != null, "pause menu exists")
		_assert(scene.btn_dev_toggle != null and scene.dev_menu != null, "dev menu exists")
		_assert(scene.btn_g2_art != null and scene.btn_g2_art.get_parent() == scene.dev_menu,
			"art toggle in dev menu")
		# Pause → restart requires confirm.
		scene._load_preset("A")
		scene._start_wait()
		await process_frame
		scene.paused = false
		scene._toggle_pause()
		_assert(scene.pause_menu.visible, "pause menu opens")
		var restarted := {"n": 0}
		# Confirm path: arm then confirm calls _restart.
		scene._restart_confirm_armed = false
		scene.btn_pause_restart.pressed.emit()
		_assert(scene._restart_confirm_armed, "restart armed after first click")
		_assert(scene.btn_pause_confirm.visible, "confirm button visible")
		# Long-press detonate: short hold no-op; ≥500ms fires.
		var md0: int = int(scene.sim.manual_detonate_tick)
		scene.detonate_now_ms_fn = func(): return 1000
		scene._on_detonate_down()
		scene.detonate_now_ms_fn = func(): return 1200 ## 200ms
		scene._on_detonate_up()
		_assert(int(scene.sim.manual_detonate_tick) == md0, "short press does not detonate")
		scene.detonate_now_ms_fn = func(): return 2000
		scene._on_detonate_down()
		scene.detonate_now_ms_fn = func(): return 2000 + scene.DETONATE_LONGPRESS_MS + 10
		scene._on_detonate_up()
		_assert(int(scene.sim.manual_detonate_tick) >= 0, "long-press sets manual_detonate_tick")
		_assert(str(scene.label_info.text).contains("手动起爆"),
			"long-press detonate info=%s" % scene.label_info.text)
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "hud scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _visible_buttons(root: Node) -> Array:
	var out: Array = []
	_collect_buttons(root, out)
	return out


func _collect_buttons(n: Node, out: Array) -> void:
	if n is BaseButton:
		var b := n as BaseButton
		if b.is_visible_in_tree() and not b.disabled:
			out.append(b)
	for c in n.get_children():
		_collect_buttons(c, out)


func _test_scout_path_preview() -> void:
	## PR-6: preview → confirm; pause freezes tick; hover preview + click confirms.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "scout preview scene err=%s" % err)
	for _i in range(240):
		await process_frame
		var scene = current_scene
		if scene == null or scene.scout == null or scene.map_view == null:
			continue
		if scene.ui_phase != scene.UiPhase.SCOUT:
			continue
		var scout = scene.scout
		var ops: Array = scout.operators
		_assert(ops.size() >= 1, "scout has ops")
		var oid := str(ops[0]["id"])
		scene.selected_op_id = oid
		scene.map_view.selected_op_id = oid
		# Goal: walkable cell near entry (11,2) typically.
		var goal := Vector2i(11, 2)
		if not scene.grid.walkable(goal.x, goal.y):
			goal = Vector2i(10, 2)
		scene._scout_hover_from_mouse = false
		scene._on_scout_cell_tapped(goal)
		_assert(scene.preview_path.size() >= 1, "preview_path set")
		_assert(scene.pending_scout_goal == goal, "pending goal")
		var end: Vector2i = scene.preview_path[scene.preview_path.size() - 1]
		_assert(end == goal, "preview ends at goal")
		var path0: Array = ops[0].get("path", [])
		_assert(path0.is_empty(), "op.path empty after first tap")
		# Second tap confirms.
		scene._on_scout_cell_tapped(goal)
		var path1: Array = ops[0].get("path", [])
		_assert(not path1.is_empty(), "op.path set after confirm")
		# Other cell updates preview without committing (clear path first).
		ops[0]["path"] = []
		ops[0]["move_ticks_left"] = 0
		scene._clear_scout_preview()
		var goal2 := Vector2i(12, 2)
		if not scene.grid.walkable(goal2.x, goal2.y):
			goal2 = Vector2i(9, 2)
		scene._on_scout_cell_tapped(goal2)
		_assert(scene.pending_scout_goal == goal2, "preview updates to other cell")
		_assert((ops[0].get("path", []) as Array).is_empty(), "path still empty on retarget")
		# Pause freezes tick; orders still allowed.
		var tick0: int = int(scout.tick)
		scene.paused = true
		for _f in range(60):
			await process_frame
		_assert(int(scout.tick) == tick0, "paused scout.tick unchanged got=%d want=%d" % [scout.tick, tick0])
		scene._on_scout_cell_tapped(goal2) ## confirm while paused
		_assert(not (ops[0].get("path", []) as Array).is_empty(), "can order while paused")
		# Hover preview + mouse click confirms.
		ops[0]["path"] = []
		ops[0]["move_ticks_left"] = 0
		scene._clear_scout_preview()
		scene.paused = true
		var goal3 := Vector2i(11, 3)
		if not scene.grid.walkable(goal3.x, goal3.y):
			goal3 = goal
		scene._on_cell_hovered(goal3)
		_assert(scene.preview_path.size() >= 1, "hover sets preview_path")
		_assert((ops[0].get("path", []) as Array).is_empty(), "hover does not commit")
		scene._on_scout_cell_tapped(goal3)
		_assert(not (ops[0].get("path", []) as Array).is_empty(), "click after hover commits")
		_assert(scene.btn_thumb_pause != null and scene.btn_thumb_pause.visible, "scout pause visible")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "scout preview scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _plan_fingerprint(plan: Dictionary) -> String:
	return JSON.stringify(plan)


func _test_undo_cancel() -> void:
	## PR-7: undo stack, Esc exits tool, Esc cancels aim drag.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "undo scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		_assert(scene.btn_undo != null and scene.btn_cancel != null, "undo/cancel buttons")
		var base := _plan_fingerprint(scene.plan)
		var ops: Array = scene.plan.get("operators", [])
		var oid := str(ops[0]["id"])
		# Place → facing → mine → undo ×3 → deep equal.
		scene.scripted_place_operator(oid, 5, 9, 0.0)
		# scripted_place bypasses undo; do player-like mutations.
		scene.undo_stack.clear()
		base = _plan_fingerprint(scene.plan)
		scene.selected_op_id = oid
		scene._push_undo()
		ops[0]["x"] = 6
		ops[0]["y"] = 5
		scene._push_undo()
		ops[0]["facing_deg"] = 45.0
		scene._on_tool_chip("mine")
		# Find walkable for mine.
		var mx := 8
		var my := 4
		for y in range(scene.grid.height):
			for x in range(scene.grid.width):
				if scene.grid.walkable(x, y):
					mx = x
					my = y
					break
		scene._place_mine_at(Vector2i(mx, my))
		_assert(scene.undo_stack.size() >= 3, "undo stack depth ≥3 got=%d" % scene.undo_stack.size())
		scene._undo()
		scene._undo()
		scene._undo()
		_assert(_plan_fingerprint(scene.plan) == base, "undo×3 restores plan")
		# Tool=trigger, Esc → OP, trigger unchanged.
		var trig0 := _plan_fingerprint(scene.plan.get("trigger", {}))
		scene._on_tool_chip("trigger")
		_assert(str(scene.setup_tool) == "trigger", "tool trigger")
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.pressed = true
		scene._unhandled_input(esc)
		_assert(str(scene.setup_tool) == "op", "Esc returns tool to op")
		_assert(_plan_fingerprint(scene.plan.get("trigger", {})) == trig0, "Esc leaves trigger")
		# Aim drag + Esc → facing unchanged.
		ops = scene.plan.get("operators", [])
		oid = str(ops[0]["id"])
		scene.selected_op_id = oid
		var f0 := float(ops[0]["facing_deg"])
		scene._on_aim_drag_started_track(oid, Vector2.ZERO)
		ops[0]["facing_deg"] = f0 + 90.0
		scene._aim_drag_active = true
		scene._cancel_mode()
		_assert(is_equal_approx(float(ops[0]["facing_deg"]), f0), "Esc cancels aim facing got=%s want=%s" % [ops[0]["facing_deg"], f0])
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "undo scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _portrait_status_text(scene) -> String:
	## Ignore nodes already queued for deletion by a portrait rebuild this frame.
	var out := ""
	if scene.portrait_strip == null:
		return out
	for c in scene.portrait_strip.get_children():
		if c is BaseButton and not (c as BaseButton).is_queued_for_deletion():
			out += str((c as BaseButton).text) + "\n"
	return out


func _test_climb_placement_feedback() -> void:
	## T5: placing on a high cell says the operator will climb first; ground does
	## not; undoing the high placement leaves no climb state at wait start.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "climb feedback scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		var ops: Array = scene.plan.get("operators", [])
		var id0 := str(ops[0]["id"])
		var id1 := str(ops[1]["id"])
		scene.scripted_place_operator(id0, 5, 9, 0.0)
		_assert(str(scene.label_info.text).contains("攀爬"),
			"high placement label mentions 攀爬 got=%s" % scene.label_info.text)
		scene.selected_op_id = id0
		scene._undo()
		scene.scripted_place_operator(id1, 11, 2, 90.0)
		_assert(not str(scene.label_info.text).contains("攀爬"),
			"ground placement label has no 攀爬 got=%s" % scene.label_info.text)
		scene.scripted_place_cross_marker(10, 7, 12, 7)
		scene._start_wait()
		if scene.sim == null:
			_assert(false, "climb feedback sim started")
			return
		var op0 = scene.sim.operators[0]
		_assert(bool(op0.get("climbing", false)) == false,
			"undone high placement does not climb at wait start")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "climb feedback scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_climb_wait_status() -> void:
	## T5: at wait start the info line and the portrait card say 攀爬中 (no
	## blacklisted teaching words); the card clears once the climb ends.
	const BriefingCopy := preload("res://ui/briefing_copy.gd")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "climb status scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		scene.apply_layout_size(1280, 720)
		await process_frame
		var ops: Array = scene.plan.get("operators", [])
		var id0 := str(ops[0]["id"])
		var id1 := str(ops[1]["id"])
		scene.scripted_place_operator(id0, 5, 9, 0.0)
		scene.scripted_place_operator(id1, 11, 2, 90.0)
		scene.scripted_place_cross_marker(10, 7, 12, 7)
		scene._start_wait()
		if scene.sim == null:
			_assert(false, "climb status sim started")
			return
		scene.paused = true
		_assert(str(scene.label_info.text).contains("攀爬中"),
			"wait opening label mentions 攀爬中 got=%s" % scene.label_info.text)
		_assert(BriefingCopy.forbidden_hits(str(scene.label_info.text)).is_empty(),
			"wait opening label blacklist clean got=%s" % str(scene.label_info.text))
		_assert(_portrait_status_text(scene).contains("攀爬中"),
			"portrait shows 攀爬中 at wait start got=%s" % _portrait_status_text(scene))
		for _t in range(40):
			scene.sim.advance_one_tick()
		scene._refresh_climb_status()
		_assert(not _portrait_status_text(scene).contains("攀爬中"),
			"portrait clears 攀爬中 after climb got=%s" % _portrait_status_text(scene))
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "climb status scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_climb_access_controls() -> void:
	## T5b: barn has two entrances. Tapping the placed operator's cell rotates the
	## entrance, copy names the trade-off, undo restores it, and retry clears the
	## sim climb fields so SETUP never paints the climb arc.
	const BriefingCopy := preload("res://ui/briefing_copy.gd")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "climb access controls scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		scene._load_preset("A")
		var mg: Dictionary = scene._plan_op("op_mg42")
		_assert(str(mg.get("climb_access", "")) == "barn_north_ladder",
			"preset A MG starts on north ladder")
		scene.selected_op_id = "op_mg42"
		scene.pending_place_cell = Vector2i(-1, -1)
		scene._handle_op_place_tap(Vector2i(5, 9))
		_assert(str(mg.get("climb_access", "")) == "barn_east_door",
			"tapping current cell rotates to east door got=%s" % mg.get("climb_access"))
		_assert(str(scene.label_info.text).contains("入口：东侧门"),
			"east door copy got=%s" % scene.label_info.text)
		_assert(str(scene.label_info.text).contains("看得见"),
			"east door copy warns about patrol got=%s" % scene.label_info.text)
		_assert(BriefingCopy.forbidden_hits(str(scene.label_info.text)).is_empty(),
			"east door copy blacklist clean got=%s" % scene.label_info.text)
		scene._handle_op_place_tap(Vector2i(5, 9))
		_assert(str(mg.get("climb_access", "")) == "barn_north_ladder",
			"tap rotates back to north ladder got=%s" % mg.get("climb_access"))
		_assert(str(scene.label_info.text).contains("入口：北侧梯子"),
			"north ladder copy got=%s" % scene.label_info.text)
		_assert(str(scene.label_info.text).contains("绕行"),
			"north ladder copy mentions detour got=%s" % scene.label_info.text)
		_assert(BriefingCopy.forbidden_hits(str(scene.label_info.text)).is_empty(),
			"north ladder copy blacklist clean got=%s" % scene.label_info.text)
		_assert(scene.set_op_climb_access("op_mg42", "no_such_entry") == false,
			"invalid climb access id rejected")
		_assert(str(mg.get("climb_access", "")) == "barn_north_ladder",
			"invalid id leaves entrance unchanged")
		_assert(scene.set_op_climb_access("no_such_op", "barn_east_door") == false,
			"unknown operator rejected")
		_assert(scene.set_op_climb_access("op_mg42", "barn_east_door") == true,
			"switch to east door for undo test")
		_assert(scene.set_op_climb_access("op_mg42", "barn_north_ladder") == true,
			"switch back to north ladder")
		scene._undo()
		_assert(str(scene._plan_op("op_mg42").get("climb_access", "")) == "barn_east_door",
			"undo restores previous entrance got=%s" % scene._plan_op("op_mg42").get("climb_access"))
		var map = scene.map_view
		_assert(map.access_marker_glyph({"label_zh": "北侧梯子"}) == "梯",
			"north ladder marker glyph")
		_assert(map.access_marker_glyph({"label_zh": "东侧门"}) == "门",
			"east door marker glyph")
		var fake_climb := {"id": "op_mg42", "climbing": true}
		_assert(not map.should_draw_climb_marker(fake_climb),
			"SETUP never draws climb marker")
		scene._start_wait()
		if scene.sim == null:
			_assert(false, "climb access wait started")
			OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
			OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
			return
		scene.paused = true
		var live_climb: Dictionary = {}
		for sop in map.operators:
			if str(sop.get("id", "")) == "op_mg42":
				live_climb = sop
		_assert(map.should_draw_climb_marker(live_climb),
			"WAIT draws live sim climb marker phase=%s" % map.phase)
		scene._restart()
		_assert(scene.ui_phase == scene.UiPhase.SETUP, "retry returns to SETUP")
		var stale := false
		for op in scene.plan.get("operators", []):
			if op.has("climbing") or op.has("climb_from") or op.has("climb_ticks_left"):
				stale = true
		_assert(not stale, "retry clears plan climb fields")
		_assert(str(scene._plan_op("op_mg42").get("climb_access", "")) == "barn_east_door",
			"retry keeps chosen entrance got=%s" % scene._plan_op("op_mg42").get("climb_access"))
		_assert(map.phase == "setup" and not map.ops_from_sim,
			"retry snapshot is plan/setup not sim ops")
		_assert(not map.should_draw_climb_marker(fake_climb),
			"retry SETUP still hides climb marker")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "climb access controls scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_climb_fractional_seconds() -> void:
	## T5c: access times are floats; ticks round once, copy drops ".0" for whole
	## seconds but keeps one decimal otherwise. Runtime level edit only.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "fractional climb scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		_assert(is_equal_approx(scene._climb_access_seconds({"id": "t", "climb_s": 2.5}), 2.5),
			"climb seconds keeps 2.5")
		_assert(scene._climb_access_ticks({"id": "t", "climb_s": 2.5}) == 50,
			"climb ticks 2.5s=50")
		_assert(scene._climb_access_ticks({"climb_s": 2.04}) == 41,
			"climb ticks 2.04s=41")
		_assert(scene._climb_access_ticks({"climb_s": 3.0}) == 60,
			"climb ticks 3.0s=60")
		_assert(scene._climb_access_ticks({}) == 40,
			"climb ticks default=40")
		_assert(scene._fmt_secs(2.5) == "2.5", "fmt secs 2.5")
		_assert(scene._fmt_secs(3.0) == "3", "fmt secs 3.0 drops decimal")
		_assert(scene._fmt_secs(2.0) == "2", "fmt secs 2.0 keeps old copy")
		var entry: Dictionary = {}
		for hs in scene.level.get("high_slots", []):
			if str(hs.get("id", "")) != "barn_l2":
				continue
			for a in hs.get("access", []):
				if str(a.get("id", "")) == "barn_north_ladder":
					entry = a
		_assert(not entry.is_empty(), "fractional test finds north ladder entry")
		if entry.is_empty():
			OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
			OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
			return
		var old_climb_s: Variant = entry.get("climb_s", 3.0)
		entry["climb_s"] = 2.5
		scene._load_preset("A")
		scene.scripted_place_operator("op_mg42", 5, 9, 0.0)
		_assert(str(scene.label_info.text).contains("2.5 秒"),
			"placement hint shows fractional seconds got=%s" % scene.label_info.text)
		scene._load_preset("A")
		_assert(scene.set_op_climb_access("op_mg42", "barn_north_ladder"),
			"fractional ladder access selected")
		_assert(str(scene.label_info.text).contains("2.5 秒"),
			"entrance copy shows fractional seconds got=%s" % scene.label_info.text)
		scene._start_wait()
		var mg: Dictionary = scene._plan_op("op_mg42")
		_assert(int(mg.get("climb_ticks_left", -1)) == 50,
			"plan A north ladder 2.5s=50 ticks got=%s" % mg.get("climb_ticks_left"))
		entry["climb_s"] = old_climb_s
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "fractional climb scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_return_fire_assist_controls() -> void:
	## T6: player-facing difficulty switch, env preset, plan handoff, and persistence.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	OS.set_environment("AMBUSH_RETURN_ASSIST", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "assist controls scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		_assert(scene.return_fire_assist == false, "assist defaults OFF in controller")
		_assert(scene.btn_return_fire_assist != null, "assist button exists")
		_assert(scene.btn_return_fire_assist.is_visible_in_tree(), "assist button visible in SETUP")
		_assert(str(scene.btn_return_fire_assist.text) == "还击辅助：关",
			"assist OFF button copy got=%s" % scene.btn_return_fire_assist.text)
		scene._load_preset("A")
		scene._push_undo()
		scene._toggle_return_fire_assist()
		_assert(scene.return_fire_assist == true, "toggle turns assist ON")
		_assert(str(scene.btn_return_fire_assist.text) == "还击辅助：开（每名敌人最多命中一次）",
			"assist ON button copy got=%s" % scene.btn_return_fire_assist.text)
		_assert(bool(scene.plan.get("return_fire_assist", false)) == true,
			"toggle mirrors setting into plan")
		scene._undo()
		_assert(scene.return_fire_assist == true, "undo does not drop assist setting")
		_assert(str(scene.btn_return_fire_assist.text).contains("还击辅助：开"),
			"undo keeps assist button copy got=%s" % scene.btn_return_fire_assist.text)
		scene._start_wait()
		if scene.sim == null:
			_assert(false, "assist scene sim started")
			return
		_assert(bool(scene.plan.get("return_fire_assist", false)) == true,
			"wait start writes return_fire_assist=true into plan")
		_assert(bool(scene.sim.enemy_return_soft_cap) == true, "sim receives assist ON")
		scene._restart()
		_assert(scene.return_fire_assist == true, "retry keeps assist setting")
		_assert(str(scene.btn_return_fire_assist.text).contains("还击辅助：开"),
			"retry keeps assist button copy got=%s" % scene.btn_return_fire_assist.text)
		scene._show_briefing_card()
		_assert(scene.briefing_assist_label != null, "briefing has assist line")
		_assert(str(scene.briefing_assist_label.text) == "还击辅助：开（每名敌人最多命中一次）",
			"briefing shows current assist ON got=%s" % scene.briefing_assist_label.text)
		scene._dismiss_briefing_card(false)
		scene._toggle_return_fire_assist()
		scene._show_briefing_card()
		_assert(str(scene.briefing_assist_label.text) == "还击辅助：关",
			"briefing shows current assist OFF got=%s" % scene.briefing_assist_label.text)
		scene._dismiss_briefing_card(false)
		OS.set_environment("AMBUSH_RETURN_ASSIST", "1")
		var err2 := change_scene_to_file("res://scenes/greybox.tscn")
		_assert(err2 == OK, "assist env scene err=%s" % err2)
		for _j in range(200):
			await process_frame
			var scene2 = current_scene
			if scene2 == null or scene2.map_view == null or scene2.plan.is_empty():
				continue
			_assert(scene2.return_fire_assist == true, "AMBUSH_RETURN_ASSIST=1 presets assist ON")
			_assert(str(scene2.btn_return_fire_assist.text).contains("还击辅助：开"),
				"env preset updates button got=%s" % scene2.btn_return_fire_assist.text)
			scene2._toggle_return_fire_assist()
			_assert(scene2.return_fire_assist == false, "button can turn env preset OFF")
			OS.set_environment("AMBUSH_RETURN_ASSIST", "")
			OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
			OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
			return
		_assert(false, "assist env scene not ready")
		OS.set_environment("AMBUSH_RETURN_ASSIST", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "assist controls scene not ready")
	OS.set_environment("AMBUSH_RETURN_ASSIST", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_camera_zoom_pan() -> void:
	## PR-8: pinch/magnify zoom, pan, round-trip cell_to_screen, wheel anchor.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "camera scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		var map = scene.map_view
		map.reset_camera()
		# Simulate pinch: two touches distance ×2 → zoom≈2.
		map._touch_points[0] = Vector2(100, 100)
		map._touch_points[1] = Vector2(140, 100)
		map._begin_or_update_pinch()
		map._touch_points[1] = Vector2(180, 100) ## dist 80 = 2×40
		map._begin_or_update_pinch()
		_assert(is_equal_approx(map.cam_zoom, 2.0) or absf(map.cam_zoom - 2.0) < 0.05,
			"pinch zoom≈2 got=%s" % map.cam_zoom)
		map.reset_camera()
		var mg := InputEventMagnifyGesture.new()
		mg.position = Vector2(200, 200)
		mg.factor = 1.5
		map._handle_camera_input(mg)
		_assert(is_equal_approx(map.cam_zoom, 1.5), "magnify 1.5 got=%s" % map.cam_zoom)
		map.zoom_at(Vector2(200, 200), 2.0) ## → 3 clamp to 2.5
		_assert(map.cam_zoom <= map.CAM_ZOOM_MAX + 1e-3, "zoom clamped")
		# Round-trip after zoom+pan.
		map.set_camera(2.0, Vector2(40, 30))
		var ok_rt := 0
		for cell in [Vector2i(2, 2), Vector2i(5, 9), Vector2i(10, 7), Vector2i(12, 4), Vector2i(8, 8),
			Vector2i(3, 11), Vector2i(15, 5), Vector2i(6, 3), Vector2i(11, 2), Vector2i(4, 6)]:
			var scr: Vector2 = map.cell_to_screen(float(cell.x), float(cell.y))
			var back: Vector2i = map.screen_to_cell(scr)
			if back == cell:
				ok_rt += 1
		_assert(ok_rt == 10, "cell_to_screen round-trip 10/10 got=%d" % ok_rt)
		# One-finger empty pan 60px → offset changes, no tap.
		map.reset_camera()
		map.allow_ground_pan = true
		map.tap_emit_count = 0
		var pan0: Vector2 = map.cam_pan
		var p0 := Vector2(50, 50)
		map.inject_input(_touch(p0, true))
		map.gesture.inject_move(p0 + Vector2(60, 0))
		map.inject_input(_touch(p0 + Vector2(60, 0), false))
		_assert(map.cam_pan.distance_to(pan0) > 1.0, "pan offset changed")
		_assert(map.tap_emit_count == 0, "pan emits no tap")
		# Wheel zoom keeps cell under cursor.
		map.reset_camera()
		var anchor := Vector2(220, 180)
		var cell_before: Vector2i = map.screen_to_cell(anchor)
		map.zoom_at(anchor, 1.25)
		var cell_after: Vector2i = map.screen_to_cell(anchor)
		_assert(cell_before == cell_after, "wheel zoom anchors cell %s→%s" % [cell_before, cell_after])
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "camera scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _count_tooltips(n: Node) -> int:
	var c := 0
	if n is Control and str((n as Control).tooltip_text) != "":
		c += 1
	for ch in n.get_children():
		c += _count_tooltips(ch)
	return c


func _test_info_card() -> void:
	## PR-9: long-press / hover info card; no tooltip_text left.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "info card scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		_assert(scene.info_card != null, "info card exists")
		var hash0 := JSON.stringify(scene.plan)
		scene._show_info_card_at(Vector2i(5, 9))
		_assert(scene.info_card.visible, "info card visible on long-press path")
		_assert(str(scene.info_card_label.text).contains("可见观察者"), "info has 可见观察者")
		_assert(JSON.stringify(scene.plan) == hash0, "plan unchanged by info card")
		scene._hide_info_card()
		# Hover dwell 300ms.
		scene.info_now_ms_fn = func(): return 5000
		scene._on_cell_hovered(Vector2i(8, 4))
		scene.info_now_ms_fn = func(): return 5000 + scene.HOVER_INFO_MS + 5
		scene._process(0.016)
		_assert(scene.info_card.visible, "hover dwell shows info card")
		scene._on_cell_hovered(Vector2i(9, 4)) ## move away arms new; hides
		_assert(not scene.info_card.visible or scene._hover_info_cell == Vector2i(9, 4), "hover move resets")
		scene._strip_all_tooltips()
		_assert(_count_tooltips(scene) == 0, "no tooltip_text left")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "info card scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _key(code: Key, ctrl: bool = false, shift: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.ctrl_pressed = ctrl
	e.shift_pressed = shift
	return e


func _test_desktop_shortcuts() -> void:
	## PR-10: 1-3 select, Q/E rotate, Space pause, Tab/M tool, right-click aim, help.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "shortcuts scene err=%s" % err)
	for _i in range(200):
		await process_frame
		var scene = current_scene
		if scene == null or scene.plan.is_empty():
			continue
		_assert(scene.shortcuts_help != null and scene.btn_shortcuts_help != null, "shortcuts help UI")
		var ops: Array = scene.plan.get("operators", [])
		scene._unhandled_input(_key(KEY_2))
		_assert(str(scene.selected_op_id) == str(ops[1]["id"]), "key 2 selects op1")
		var f0 := float(ops[1]["facing_deg"])
		scene._unhandled_input(_key(KEY_E))
		_assert(absf(float(ops[1]["facing_deg"]) - (f0 + 15.0)) < 0.01, "E rotates +15")
		scene._unhandled_input(_key(KEY_Q))
		_assert(absf(float(ops[1]["facing_deg"]) - f0) < 0.01, "Q rotates -15")
		scene.paused = false
		scene._unhandled_input(_key(KEY_SPACE))
		_assert(scene.paused == true, "Space pauses")
		scene._unhandled_input(_key(KEY_M))
		_assert(str(scene.setup_tool) == "mine", "M selects mine tool")
		scene._unhandled_input(_key(KEY_TAB))
		_assert(str(scene.setup_tool) == "trigger", "Tab cycles tool")
		# Right-click aim toward (10,7).
		scene._on_tool_chip("op")
		scene.selected_op_id = str(ops[1]["id"])
		var ox := float(ops[1]["x"])
		var oy := float(ops[1]["y"])
		scene._on_cell_right_clicked(Vector2i(10, 7))
		var want := rad_to_deg(atan2(7.0 - oy, 10.0 - ox))
		_assert(absf(float(ops[1]["facing_deg"]) - want) < 1.0, "right-click aim err=%s" % absf(float(ops[1]["facing_deg"]) - want))
		scene._toggle_shortcuts_help()
		_assert(scene.shortcuts_help.visible, "help overlay opens")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "shortcuts scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_briefing_and_phase_tips() -> void:
	## P0-3: opening briefing appears, dismissible, reopen via ?; phase tip once.
	const BriefingCopy := preload("res://ui/briefing_copy.gd")
	## Blacklist on all teaching strings (also covered by w8_briefing_blacklist_test).
	for t in BriefingCopy.all_teaching_texts():
		var hits: PackedStringArray = BriefingCopy.forbidden_hits(str(t))
		_assert(hits.is_empty(), "teaching text blacklist clean got=%s in=%s" % [str(hits), str(t).substr(0, 40)])
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "briefing scene err=%s" % err)
	for _i in range(260):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.briefing_card == null:
			continue
		## Fit asserts at both playable viewports before content checks.
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			scene.apply_layout_size(size_pair.x, size_pair.y)
			scene._show_briefing_card()
			await process_frame
			await process_frame
			await process_frame
			var tag := "%dx%d" % [size_pair.x, size_pair.y]
			_assert(scene.briefing_card.visible, "briefing visible %s" % tag)
			_assert(scene.briefing_dimmer != null and scene.briefing_dimmer.visible,
				"dimmer visible %s" % tag)
			var lay: Dictionary = scene.briefing_layout_ok(float(size_pair.x), float(size_pair.y))
			_assert(bool(lay.get("card_in", false)), "briefing card on-screen %s got=%s" % [tag, lay])
			_assert(bool(lay.get("btn_in", false)), "briefing dismiss on-screen %s got=%s" % [tag, lay])
			_assert(float(lay.get("btn_h", 0.0)) + 1e-3 >= 44.0,
				"briefing dismiss ≥44px %s h=%s" % [tag, lay.get("btn_h")])
			_assert(not bool(lay.get("text_clip", true)), "briefing text not clipped %s got=%s" % [tag, lay])
			_assert(bool(lay.get("ok", false)), "briefing layout ok %s got=%s" % [tag, lay])
		scene.apply_layout_size(1280, 720)
		scene._show_briefing_card()
		await process_frame
		await process_frame
		_assert(scene.briefing_card.visible, "briefing visible on first boot")
		_assert(scene.briefing_show_count >= 1, "briefing show counted")
		_assert(str(scene.briefing_body.text).contains("全歼"), "briefing mentions 全歼")
		_assert(str(scene.briefing_body.text).contains("北门"), "briefing lists 北门")
		_assert(str(scene.briefing_body.text).contains("南门"), "briefing lists 南门")
		_assert(str(scene.briefing_body.text).contains("东巷"), "briefing lists 东巷")
		_assert(str(scene.briefing_body.text).contains("侦察"), "briefing lists 侦察")
		_assert(str(scene.briefing_body.text).contains("搜集"), "briefing lists 搜集")
		_assert(str(scene.briefing_body.text).contains("布阵"), "briefing lists 布阵")
		_assert(str(scene.briefing_body.text).contains("等待"), "briefing lists 等待")
		_assert(str(scene.briefing_body.text).contains("起爆"), "briefing lists 起爆")
		## Dismiss.
		scene.btn_briefing_dismiss.pressed.emit()
		await process_frame
		_assert(not scene.briefing_card.visible, "briefing closes on 知道了")
		_assert(scene.briefing_dimmer == null or not scene.briefing_dimmer.visible, "dimmer hides with card")
		_assert(scene.briefing_dismiss_count >= 1, "briefing dismiss counted")
		## Scout tip after dismiss (first scout entry may have been blocked by briefing).
		scene._phase_tip_seen.erase("scout")
		scene._set_ui_phase(scene.UiPhase.SCOUT)
		await process_frame
		_assert(scene.phase_tip_bar.visible, "scout tip shows once")
		var tip1 := str(scene.phase_tip_label.text)
		scene.btn_phase_tip_close.pressed.emit()
		await process_frame
		_assert(not scene.phase_tip_bar.visible, "scout tip closable")
		scene._set_ui_phase(scene.UiPhase.SCOUT)
		await process_frame
		_assert(not scene.phase_tip_bar.visible, "scout tip does not repeat")
		## Setup tip once.
		scene._set_ui_phase(scene.UiPhase.SETUP)
		await process_frame
		_assert(scene.phase_tip_bar.visible, "setup tip shows")
		_assert(str(scene.phase_tip_label.text) != tip1, "setup tip differs from scout")
		scene._hide_phase_tip()
		scene._set_ui_phase(scene.UiPhase.SETUP)
		await process_frame
		_assert(not scene.phase_tip_bar.visible, "setup tip once only")
		## Reopen via ?
		scene.btn_shortcuts_help.pressed.emit()
		await process_frame
		_assert(scene.briefing_card.visible, "? reopens briefing")
		scene._dismiss_briefing_card(true)
		await process_frame
		_assert(not scene.briefing_card.visible, "briefing closed again")
		## Layout still OK after briefing dismissed.
		scene.dismiss_overlays_for_layout_test()
		scene.apply_layout_size(1280, 720)
		await process_frame
		var map_frac: float = scene.map_viewport_area_fraction()
		_assert(map_frac + 1e-4 >= 0.60, "map area after briefing dismiss ≥60%% got %.1f%%" % (map_frac * 100.0))
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
		return
	_assert(false, "briefing scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")


func _test_hud_layout_no_overlap() -> void:
	## No overlap + map fills leftover space (≥60% area; ≥75% in wait).
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "layout scene err=%s" % err)
	for _i in range(220):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_host == null or scene.right_column == null:
			continue
		if scene.plan.is_empty():
			continue
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			for phase_name in ["setup", "scout", "wait", "result"]:
				scene.apply_layout_size(size_pair.x, size_pair.y)
				await process_frame
				match phase_name:
					"setup":
						scene.drawer_open = true
						if scene.ui_phase != scene.UiPhase.SETUP:
							OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
							scene._init_blank_plan()
							scene._build_op_cards()
							scene._build_kit_row()
							scene._set_ui_phase(scene.UiPhase.SETUP)
						else:
							scene._set_ui_phase(scene.UiPhase.SETUP)
					"scout":
						scene.drawer_open = true
						scene._start_scout_phase()
					"wait":
						if scene.ui_phase != scene.UiPhase.SETUP:
							scene._init_blank_plan()
							scene._build_op_cards()
							scene._set_ui_phase(scene.UiPhase.SETUP)
						scene._load_preset("A")
						scene._start_wait()
						await process_frame
						if scene.sim:
							scene.paused = true
					"result":
						if scene.ui_phase != scene.UiPhase.WAIT:
							scene._load_preset("A")
							scene._start_wait()
							await process_frame
						scene._set_ui_phase(scene.UiPhase.RESULT)
				if scene.has_method("dismiss_overlays_for_layout_test"):
					scene.dismiss_overlays_for_layout_test()
				elif scene.pause_menu:
					scene.pause_menu.visible = false
					if scene.shortcuts_help:
						scene.shortcuts_help.visible = false
					if scene.info_card:
						scene.info_card.visible = false
					if scene.dev_menu:
						scene.dev_menu.visible = false
				scene.apply_layout_size(size_pair.x, size_pair.y)
				await process_frame
				await process_frame
				var tag := "%s@%dx%d" % [phase_name, size_pair.x, size_pair.y]
				var overlap := _find_hud_overlap(scene)
				_assert(overlap == "", "no HUD overlap %s (%s)" % [tag, overlap])
				var map_hit := _find_map_intersection(scene)
				_assert(map_hit == "", "HUD clears map viewport %s (%s)" % [tag, map_hit])
				var map_frac: float = scene.map_viewport_area_fraction()
				var min_frac := 0.75 if phase_name == "wait" else 0.60
				if phase_name != "result":
					_assert(map_frac + 1e-4 >= min_frac,
						"map area ≥%.0f%% got %.1f%% %s" % [min_frac * 100.0, map_frac * 100.0, tag])
				if phase_name == "setup":
					_assert(scene.right_column.visible, "right column visible in setup %s" % tag)
					var want_w: float = scene._right_column_width()
					var frac: float = want_w / float(size_pair.x)
					if size_pair.y < 500:
						_assert(frac >= 0.30 and frac <= 0.40, "phone drawer ~34%% got %.2f %s" % [frac, tag])
					else:
						_assert(frac >= 0.24 and frac <= 0.34, "desktop panel ~28%% got %.2f %s" % [frac, tag])
				if phase_name == "wait":
					var rail_w: float = scene._right_column_width()
					_assert(rail_w <= 110.0, "wait rail narrow got %.0f %s" % [rail_w, tag])
		## Phone setup: collapsing drawer grows the map.
		scene.apply_layout_size(844, 390)
		scene.drawer_open = true
		scene._set_ui_phase(scene.UiPhase.SETUP)
		scene.apply_layout_size(844, 390)
		await process_frame
		var open_frac: float = scene.map_viewport_area_fraction()
		scene.drawer_open = false
		scene.apply_layout_size(844, 390)
		await process_frame
		var closed_frac: float = scene.map_viewport_area_fraction()
		_assert(closed_frac > open_frac + 0.05, "collapse drawer grows map %.2f→%.2f" % [open_frac, closed_frac])
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "layout scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _layout_ignore_names() -> Dictionary:
	return {
		"ShortcutsHelp": true,
		"PauseMenu": true,
		"InfoCard": true,
		"DevMenu": true,
		"ResultPanel": true,
	}


func _is_layout_relevant(c: Control) -> bool:
	if c == null or not c.is_visible_in_tree():
		return false
	if c is ScrollContainer or c is MarginContainer or c is PanelContainer or c is VBoxContainer \
			or c is HBoxContainer or c is GridContainer or c is SubViewportContainer:
		## Containers themselves may tightly wrap children; compare leaves.
		if c.get_child_count() > 0 and not (c is BaseButton or c is Label or c is RichTextLabel):
			return false
	if c is BaseButton or c is Label or c is RichTextLabel or c is OptionButton or c is LineEdit:
		return true
	return false


func _collect_layout_controls(n: Node, out: Array, ignore: Dictionary) -> void:
	if n is Control:
		var c := n as Control
		var nm := str(c.name)
		if ignore.has(nm):
			return
		## Skip ResultPanel subtree when invisible; when visible it is modal.
		if nm == "ResultPanel":
			return
		if _is_layout_relevant(c):
			var r := c.get_global_rect()
			if r.size.x >= 2.0 and r.size.y >= 2.0:
				out.append(c)
	for ch in n.get_children():
		_collect_layout_controls(ch, out, ignore)


func _is_ancestor(a: Node, b: Node) -> bool:
	var p := b.get_parent()
	while p != null:
		if p == a:
			return true
		p = p.get_parent()
	return false


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	## Require a meaningful intersection (>2px) to ignore hairline adjacency.
	var i := a.intersection(b)
	return i.size.x > 2.0 and i.size.y > 2.0


func _clipped_global_rect(c: Control) -> Rect2:
	## Intersect with clipping ancestors so scrolled-off scroll content is ignored.
	var r := c.get_global_rect()
	var p: Node = c.get_parent()
	while p != null:
		if p is Control:
			var pc := p as Control
			if pc is ScrollContainer or pc.clip_contents:
				r = r.intersection(pc.get_global_rect())
				if r.size.x <= 2.0 or r.size.y <= 2.0:
					return Rect2()
		p = p.get_parent()
	return r


func _find_hud_overlap(scene) -> String:
	var ctrls: Array = []
	_collect_layout_controls(scene.hud, ctrls, _layout_ignore_names())
	for i in range(ctrls.size()):
		var a: Control = ctrls[i]
		var ra := _clipped_global_rect(a)
		if ra.size.x <= 2.0 or ra.size.y <= 2.0:
			continue
		for j in range(i + 1, ctrls.size()):
			var b: Control = ctrls[j]
			if _is_ancestor(a, b) or _is_ancestor(b, a):
				continue
			var rb := _clipped_global_rect(b)
			if rb.size.x <= 2.0 or rb.size.y <= 2.0:
				continue
			if _rects_overlap(ra, rb):
				return "%s ∩ %s" % [a.get_path(), b.get_path()]
	return ""


func _find_map_intersection(scene) -> String:
	## Overlays allowed on the map: top bar, utility chip strip, portrait strip.
	var map_r: Rect2 = scene.map_viewport_rect()
	if map_r.size.x < 4.0 or map_r.size.y < 4.0:
		## Logical map when framebuffer ≠ layout override.
		if scene.layout_size_override.x > 8.0:
			var col_w: float = scene._right_column_width()
			map_r = Rect2(2, scene.TOP_BAR_H + 2,
				scene.layout_size_override.x - col_w - 4,
				scene.layout_size_override.y - scene.TOP_BAR_H - 4)
		else:
			return "map rect empty"
	var ctrls: Array = []
	_collect_layout_controls(scene.hud, ctrls, _layout_ignore_names())
	for c in ctrls:
		var ctl: Control = c
		var path := str(ctl.get_path())
		if path.contains("/TopBar") or path.contains("Portrait") or path.contains("Utility"):
			continue
		if path.contains("RightColumn") or path.contains("WaitRail") or path.contains("DrawerTab"):
			continue
		var r := _clipped_global_rect(ctl)
		if r.size.x <= 2.0 or r.size.y <= 2.0:
			continue
		if _rects_overlap(r, map_r):
			return "%s ∩ MapHost" % path
	return ""


func _test_phase_camera_frames_content() -> void:
	## At phase start, every operator + enemy spawn cell is inside the visible map view.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "camera-frame scene err=%s" % err)
	for _i in range(220):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			for phase_name in ["scout", "setup", "wait"]:
				scene.apply_layout_size(size_pair.x, size_pair.y)
				await process_frame
				if scene.has_method("dismiss_overlays_for_layout_test"):
					scene.dismiss_overlays_for_layout_test()
				match phase_name:
					"scout":
						scene._start_scout_phase()
					"setup":
						scene.drawer_open = true
						if scene.ui_phase != scene.UiPhase.SETUP:
							scene.begin_setup_from_scout()
						scene._load_preset("A")
						scene._push_map_snapshot()
						scene._set_ui_phase(scene.UiPhase.SETUP)
					"wait":
						if scene.ui_phase != scene.UiPhase.SETUP:
							scene.begin_setup_from_scout()
							scene._load_preset("A")
						scene._start_wait()
						await process_frame
						if scene.sim:
							scene.paused = true
				scene.apply_layout_size(size_pair.x, size_pair.y)
				scene._push_map_snapshot()
				scene._apply_default_camera()
				await process_frame
				await process_frame
				var tag := "%s@%dx%d" % [phase_name, size_pair.x, size_pair.y]
				var map = scene.map_view
				_assert(map.cell_px > 0.0, "cell_px>0 %s" % tag)
				if size_pair.y < 500:
					_assert(scene._portrait_strip_height() <= 56.0 + 1e-3,
						"phone portrait strip ≤56px got=%s %s" % [scene._portrait_strip_height(), tag])
				var ops: Array = map.operators
				_assert(not ops.is_empty(), "ops present %s" % tag)
				for op in ops:
					if not bool(op.get("alive", true)):
						continue
					var cell := Vector2i(int(op["x"]), int(op["y"]))
					_assert(map.cell_in_visible_view(cell),
						"op %s cell %s in view %s" % [op.get("id", "?"), cell, tag])
					_assert(map.cell_in_safe_view(cell),
						"op %s cell %s in safe view %s" % [op.get("id", "?"), cell, tag])
					_assert(not scene.cell_under_hud_overlay(cell),
						"op %s cell %s clear of HUD %s" % [op.get("id", "?"), cell, tag])
				for spawn in map.enemy_spawn_cells():
					_assert(map.cell_in_visible_view(spawn),
						"spawn %s in view %s" % [spawn, tag])
					_assert(map.cell_in_safe_view(spawn),
						"spawn %s in safe view %s" % [spawn, tag])
					_assert(not scene.cell_under_hud_overlay(spawn),
						"spawn %s clear of HUD %s" % [spawn, tag])
		OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
		return
	_assert(false, "camera-frame scene not ready")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
