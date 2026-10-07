extends Node

## Test-only: bounded scalar post-draw table. No capture/simulation/resource writes.
const Provenance := preload("res://scripts/a3_provenance.gd")
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
	"tool_reject_geometry","dust_active","dust_reject_geometry","render_setup_ms","collector_usec",
	"presenter_valid","main_auto_process","tree_paused","render_counters_ready","collector_storage_bytes",
	"window_width","window_height","content_scale","max_fps","vsync"]
const TEXT_COLUMNS := ["segment","exclusion","level_id","attempt_id","policy"]
const SYMBOL_CAPACITY := 1024
const SEGMENT_CAPACITY := 512
var capacity := 32768 # Fixed allocation before production scene creation.
var row_count := 0
var overflow_rows := 0
var symbol_overflow := 0
var metadata: Dictionary = {}
var monitors: Array = []
var host: Node
var follow_current_scene := true
var segment := "cold-production-scene"
var measured := false
var exclusion := "cold_scene_loading"
var _table := PackedFloat64Array()
var _columns := {}
var _symbols: Array[String] = []
var _symbol_ids := {}
var _symbol_count := 0
var _segments: Array = []
var _first_segment_frame := true
var _previous_usec := 0
var _frame := 0
var _collecting := false
var _proof: Dictionary = {}
var _receipt_path := ""


func _ready() -> void:
	capacity=clampi(capacity,1,131072)
	for i: int in COLUMNS.size(): _columns[COLUMNS[i]]=i
	var static_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	_table.resize(capacity*column_count())
	_table.fill(-1.0)
	_symbols.resize(SYMBOL_CAPACITY)
	for label: String in ["",segment,exclusion,"first_frame_after_segment_transition","presenter_unavailable",
		"provenance_unverified","symbol_capacity_exceeded","headless_functional_only","standard","power_saving"]:
		_intern(label)
	var static_after := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var definitions := {}
	var constants := ClassDB.class_get_integer_constant_list("Performance")
	var rendering_method := RenderingServer.get_current_rendering_method()
	for name: String in MONITORS:
		var id := ClassDB.class_get_integer_constant("Performance",name) if name in constants else -1
		monitors.append(id)
		definitions[name]=monitor_support(name,id,DisplayServer.get_name(),OS.is_debug_build(),rendering_method)
	_receipt_path=OS.get_environment("AMBUSH_A3_PROVENANCE_FILE")
	_proof=Provenance.verify(_receipt_path,OS.get_environment("AMBUSH_TEST_SOURCE_SHA"))
	metadata={"format":2,"engine":Engine.get_version_info(),"os":OS.get_name(),"os_version":OS.get_version(),
		"cpu":OS.get_processor_name(),"cpu_count":OS.get_processor_count(),"pid":OS.get_process_id(),
		"display":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"vendor":RenderingServer.get_video_adapter_vendor(),"api_version":RenderingServer.get_video_adapter_api_version(),
		"rendering_method":rendering_method,"rendering_driver":RenderingServer.get_current_rendering_driver_name(),
		"debug_build":OS.is_debug_build(),"monitor_support":definitions,
		"monitor_names":MONITORS,"monitor_ids":monitors.duplicate(),
		"monitor_update_scope":"some engine monitors lag up to one second; early render counters need two drawn frames",
		"pipeline_zero_scope":"unknown backend support is not proof of no compilation; exclude unknown from supported summaries",
		"render_setup_supported":DisplayServer.get_name()!="headless" and RenderingServer.has_method("get_frame_setup_time_cpu"),
		"source_proof_before":_proof,"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),
		"run_id":OS.get_environment("AMBUSH_TEST_RUN_ID"),"xdg_cache":OS.get_environment("XDG_CACHE_HOME"),
		"buffer":{"capacity":capacity,"columns":column_count(),"payload_bytes":storage_bytes(),
			"static_before_allocate":static_before,"static_after_allocate":static_after,
			"allocation_delta_including_tables":static_after-static_before,"symbol_capacity":SYMBOL_CAPACITY,
			"scope":"fixed numeric payload; metadata/symbol strings/allocator overhead also resident; never subtract payload as total instrumentation memory"},
		"rss_ready_bytes":own_rss_bytes(),
		"cold_scope":"hook exists before caller changes production scene; engine boot/autoloads before script are not captured",
		"timer_scope":"callback entry through scalar table/counter writes and row_count increment; final timestamp field store and return excluded; not whole frame CPU/GPU time",
		"scope":"wall post-draw intervals, engine counters and explicit workload receipts; not Android performance"}
	mark(segment,false,exclusion)
	start()


