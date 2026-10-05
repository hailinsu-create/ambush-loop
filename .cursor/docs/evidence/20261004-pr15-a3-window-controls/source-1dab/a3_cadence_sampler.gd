extends RefCounted
## Shared, bounded post-draw sampler in BOTH baseline/instrumented conditions.
const CAPACITY := 32768
const COLUMNS := ["engine_frame","sample_seq","ticks_usec","interval_usec","included","exclusion_code",
	"render_counters_ready","draw_calls","primitives","render_objects","static_bytes","object_count",
	"node_count","resource_count","process_seconds","sampler_usec"]
var row_count := 0
var overflow_rows := 0
var _sequence := 0
var _previous_usec := 0
var _timed := false
var _first := true
var _running := false
var _sealed := false
var _run_incomplete := false
var _table := PackedFloat64Array()


func _init() -> void:
	_table.resize(CAPACITY*COLUMNS.size())
	_table.fill(-1.0)


func begin() -> bool:
	if _running or _run_incomplete or (row_count>0 and not _sealed):return false
	_table.fill(-1.0)
	row_count=0
	overflow_rows=0
	_previous_usec=0
	_timed=false
	_first=true
	_sealed=false
	RenderingServer.frame_post_draw.connect(_sample)
	_running=true
	return true


func mark_timed(value: bool) -> void:
	_timed=value
	_first=true


func stop() -> void:
	if RenderingServer.frame_post_draw.is_connected(_sample):RenderingServer.frame_post_draw.disconnect(_sample)
	_running=false
	_timed=false


func storage_bytes() -> int:
	return _table.size()*8


func _sample() -> void:
	var now := Time.get_ticks_usec()
	var interval := now-_previous_usec if _previous_usec>0 else -1
	_previous_usec=now
	_sequence+=1
	if row_count>=CAPACITY:
		overflow_rows+=1;_run_incomplete=true;_sealed=false;return
	var base := row_count*COLUMNS.size()
	var drawn := Engine.get_frames_drawn()
	var ready: bool = DisplayServer.get_name()!="headless" and drawn>=2
	var exclusion := 0
	if not _timed:exclusion=1
	elif _first:exclusion=2
	elif not ready:exclusion=3
	_table[base]=drawn
	_table[base+1]=_sequence
	_table[base+2]=now
	_table[base+3]=interval
	_table[base+4]=1 if exclusion==0 and interval>0 else 0
	_table[base+5]=exclusion
	_table[base+6]=1 if ready else 0
	_table[base+7]=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_table[base+8]=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	_table[base+9]=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	_table[base+10]=Performance.get_monitor(Performance.MEMORY_STATIC) if OS.is_debug_build() else -1
	_table[base+11]=Performance.get_monitor(Performance.OBJECT_COUNT)
	_table[base+12]=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_table[base+13]=Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	_table[base+14]=Performance.get_monitor(Performance.TIME_PROCESS)
	_first=false
	row_count+=1
	_table[base+15]=Time.get_ticks_usec()-now


func row_at(index: int) -> Array:
	if index<0 or index>=row_count:return []
	var result: Array=[]
	for column: int in COLUMNS.size():result.append(_table[index*COLUMNS.size()+column])
	return result


func save(path: String, receipt: Dictionary) -> Error:
	if _running or _timed:return ERR_BUSY
	if FileAccess.file_exists(path+"/cadence.csv"):return ERR_ALREADY_IN_USE
	var file := FileAccess.open(path+"/cadence.csv",FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_csv_line(PackedStringArray(COLUMNS))
	for index: int in row_count:
		var values := PackedStringArray()
		for value: Variant in row_at(index):values.append(str(value))
		file.store_csv_line(values)
	var raw_error := file.get_error();file.close()
	var metadata := FileAccess.open(path+"/cadence-metadata.json",FileAccess.WRITE)
	if metadata==null:return FileAccess.get_open_error()
	metadata.store_string(JSON.stringify({"format":1,"rows":row_count,"overflow_rows":overflow_rows,
		"run_incomplete":_run_incomplete,"capacity":CAPACITY,"payload_bytes":storage_bytes(),
		"raw_sha256":FileAccess.get_sha256(path+"/cadence.csv"),"receipt":receipt,
		"exclusion_codes":{"0":"included","1":"untimed_settle","2":"first_interval_after_transition","3":"render_counters_not_ready"},
		"support":{"static_bytes":OS.is_debug_build(),"render_counters":"Window after two engine draws; may lag",
			"GPU_time":"unavailable Compatibility/OpenGL","pipeline":"not sampled; unknown backend support"},
		"timer_scope":"callback entry through all scalar/counter writes and row count; final duration store/return excluded",
		"scope":"same minimal sampler paid in both controls; warm/transition raw retained, no corrected FPS subtraction"},"  "))
	var metadata_error := metadata.get_error();metadata.close()
	_sealed=raw_error==OK and metadata_error==OK
	if not _sealed:return ERR_FILE_CANT_WRITE
	return ERR_INVALID_DATA if _run_incomplete else OK
