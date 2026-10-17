extends RefCounted
class_name GestureRouter

## PLAY-UX controls: release-based taps, drag slop, touch/mouse dedupe.
## Port of ambush_loop main.gd `_touch_ate_click` + pending-touch pattern.

signal tapped(pos: Vector2)
signal long_pressed(pos: Vector2)
signal drag_started(pos: Vector2, start_pos: Vector2)
signal drag_moved(pos: Vector2, start_pos: Vector2)
signal drag_ended(pos: Vector2, start_pos: Vector2, cancelled: bool)

enum State { IDLE, PRESSED, DRAGGING }

## User/audit: 22 design-px tap-vs-drag threshold (map local coords under canvas_items).
const TAP_SLOP_PX := 22.0
const LONG_PRESS_MS := 450

var state: int = State.IDLE
var now_ms_fn: Callable = Callable() ## injectable clock for tests
var bounds: Rect2 = Rect2() ## optional; release outside = cancel
var slop_px: float = TAP_SLOP_PX

var _press_pos: Vector2 = Vector2.ZERO
var _press_ms: int = 0
var _last_pos: Vector2 = Vector2.ZERO
var _touch_ate_click: bool = false
var _from_touch: bool = false
var _long_fired: bool = false


func reset() -> void:
	state = State.IDLE
	_touch_ate_click = false
	_from_touch = false
	_long_fired = false
	_press_pos = Vector2.ZERO
	_last_pos = Vector2.ZERO


func now_ms() -> int:
	if now_ms_fn.is_valid():
		return int(now_ms_fn.call())
	return Time.get_ticks_msec()


## Feed raw Control `_gui_input` events. Returns true if consumed.
func feed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_touch_ate_click = true
		_from_touch = true
		if st.pressed:
			_begin_press(st.position)
		else:
			_end_press(st.position)
		return true
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touch_ate_click = true
		_from_touch = true
		if state == State.IDLE:
			_begin_press(sd.position - sd.relative)
		_move_press(sd.position)
		return true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return false
		# Swallow the synthetic mouse click that follows a real touch.
		if _touch_ate_click:
			if not mb.pressed:
				_touch_ate_click = false
			return true
		_from_touch = false
		if mb.pressed:
			_begin_press(mb.position)
		else:
			_end_press(mb.position)
		return true
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _touch_ate_click and state == State.IDLE:
			return true
		# After a real touch press, allow motion while still pressed (some hosts
		# deliver MouseMotion instead of ScreenDrag alongside touch).
		var left_down := (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if left_down or state == State.PRESSED or state == State.DRAGGING:
			_move_press(mm.position)
			return true
	return false


## Test helper: inject a move without building platform events.
func inject_move(pos: Vector2) -> void:
	_move_press(pos)


func _begin_press(pos: Vector2) -> void:
	state = State.PRESSED
	_press_pos = pos
	_last_pos = pos
	_press_ms = now_ms()
	_long_fired = false


func _move_press(pos: Vector2) -> void:
	if state == State.IDLE:
		return
	_last_pos = pos
	var dist := pos.distance_to(_press_pos)
	if state == State.PRESSED:
		if dist >= slop_px:
			state = State.DRAGGING
			drag_started.emit(pos, _press_pos)
			drag_moved.emit(pos, _press_pos)
		elif not _long_fired and now_ms() - _press_ms >= LONG_PRESS_MS:
			_long_fired = true
			long_pressed.emit(_press_pos)
	elif state == State.DRAGGING:
		drag_moved.emit(pos, _press_pos)


func _end_press(pos: Vector2) -> void:
	_last_pos = pos
	var was := state
	var start := _press_pos
	state = State.IDLE
	if was == State.IDLE:
		return
	# Long-press already fired: release does not also tap.
	if _long_fired and was == State.PRESSED:
		_long_fired = false
		return
	if was == State.DRAGGING:
		var cancelled := false
		if bounds.has_area() and not bounds.has_point(pos):
			cancelled = true
		# Dragging back near press origin counts as cancel (aim cancel helper).
		if pos.distance_to(start) <= slop_px + 1e-3:
			cancelled = true
		drag_ended.emit(pos, start, cancelled)
		return
	# PRESSED within slop → tap on release (cancel if released outside bounds).
	if bounds.has_area() and not bounds.has_point(pos):
		return
	if pos.distance_to(start) < slop_px:
		tapped.emit(pos)
	_long_fired = false


## Test helper: advance clock while pressed to fire long-press without motion.
func poll_long_press() -> void:
	if state != State.PRESSED or _long_fired:
		return
	if now_ms() - _press_ms >= LONG_PRESS_MS:
		_long_fired = true
		long_pressed.emit(_press_pos)