static func monitor_support(name: String, id: int, display: String, debug_build: bool, rendering_method: String) -> Dictionary:
	if id<0: return {"supported":false,"status":"enum_unavailable","raw_sentinel":-1}
	if display=="headless" and (name.begins_with("RENDER_") or name.begins_with("PIPELINE_")):
		return {"supported":false,"status":"unsupported_headless_renderer","raw_sentinel":-1}
	if not debug_build and name in ["MEMORY_STATIC","OBJECT_ORPHAN_NODE_COUNT"]:
		return {"supported":false,"status":"unsupported_release_build","raw_sentinel":-1}
	if name.begins_with("PIPELINE_"):
		return {"supported":null,"status":"unknown_backend_support","backend":rendering_method,
			"scope":"enum readable; zero is unproven. Raw retained, exclude from supported budgets"}
	return {"supported":true,"status":"documented_monitor_api","scope":"availability does not imply immediate updates or isolated GPU/VRAM"}


func column_count() -> int:
	return COLUMNS.size()+MONITORS.size()


func storage_bytes() -> int:
	return _table.size()*8


func mark(label: String, timed: bool = false, reason: String = "fixture_or_transition", receipt: Dictionary = {}) -> void:
	segment=label
	measured=timed
	exclusion="" if timed else reason
	_first_segment_frame=true
	_intern(label)
	_intern(exclusion)
	if _segments.size()<SEGMENT_CAPACITY:
		_segments.append({"label":label,"timed":timed,"reason":reason,"frame_boundary":_frame,
			"row_boundary":row_count,"ticks_usec":Time.get_ticks_usec(),"rss_bytes":own_rss_bytes(),
			"window":get_window().size,"scale":get_window().content_scale_factor,"max_fps":Engine.max_fps,
			"vsync":DisplayServer.window_get_vsync_mode(),"workload":receipt.duplicate(true)})
	else:
		symbol_overflow+=1 # No unbounded segment metadata; full run becomes incomplete.


func start() -> void:
	if not RenderingServer.frame_post_draw.is_connected(_sample):
		RenderingServer.frame_post_draw.connect(_sample)
	_collecting=true


func stop() -> void:
	if RenderingServer.frame_post_draw.is_connected(_sample):
		RenderingServer.frame_post_draw.disconnect(_sample)
	_collecting=false


func _exit_tree() -> void:
	stop()


func _intern(value: String) -> int:
	if value in _symbol_ids: return int(_symbol_ids[value])
	if _symbol_count>=SYMBOL_CAPACITY:
		symbol_overflow+=1
		return -1
	var index := _symbol_count
	_symbols[index]=value
	_symbol_ids[value]=index
	_symbol_count+=1
	return index


func _put(base: int, name: String, value: float) -> void:
	_table[base+int(_columns[name])]=value


func _text(base: int, name: String, value: Variant) -> void:
	_put(base,name,_intern(value if value is String else ""))


func _number(base: int, name: String, value: Variant) -> void:
	var number := -1.0
	if typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)): number=float(value)
	elif value is bool: number=1.0 if value else 0.0
	_put(base,name,number)


func _size_property(object: Object, key: String) -> int:
	if not is_instance_valid(object): return -1
	var value: Variant = object.get(key)
	return value.size() if value is Array or value is Dictionary else -1


func _property(base: int, name: String, object: Object, key: String) -> void:
	if is_instance_valid(object): _number(base,name,object.get(key))


