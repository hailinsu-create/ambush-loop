extends RefCounted

## Short, opt-in camera/render probe. It never starts or changes a raid.
## Raw frame intervals are wall-clock measurements, not a sustained FPS verdict.
const DURATION := 30.0
var active := false
var elapsed := 0.0
var intervals := PackedFloat64Array()
var previous_usec := 0
var saved_pose: Dictionary = {}
var report: Dictionary = {}
var max_draws := 0
var max_primitives := 0


func start(rig: Node3D) -> void:
	active = true
	elapsed = 0.0
	intervals.clear()
	report.clear()
	previous_usec = Time.get_ticks_usec()
	max_draws = 0
	max_primitives = 0
	saved_pose = {"focus": rig.focus, "yaw": rig.yaw_deg, "pitch": rig.pitch_deg, "size": rig.view_size}


func stop(rig: Node3D) -> void:
	active = false
	if not saved_pose.is_empty():
		rig.focus = saved_pose.focus
		rig.yaw_deg = saved_pose.yaw
		rig.pitch_deg = saved_pose.pitch
		rig.view_size = saved_pose.size
		rig.apply_pose()


func step(rig: Node3D, frame: Dictionary) -> bool:
	if not active:
		return false
	var now := Time.get_ticks_usec()
	var ms := float(now - previous_usec) / 1000.0
	previous_usec = now
	elapsed += ms / 1000.0
	# Two seconds of warm-up are included in the tour but excluded from samples.
	if elapsed >= 2.0:
		intervals.append(ms)
		max_draws = maxi(max_draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		max_primitives = maxi(max_primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	rig.yaw_deg = float(saved_pose.yaw) + elapsed / DURATION * 360.0
	rig.pitch_deg = 50.0 + 15.0 * sin(elapsed / DURATION * TAU)
	rig.view_size = 24.0 + 6.0 * sin(elapsed / DURATION * TAU)
	rig.apply_pose()
	if elapsed < DURATION:
		return false
	stop(rig)
	var sorted := intervals.duplicate()
	sorted.sort()
	var total_ms := 0.0
	for value in intervals:
		total_ms += value
	report = {"kind": "short_camera_probe_not_sustained_acceptance", "engine": Engine.get_version_info().string,
		"model": OS.get_model_name(), "os": OS.get_name(), "os_version": OS.get_version(),
		"gpu": RenderingServer.get_video_adapter_name(), "viewport": str(rig.get_viewport().get_visible_rect().size),
		"phase_at_end": frame.get("phase", -1), "level": frame.get("level_id", ""),
		"samples": intervals.size(), "avg_fps": intervals.size() * 1000.0 / maxf(total_ms, 0.001),
		"p95_ms": sorted[mini(sorted.size() - 1, int(ceil(sorted.size() * 0.95)) - 1)],
		"p99_ms": sorted[mini(sorted.size() - 1, int(ceil(sorted.size() * 0.99)) - 1)],
		"max_draw_calls": max_draws, "max_primitives": max_primitives,
		"texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"frame_ms": Array(intervals)}
	var file := FileAccess.open("user://a0_camera_probe.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	print("A0_CAMERA_PROBE ", JSON.stringify(report))
	return true
