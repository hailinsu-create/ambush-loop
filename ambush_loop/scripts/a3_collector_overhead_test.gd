extends SceneTree
## Stationary paired instrumentation controls; all proof/IO/assertions are untimed.
const Guard := preload("res://scripts/test_storage_guard.gd")
const Collector := preload("res://scripts/a3_render_metrics.gd")
const Sampler := preload("res://scripts/a3_cadence_sampler.gd")
const Context := preload("res://scripts/a3_window_context.gd")
const ORDER := [false,true,true,false,true,false,false,true] # ABBA then BAAB.
var checks:=0
var failures:=0
var directory: String
var receipt_sha: String
var main: Node
var active_collector: Node
var sampler: RefCounted
var canonical: Dictionary={}
var conditions: Array=[]
var source_before: Dictionary={}
var source_after: Dictionary={}
var monitor_support: Dictionary={}


func _init() -> void:
	if not Guard.check():quit(91);return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("A3_OVERHEAD_FAIL "+message)


func _wait_seconds(seconds: float) -> void:
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec()-start<int(seconds*1_000_000):await process_frame


func _condition(family: String, index: int, attached: bool, resident: Node) -> void:
	var failures_before := failures
	var label := "%s-%02d-%s" % [family,index,"attached" if attached else "baseline"]
	var path := directory+"/"+label
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	active_collector=resident
	if family=="full_buffer" and attached:
		active_collector=Collector.new();root.add_child(active_collector);active_collector.stop()
	if is_instance_valid(active_collector):
		active_collector.stop() # Sampler always reconnects FIRST in both controls.
		monitor_support=active_collector.metadata.monitor_support.duplicate(true)
		_check(active_collector.metadata.source_proof_before.get("receipt_sha256")==receipt_sha,"collector pins original receipt outside timing "+label)
	_check(sampler.begin(),"shared fixed sampler starts only after previous raw seal "+label)
	if is_instance_valid(active_collector) and attached:
		active_collector.mark(label+"-untimed-settle",false,"fixture_or_transition")
		active_collector.start()
	await _wait_seconds(2.0) # Retained by sampler/attached collector, explicitly excluded.
	var before := Context.workload(main)
	_check(before==canonical,"same original backend/presenter/camera/config before "+label)
	if failures>failures_before:
		sampler.stop()
		var partial_collector: Dictionary={}
		if is_instance_valid(active_collector):
			active_collector.mark(label+"-failed-before-timing",false)
			active_collector.stop()
			if active_collector.row_count>0:
				var partial_path := path+"/collector"
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(partial_path))
				var partial_error: Error=active_collector.save(partial_path,{"invalid_before_timing":true,"scope":"preserved partial warm raw; not an accepted control window"})
				partial_collector={"path":partial_path,"rows":active_collector.row_count,
					"save_error":partial_error,"raw_sha256":FileAccess.get_sha256(partial_path+"/raw.csv")}
		var partial: Dictionary={"label":label,"family":family,"index":index,"attached":attached,
			"invalid_before_timing":true,"valid":false,"workload_before":before,"canonical":canonical,
			"collector":partial_collector,"receipt_sha256":receipt_sha,"path":path}
		var partial_cadence_error: Error=sampler.save(path,partial)
		partial["cadence_save_error"]=partial_cadence_error
		partial["cadence_sha256"]=FileAccess.get_sha256(path+"/cadence.csv")
		conditions.append(partial) # Failed controls are explicit, never disappear from the run.
		if family=="full_buffer" and is_instance_valid(active_collector):
			active_collector.queue_free()
			await process_frame
			await process_frame
			active_collector=null
		return
	var rss_start: int=Collector.own_rss_bytes()
	var static_start: float=Performance.get_monitor(Performance.MEMORY_STATIC) if OS.is_debug_build() else -1
	sampler.mark_timed(true)
	if is_instance_valid(active_collector) and attached:active_collector.mark(label,true,"",before)
	var timed_start := Time.get_ticks_usec()
	await _wait_seconds(4.0)
	var timed_end := Time.get_ticks_usec()
	sampler.mark_timed(false);sampler.stop()
	if is_instance_valid(active_collector):
		active_collector.mark(label+"-outside-timing",false)
		active_collector.stop()
	var rss_end: int=Collector.own_rss_bytes()
	var static_end: float=Performance.get_monitor(Performance.MEMORY_STATIC) if OS.is_debug_build() else -1
	var after := Context.workload(main)
	_check(after==before and after==canonical,"same original backend/presenter/camera/config after "+label)
	var rows: Array=[]
	for row_index: int in sampler.row_count:rows.append(sampler.row_at(row_index))
	var included: Array=rows.filter(func(row:Array)->bool:return row[4]==1)
	_check(sampler.overflow_rows==0 and included.size()>=3,"bounded real post-draw cadence with at least3 accepted frames "+label)
	_check(included.all(func(row:Array)->bool:return row[6]==1 and row[3]>0 and row[5]==0 and is_finite(row[15]) and row[15]>=0),"accepted cadence ready/finite/positive with no transition rows "+label)
	var payload: int=active_collector.storage_bytes() if is_instance_valid(active_collector) else 0
	var collector_receipt: Dictionary={}
	if attached:
		var collector_path := path+"/collector"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(collector_path))
		var collector_rows: Array=[]
		for row_index: int in active_collector.row_count:collector_rows.append(active_collector.row_at(row_index))
		var measured: Array=collector_rows.filter(func(row:Array)->bool:return row[4]==1)
		_check(measured.size()>=3 and measured.all(func(row:Array)->bool:return row[31]==1 and row[34]==1 and row[32]==0 and row[5]=="" and row[2]>0),"actual collector accepted rows ready/valid/frozen "+label)
		_check(active_collector.save(collector_path,{"family":family,"label":label,"scope":"stationary paired overhead; not six-level gameplay/Android"})==OK,"actual collector raw sealed outside timing "+label)
		var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(collector_path+"/metadata.json"))
		_check(saved.chunk_source_and_buffer_valid and saved.receipt_stable and saved.warm_import_proof_complete and not saved.run_incomplete and saved.run_overflow_rows==0,"collector raw complete lifetime/fixed loaded-source proof "+label)
		_check(saved.metadata.source_proof_before.receipt_sha256==receipt_sha and saved.source_proof_after.receipt_sha256==receipt_sha and saved.raw_sha256==FileAccess.get_sha256(collector_path+"/raw.csv"),"collector raw and original provenance hashes exact "+label)
		collector_receipt={"path":collector_path,"raw_sha256":saved.raw_sha256,"rows":collector_rows.size(),"measured_rows":measured.size()}
		if family=="resident_callback":_check(active_collector.reset_buffer(),"resident buffer reused only after successful accepted raw seal "+label)
	elif is_instance_valid(active_collector):
		_check(not RenderingServer.frame_post_draw.is_connected(active_collector._sample) and active_collector.row_count==0,"resident baseline retains buffer but performs no collector callback "+label)
	var receipt: Dictionary={"label":label,"family":family,"index":index,"attached":attached,
		"collector_present":is_instance_valid(active_collector),"collector_payload_bytes":payload,
		"common_sampler_payload_bytes":sampler.storage_bytes(),"sampler_callback_order":"first, collector second when attached",
		"workload_before":before,"workload_after":after,"receipt_sha256":receipt_sha,
		"rss_start_bytes":rss_start,"rss_end_bytes":rss_end,"static_start_bytes":static_start,"static_end_bytes":static_end,
		"timed_start_usec":timed_start,"timed_end_usec":timed_end,"actual_wall_seconds":float(timed_end-timed_start)/1_000_000.0,
		"settle_seconds":2.0,"requested_timed_seconds":4.0,"included_rows":included.size(),"collector":collector_receipt}
	_check(sampler.save(path,receipt)==OK,"shared cadence raw seals outside timing "+label)
	var cadence_meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"/cadence-metadata.json"))
	_check(cadence_meta.raw_sha256==FileAccess.get_sha256(path+"/cadence.csv") and not cadence_meta.run_incomplete,"shared cadence raw hash exact/complete "+label)
	receipt["path"]=path
	receipt["cadence_sha256"]=cadence_meta.raw_sha256
	receipt["valid"]=failures==failures_before
	conditions.append(receipt)
	if family=="full_buffer" and is_instance_valid(active_collector):
		active_collector.queue_free()
		await process_frame
		await process_frame
		active_collector=null