func _sample() -> void:
	var now := Time.get_ticks_usec()
	var interval := now-_previous_usec if _previous_usec>0 else -1
	_previous_usec=now
	_frame+=1
	if row_count>=capacity:
		overflow_rows+=1
		return # Preserve first/cold rows, never silently overwrite.
	var base := row_count*column_count()
	var first := _first_segment_frame
	_first_segment_frame=false
	if follow_current_scene: host=get_tree().current_scene
	var view: Variant = host.get("presentation_3d") if is_instance_valid(host) else null
	var frame: Variant = view.get("frame") if is_instance_valid(view) else null
	var valid: bool = frame is Dictionary and not frame.is_empty()
	var reason := exclusion
	if first: reason="first_frame_after_segment_transition"
	if not valid: reason="presenter_unavailable"
	if DisplayServer.get_name()=="headless": reason="headless_functional_only"
	if not _proof.get("verified",false): reason="provenance_unverified"
	_put(base,"frame",_frame)
	_put(base,"ticks_usec",now)
	_put(base,"interval_usec",interval)
	_text(base,"segment",segment)
	_text(base,"exclusion",reason)
	_put(base,"measured",1 if measured and not first and valid and DisplayServer.get_name()!="headless" and _proof.get("verified",false) and symbol_overflow==0 else 0)
	_put(base,"presenter_valid",1 if valid else 0)
	_put(base,"tree_paused",1 if get_tree().paused else 0)
	_put(base,"main_auto_process",1 if is_instance_valid(host) and host.is_processing() else 0)
	_put(base,"render_counters_ready",1 if DisplayServer.get_name()!="headless" and Engine.get_frames_drawn()>=2 else 0)
	_put(base,"collector_storage_bytes",storage_bytes())
	_put(base,"window_width",get_window().size.x)
	_put(base,"window_height",get_window().size.y)
	_put(base,"content_scale",get_window().content_scale_factor)
	_put(base,"max_fps",Engine.max_fps)
	_put(base,"vsync",DisplayServer.window_get_vsync_mode())
	if valid:
		for name: String in ["level_id","attempt_id"]: _text(base,name,frame.get(name))
		for name: String in ["wave_id","phase","recorded_phase","frame_seq","local_tick","playback_tick","replay"]:
			_number(base,name,frame.get(name))
		_property(base,"replay_speed",host.get("replay"),"speed")
		_property(base,"sim_paused",host.get("sim"),"paused")
		var rig: Variant = view.get("rig")
		for name: String in ["yaw_deg","pitch_deg","view_size"]: _property(base,name,rig,name)
		_text(base,"policy","power_saving" if host.has_method("_is_power_saving") and host.call("_is_power_saving") else "standard")
		var shot: Variant = view.get("shot_fx")
		var tool: Variant = view.get("tool_fx")
		var dust: Variant = view.get("movement_dust")
		_put(base,"shot_active",_size_property(shot,"_active"))
		_put(base,"shot_cache",_size_property(shot,"_cache"))
		_property(base,"shot_reject_geometry",shot,"_rejected_geometry")
		_property(base,"shot_reject_socket",shot,"_rejected_sockets")
		_put(base,"tool_active",_size_property(tool,"_active"))
		_property(base,"tool_reject_geometry",tool,"_rejected_geometry")
		_put(base,"dust_active",_size_property(dust,"_active"))
		_property(base,"dust_reject_geometry",dust,"_rejected_geometry")
	_put(base,"render_setup_ms",RenderingServer.get_frame_setup_time_cpu() if metadata.render_setup_supported else -1.0)
	for i: int in monitors.size():
		var definition: Dictionary = metadata.monitor_support[MONITORS[i]]
		_table[base+COLUMNS.size()+i]=Performance.get_monitor(monitors[i]) if definition.get("supported") != false else -1.0
	if symbol_overflow>0:
		_put(base,"measured",0)
		_text(base,"exclusion","symbol_capacity_exceeded")
	row_count+=1
	_put(base,"collector_usec",Time.get_ticks_usec()-now) # After every row/counter write and row index update.


func row_at(index: int) -> Array:
	if index<0 or index>=row_count: return []
	var result: Array = []
	for col: int in column_count():
		var value: float = _table[index*column_count()+col]
		if col<COLUMNS.size() and COLUMNS[col] in TEXT_COLUMNS:
			result.append(_symbols[int(value)] if value>=0 and value<_symbol_count else "")
		else: result.append(value)
	return result # Reconstruction only outside timed windows.


func reset_buffer() -> bool:
	if _collecting or measured: return false
	_table.fill(-1.0)
	row_count=0
	overflow_rows=0
	_first_segment_frame=true
	return true # Caller must seal old raw before reset; symbols/absolute frame counter retained.


static func own_rss_bytes() -> int:
	if OS.get_name()!="Linux" or not FileAccess.file_exists("/proc/self/status"): return -1
	for line: String in FileAccess.get_file_as_string("/proc/self/status").split("\n"):
		if line.begins_with("VmRSS:"):
			return int(line.substr(6).strip_edges().get_slice(" ",0))*1024
	return -1


func save(path: String, extra: Dictionary = {}) -> Error:
	if measured: return ERR_BUSY
	var file := FileAccess.open(path+"/raw.csv",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	var header: Array = COLUMNS.duplicate()
	header.append_array(MONITORS)
	file.store_csv_line(PackedStringArray(header))
	for index: int in row_count:
		var values := PackedStringArray()
		for value: Variant in row_at(index): values.append(str(value))
		file.store_csv_line(values)
	file.close()
	var report := FileAccess.open(path+"/metadata.json",FileAccess.WRITE)
	if report==null: return FileAccess.get_open_error()
	report.store_string(JSON.stringify({"metadata":metadata,"rows":row_count,"overflow_rows":overflow_rows,
		"symbol_overflow":symbol_overflow,"complete_buffer":overflow_rows==0 and symbol_overflow==0,
		"rss_save_bytes":own_rss_bytes(),"segments":_segments,"source_proof_after":Provenance.verify(_receipt_path,OS.get_environment("AMBUSH_TEST_SOURCE_SHA")),
		"extra":extra},"  "))
	report.close()
	return OK
