extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Collector := preload("res://scripts/a3_render_metrics.gd")
const Context := preload("res://scripts/a3_window_context.gd")
var checks:=0
var failures:=0
var directory: String
var chunks: Array=[]
var captures: Array=[]
var receipt_sha: String
var collector: Node

func _init() -> void:
	if not Guard.check():quit(91);return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("A3_COLLECTOR_PROBE_FAIL "+message)

func _wait_seconds(seconds: float) -> void:
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec()-start<int(seconds*1_000_000):await process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path := directory+"/"+label+".png"
	_check(image.get_size()==Vector2i(1280,720) and image.save_png(path)==OK,"original Window crop outside timed segment "+label)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"scope":"DisplayServer crop outside timing; explicit frozen/API lifecycle control"})


func _seal(label: String, require_measured: bool) -> Dictionary:
	collector.mark(label+"-flush",false)
	collector.stop()
	var path := directory+"/"+label
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	var rows: Array=[]
	for index: int in collector.row_count:rows.append(collector.row_at(index))
	var included: Array=rows.filter(func(row:Array)->bool:return row[4]==1)
	_check(rows.size()>0 and rows.all(func(row:Array)->bool:return row.size()==59),"all actual retained post-draw rows have exact59 columns "+label)
	_check(rows.slice(1).all(func(row:Array)->bool:return row[2]>0 and is_finite(row[30]) and row[30]>=0),"actual monotonic intervals and finite callback usecs "+label)
	_check(included.size()>=3 if require_measured else true,"actual measured Window rows exist "+label)
	_check(included.all(func(row:Array)->bool:return row[31]==1 and row[34]==1 and row[2]>0 and row[5]=="" and row[32]==0),"accepted rows ready/presenter-valid/frozen and free of exclusions "+label)
	var save_error: Error=collector.save(path,{"scope":"actual Window stationary chunk/lifecycle; no six-level performance acceptance"})
	_check(save_error==OK,"valid nonoverflow Window chunk seals outside timing "+label)
	if not FileAccess.file_exists(path+"/metadata.json"):
		chunks.append({"label":label,"path":path,"valid":false,"save_error":save_error})
		return {}
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path+"/metadata.json"))
	if not parsed is Dictionary:
		_check(false,"valid JSON receipt exists "+label)
		chunks.append({"label":label,"path":path,"valid":false,"save_error":save_error})
		return {}
	var saved: Dictionary=parsed
	_check(saved.chunk_source_and_buffer_valid and not saved.run_incomplete and saved.run_overflow_rows==0 and saved.receipt_stable and saved.warm_import_proof_complete,"complete lifetime/buffer/fixed-loaded-proof receipt "+label)
	_check(saved.metadata.source_proof_before.receipt_sha256==receipt_sha and saved.source_proof_after.receipt_sha256==receipt_sha and saved.raw_sha256==FileAccess.get_sha256(path+"/raw.csv"),"original receipt and raw hash exact before/after "+label)
	if rows.is_empty():return {}
	var result: Dictionary={"label":label,"path":path,"raw_sha256":saved.raw_sha256,"row_count":rows.size(),
		"included_count":included.size(),"first_frame":rows.front()[0],"last_frame":rows.back()[0],
		"first_usec":rows.front()[1],"last_usec":rows.back()[1]}
	chunks.append(result)
	return result


