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
	await _test_setup_toolbar_and_trip()
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
		scene._load_preset("A")
		scene._start_wait()
		await process_frame
		if scene.sim == null:
			continue
		scene.paused = true
		var map = scene.map_view
		var oid := str(scene.sim.operators[1]["id"]) ## Kar
		var op = scene.sim.operators[1]
		var facing0 := float(op["facing_deg"])
		scene.selected_op_id = oid
		map.selected_op_id = oid
		scene._facing_submit_count = 0
		var origin: Vector2 = map.cell_to_screen(float(op["x"]), float(op["y"]))
		map.inject_input(_touch(origin, true))
		# 20 motion steps sweeping ~90°.
		for s in range(20):
			var ang := deg_to_rad(facing0 + float(s + 1) * 4.5)
			var p := origin + Vector2(cos(ang), -sin(ang)) * 80.0
			map.gesture.inject_move(p)
			# During drag, sim facing must stay.
			_assert(is_equal_approx(float(op["facing_deg"]), facing0), "facing unchanged mid-drag step %d" % s)
		var end := origin + Vector2(cos(deg_to_rad(facing0 + 90.0)), -sin(deg_to_rad(facing0 + 90.0))) * 80.0
		map.inject_input(_touch(end, false))
		_assert(scene._facing_submit_count == 1, "exactly one turn order got=%d" % scene._facing_submit_count)
		_assert(int(op.get("turn_ticks_left", 0)) == 40, "90° → 40 ticks got=%s" % op.get("turn_ticks_left"))
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