func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	directory="res://build/asset_review/pr15-runtime/a3-overhead-window-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	Context.configure(self)
	receipt_sha=FileAccess.get_sha256(OS.get_environment("AMBUSH_A3_PROVENANCE_FILE"))
	source_before=Context.proof(receipt_sha)
	_check(source_before.get("window_control_verified",false),"fixed source/engine/nonempty warm/receipt before workload")
	if failures>0:_finish();return
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	Context.freeze(main)
	await _wait_seconds(3.0)
	canonical=Context.workload(main)
	sampler=Sampler.new() # Same numeric allocation lives through EVERY condition.
	for index: int in ORDER.size():
		await _condition("full_buffer",index,ORDER[index],null)
		if failures>0:break
	if failures==0:
		var resident: Node=Collector.new();root.add_child(resident);resident.stop()
		for index: int in ORDER.size():
			await _condition("resident_callback",index,ORDER[index],resident)
			if failures>0:break
		resident.stop();resident.queue_free()
		await process_frame
		active_collector=null
	source_after=Context.proof(receipt_sha)
	_check(source_after.get("window_control_verified",false),"same source/engine/warm receipt after BOTH control families")
	_check(conditions.size()==16 and conditions.all(func(condition:Dictionary)->bool:return condition.valid),"all sixteen ABBA/BAAB control windows completed without discarded failures")
	_check(Context.workload(main)==canonical,"entire paired control preserves original source/frame/config")
	_finish()


func _finish() -> void:
	if is_instance_valid(sampler):sampler.stop()
	if is_instance_valid(active_collector):active_collector.stop()
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":1,"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),
		"receipt_sha256":receipt_sha,"checks":checks,"failures":failures,"complete":failures==0 and conditions.size()==16,
		"source_proof_before":source_before,"source_proof_after":source_after,"environment":Context.environment(),
		"canonical_workload":canonical,"order":ORDER,"conditions":conditions,"monitor_support":monitor_support,
		"scope":"stationary yard/main+presenter stopped; common sampler in both conditions; callback-only and total buffer controls distinct",
		"limitations":"preloaded collector script shared even baseline; allocator/RSS retention and monitor lag retained; no corrected FPS, dynamic FX, sustained six-level or Android conclusion"},"  "))
	file.close()
	print("A3_COLLECTOR_OVERHEAD_TEST checks=%d failures=%d windows=%d output=%s" % [checks,failures,conditions.size(),directory])
	root.get_node("AudioDirector").pause_for_background()
	quit(0 if failures==0 else 1)