func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	directory="res://build/asset_review/pr15-runtime/a3-collector-probe-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	Context.configure(self)
	receipt_sha=FileAccess.get_sha256(OS.get_environment("AMBUSH_A3_PROVENANCE_FILE"))
	var proof := Context.proof(receipt_sha)
	_check(proof.get("window_control_verified",false),"fixed complete source/engine/warm inventory proof before scene creation")
	if failures>0:_finish();return
	collector=Collector.new();root.add_child(collector) # Real hook BEFORE original scene load.
	collector.mark("cold-original-yard-scene",false,"cold_scene_loading")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main: Node=current_scene
	Context.freeze(main)
	collector.mark("first-warm-settle",false,"fixture_or_transition")
	await _wait_seconds(2.0)
	var original := Context.workload(main)
	collector.mark("first-actual-frozen-yard",true,"",original)
	await _wait_seconds(3.0)
	collector.mark("first-check-outside-timing",false)
	_check(Context.workload(main)==original,"first real render window leaves exact backend/frame/camera/config unchanged")
	var first := _seal("first",true)
	if failures>0:_finish();return
	await _capture("original-frozen-yard-first")
	_check(collector.reset_buffer(),"first valid raw seal permits reset")
	collector.mark("second-reconnect-settle",false,"fixture_or_transition")
	collector.start();collector.start()
	_check(RenderingServer.frame_post_draw.get_connections().filter(func(c:Dictionary)->bool:return c.callable==collector._sample).size()==1,"restart stays one actual post-draw subscription")
	await _wait_seconds(1.0)
	collector.mark("second-actual-frozen-yard",true,"",original)
	await _wait_seconds(3.0)
	collector.mark("second-check-outside-timing",false)
	_check(Context.workload(main)==original,"restarted actual window preserves original source and rendered frame")
	var second := _seal("second",true)
	if failures>0:_finish();return
	_check(second.first_frame>first.last_frame and second.first_usec>first.last_usec and FileAccess.get_sha256(first.path+"/raw.csv")==first.raw_sha256,"restart advances absolute frames/time and never overwrites first cold raw")
	_check(collector.reset_buffer(),"second valid raw seal permits lifecycle chunk reset")
	collector.mark("original-Title-transition",false,"fixture_or_transition")
	collector.start()
	var old_host: WeakRef=weakref(main)
	main._return_to_title()
	await process_frame
	await process_frame
	collector.mark("original-Title-unbound",false,"presenter_unavailable")
	await _wait_seconds(1.0)
	var title_rows: Array=[]
	for index: int in collector.row_count:
		var row: Array=collector.row_at(index)
		if row[3]=="original-Title-unbound":title_rows.append(row)
	_check(not is_instance_valid(old_host.get_ref()) and not title_rows.is_empty() and title_rows.all(func(row:Array)->bool:return row[31]==0 and row[4]==0 and row[9]==-1),"original Title frees host; real callbacks remain unavailable rather than fabricated phase0")
	collector.mark("Title-screenshot-excluded",false,"screenshot")
	await _capture("original-Title-unbound")
	root.get_node("GameSettings").pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var rebound: Node=current_scene
	Context.freeze(rebound)
	collector.mark("rebound-yard-settle",false,"fixture_or_transition")
	await _wait_seconds(1.0)
	var rebound_source := Context.workload(rebound)
	collector.mark("original-yard-rebound",true,"",rebound_source)
	await _wait_seconds(2.0)
	collector.mark("rebound-check-outside-timing",false)
	_check(Context.workload(rebound)==rebound_source,"new actual host/frame/source remains immutable under rebound callback")
	var rebound_rows: Array=[]
	for index: int in collector.row_count:
		var row: Array=collector.row_at(index)
		if row[3]=="original-yard-rebound" and row[4]==1:rebound_rows.append(row)
	_check(not rebound_rows.is_empty() and rebound_rows.all(func(row:Array)->bool:return row[7]==rebound.battle_log.attempt_id and row[31]==1 and row[34]==1),"rebound actual callbacks read the new host rather than freed source")
	var third := _seal("Title-and-rebound",true)
	if failures>0:_finish();return
	_check(third.first_frame>second.last_frame and third.first_usec>second.last_usec and FileAccess.get_sha256(first.path+"/raw.csv")==first.raw_sha256,"lifecycle third raw advances and original first bytes remain exact")
	await _capture("original-frozen-yard-rebound")
	var collector_id: int=collector.get_instance_id()
	var old_collector: WeakRef=weakref(collector)
	collector.start();collector.queue_free()
	await process_frame
	await process_frame
	_check(not is_instance_valid(old_collector.get_ref()) and RenderingServer.frame_post_draw.get_connections().all(func(c:Dictionary)->bool:return c.callable.get_object_id()!=collector_id),"freed collector disconnects actual source without stale callback")
	_check(Context.proof(receipt_sha).get("window_control_verified",false),"final source/cache/engine/receipt remain pinned after lifecycle")
	_finish()


func _finish() -> void:
	if is_instance_valid(collector):collector.stop()
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":1,"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),
		"receipt_sha256":receipt_sha,"checks":checks,"failures":failures,"chunks":chunks,"captures":captures,
		"environment":Context.environment(),"scope":"actual stationary Window positive seal/reset/restart/Title/rebind control only; not six-level A3/device/normal13"},"  "))
	file.close()
	print("A3_COLLECTOR_PROBE_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	root.get_node("AudioDirector").pause_for_background()
	quit(0 if failures==0 else 1)
