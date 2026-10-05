extends Node

## Test-only post-draw scalar collector. No simulation/capture/resource mutation.
const MONITORS := ["TIME_PROCESS","TIME_PHYSICS_PROCESS","RENDER_TOTAL_DRAW_CALLS_IN_FRAME",
	"RENDER_TOTAL_PRIMITIVES_IN_FRAME","RENDER_TOTAL_OBJECTS_IN_FRAME","RENDER_TEXTURE_MEM_USED",
	"RENDER_BUFFER_MEM_USED","RENDER_VIDEO_MEM_USED","MEMORY_STATIC","OBJECT_COUNT",
	"OBJECT_NODE_COUNT","OBJECT_RESOURCE_COUNT","OBJECT_ORPHAN_NODE_COUNT",
	"PIPELINE_COMPILATIONS_CANVAS","PIPELINE_COMPILATIONS_MESH","PIPELINE_COMPILATIONS_SURFACE",
	"PIPELINE_COMPILATIONS_DRAW","PIPELINE_COMPILATIONS_SPECIALIZATION"]
const COLUMNS := ["frame","ticks_usec","interval_usec","segment","measured","exclusion",
	"level_id","attempt_id","wave_id","phase","recorded_phase","frame_seq","local_tick","playback_tick",
	"replay","replay_speed","sim_paused","yaw_deg","pitch_deg","view_size","policy",
	"shot_active","shot_cache","shot_reject_geometry","shot_reject_socket","tool_active",
	"tool_reject_geometry","dust_active","dust_reject_geometry","render_setup_ms","collector_usec"]
var rows: Array = []
var metadata: Dictionary = {}
var monitors: Array = []
var host: Node
var segment := "fixture"
var measured := false
var exclusion := "fixture_or_transition"
var _first_segment_frame := true
var _previous_usec := 0
var _frame := 0


func _ready() -> void:
	var constants := ClassDB.class_get_integer_constant_list("Performance")
	for name: String in MONITORS:
		monitors.append(ClassDB.class_get_integer_constant("Performance",name) if name in constants else -1)
	metadata = {"engine":Engine.get_version_info(),"os":OS.get_name(),"os_version":OS.get_version(),
		"cpu":OS.get_processor_name(),"cpu_count":OS.get_processor_count(),"display":DisplayServer.get_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),
		"api_version":RenderingServer.get_video_adapter_api_version(),
		"rendering_method":RenderingServer.call("get_current_rendering_method") if RenderingServer.has_method("get_current_rendering_method") else "unsupported",
		"rendering_driver":RenderingServer.call("get_current_rendering_driver_name") if RenderingServer.has_method("get_current_rendering_driver_name") else "unsupported",
		"window":get_window().size,"scale":get_window().content_scale_factor,"max_fps":Engine.max_fps,
		"vsync":DisplayServer.window_get_vsync_mode(),"monitor_ids":monitors.duplicate(),"monitor_names":MONITORS,
		"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"run_id":OS.get_environment("AMBUSH_TEST_RUN_ID"),
		"xdg_cache":OS.get_environment("XDG_CACHE_HOME"),"scope":"actual post-draw wall intervals and scalar counters; not isolated GPU time/Android performance; unsupported monitors use -1"}
	RenderingServer.frame_post_draw.connect(_sample)


func mark(label: String, timed: bool = false, reason: String = "fixture_or_transition") -> void:
	segment = label
	measured = timed
	exclusion = "" if timed else reason
	_first_segment_frame = true


func _sample() -> void:
	var now := Time.get_ticks_usec()
	var interval := now - _previous_usec if _previous_usec > 0 else -1
	_previous_usec = now
	_frame += 1
	if not is_instance_valid(host) or host.presentation_3d == null: return
	var view: Node3D = host.presentation_3d
	var frame: Dictionary = view.frame
	var first := _first_segment_frame
	_first_segment_frame = false
	var row: Array = [_frame,now,interval,segment,1 if measured and not first else 0,
		"first_frame_after_segment_transition" if first else exclusion,
		frame.get("level_id",""),frame.get("attempt_id",""),frame.get("wave_id",-1),
		frame.get("phase",-1),frame.get("recorded_phase",-1),frame.get("frame_seq",-1),
		frame.get("local_tick",-1),frame.get("playback_tick",-1),1 if frame.get("replay",false) else 0,
		host.replay.speed,1 if host.sim.paused else 0,view.rig.yaw_deg,view.rig.pitch_deg,view.rig.view_size,
		"power_saving" if host._is_power_saving() else "standard",
		view.shot_fx._active.size(),view.shot_fx._cache.size(),view.shot_fx._rejected_geometry,view.shot_fx._rejected_sockets,
		view.tool_fx._active.size(),view.tool_fx._rejected_geometry,view.movement_dust._active.size(),view.movement_dust._rejected_geometry,
		RenderingServer.call("get_frame_setup_time_cpu") if RenderingServer.has_method("get_frame_setup_time_cpu") else -1.0,0]
	for id: int in monitors: row.append(Performance.get_monitor(id) if id >= 0 else -1.0)
	row[COLUMNS.find("collector_usec")] = Time.get_ticks_usec() - now
	rows.append(row)


func save(path: String, extra: Dictionary = {}) -> void:
	var file := FileAccess.open(path + "/raw.csv",FileAccess.WRITE)
	var header: Array = COLUMNS.duplicate()
	header.append_array(MONITORS)
	file.store_csv_line(PackedStringArray(header))
	for row: Array in rows:
		var values := PackedStringArray()
		for value: Variant in row: values.append(str(value))
		file.store_csv_line(values)
	file.close()
	var report := FileAccess.open(path + "/metadata.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"metadata":metadata,"rows":rows.size(),"extra":extra},"  "))
	report.close()
