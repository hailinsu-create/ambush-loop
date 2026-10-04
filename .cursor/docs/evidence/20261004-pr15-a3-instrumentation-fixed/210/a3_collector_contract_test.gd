extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Collector := preload("res://scripts/a3_render_metrics.gd")
const Provenance := preload("res://scripts/a3_provenance.gd")
var checks := 0
var failures := 0
var directory := ""


func _init() -> void:
	if not Guard.check(): quit(91);return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;print("A3_COLLECTOR_CONTRACT_FAIL "+message)


func _receipt_copy(receipt: Dictionary, label: String) -> String:
	var path := directory+"/"+label+".json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt))
	file.close()
	return path


func _backend_bytes(main: Node) -> PackedByteArray:
	return var_to_bytes([main.battle_log.events,main.battle_log.playback_snapshots,main.sim.tick,
		main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines])])


func _run() -> void:
	if DisplayServer.get_name()!="headless": quit(2);return
	directory="res://build/asset_review/pr15-runtime/a3-collector-contract-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var receipt_path := OS.get_environment("AMBUSH_A3_PROVENANCE_FILE")
	var consumer := OS.get_environment("AMBUSH_TEST_SOURCE_SHA")
	var proof := Provenance.verify(receipt_path,consumer)
	_check(proof.get("verified",false),"actual tracked project/asset/official engine/original record receipt verifies")
	if not proof.get("verified",false):
		print("A3_PROVENANCE_FAILURE ",proof)
		_finish();return
	var receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	_check(not Provenance.verify("",consumer).get("verified",false),"missing provenance fails closed")
	_check(not Provenance.verify(receipt_path,"0".repeat(40)).get("verified",false),"foreign consumer commit fails closed")
	var corrupt: Dictionary = receipt.duplicate(true);corrupt.engine.sha256="0".repeat(64)
	_check(Provenance.verify(_receipt_copy(corrupt,"wrong-engine"),consumer).get("reason")=="engine_bytes_mismatch","wrong actual executable hash rejected")
	corrupt=receipt.duplicate(true);corrupt.source_files[0].sha256="0".repeat(64)
	_check(Provenance.verify(_receipt_copy(corrupt,"wrong-source"),consumer).get("reason")=="source_bytes_mismatch","wrong actual source/asset hash rejected")
	corrupt=receipt.duplicate(true);corrupt.source_files.append(corrupt.source_files[0].duplicate(true))
	_check(Provenance.verify(_receipt_copy(corrupt,"duplicate-source"),consumer).get("reason")=="invalid_or_duplicate_source_path","duplicate source receipt cannot stand for missing project bytes")
	corrupt=receipt.duplicate(true);corrupt.source_files[0].path="../foreign.gd"
	_check(Provenance.verify(_receipt_copy(corrupt,"outside-source"),consumer).get("reason")=="invalid_or_duplicate_source_path","outside-root source entry rejected")
	_check(not receipt.producer_records.is_empty(),"functional suite includes actual immutable old record provenance")
	if not receipt.producer_records.is_empty():
		corrupt=receipt.duplicate(true);corrupt.producer_records[0].sha256="0".repeat(64)
		_check(Provenance.verify(_receipt_copy(corrupt,"wrong-record"),consumer).get("reason")=="record_bytes_or_attribution_mismatch","changed raw record bytes rejected without upgrading or rewriting")
	var name := "PIPELINE_COMPILATIONS_DRAW"
	_check(Collector.monitor_support(name,-1,"x11",true,"gl_compatibility").supported==false,"enum absence explicitly unavailable")
	_check(Collector.monitor_support(name,37,"headless",true,"gl_compatibility").supported==false,"headless pipeline explicitly unsupported")
	_check(Collector.monitor_support(name,37,"x11",true,"gl_compatibility").supported==null,"Compatibility pipeline support stays unknown despite enum availability")
	_check(Collector.monitor_support("MEMORY_STATIC",4,"x11",false,"gl_compatibility").supported==false,"release static memory zero cannot pretend availability")
	_check(Collector.monitor_support("OBJECT_ORPHAN_NODE_COUNT",10,"x11",false,"gl_compatibility").supported==false,"release orphan zero cannot pretend availability")
	_check(Collector.monitor_support("TIME_PROCESS",1,"headless",true,"gl_compatibility").supported==true,"headless process scalar remains documented available")
	var collector := Collector.new();collector.capacity=12;root.add_child(collector)
	_check(RenderingServer.frame_post_draw.is_connected(collector._sample),"collector hook connected before actual production scene load")
	collector.start()
	_check(RenderingServer.frame_post_draw.get_connections().filter(func(c:Dictionary)->bool:return c.callable==collector._sample).size()==1,"repeat start does not double-subscribe")
	collector.stop()
	_check(not RenderingServer.frame_post_draw.is_connected(collector._sample),"stop disconnects post-draw source")
	var payload_bytes := collector.storage_bytes()
	_check(payload_bytes==12*collector.column_count()*8,"all scalar payload allocated before sampling with exact bounded byte count")
	collector._sample() # Explicit functional callback, NOT an actual draw/performance sample.
	var cold := collector.row_at(0)
	_check(cold[Collector.COLUMNS.find("phase")]==-1 and cold[Collector.COLUMNS.find("presenter_valid")]==0,"no-host cold callback kept with unavailable source instead of fabricated phase")
	_check(cold[Collector.COLUMNS.find("measured")]==0,"headless callback cannot be a measured render frame")
	_check(cold[Collector.COLUMNS.find("render_counters_ready")]==0,"headless renderer never declared ready")
	_check(cold[Collector.COLUMNS.size()+Collector.MONITORS.find("RENDER_TOTAL_DRAW_CALLS_IN_FRAME")]==-1,"unsupported headless draw count uses explicit -1")
	root.get_node("GameSettings").pending_level_id="yard"
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main: Node = current_scene
	main.set_process(false)
	collector.follow_current_scene=false;collector.host=main
	var before := _backend_bytes(main)
	collector.mark("headless-manual-original-SCOUT",true,"",{"fixture":"actual original yard, main automatic process frozen; callbacks manual, not render metrics"})
	_check(not collector.reset_buffer(),"timed mark prevents accidental discard before raw sealing")
	_check(collector.save(directory)==ERR_BUSY,"CSV/provenance flush refused inside timed mark")
	collector._sample();collector._sample()
	var live := collector.row_at(2)
	_check(live[Collector.COLUMNS.find("level_id")]=="yard" and live[Collector.COLUMNS.find("phase")]==0,"actual saved presenter source identity read without recapture")
	_check(live[Collector.COLUMNS.find("main_auto_process")]==0,"explicit frozen source process is recorded")
	_check(live[Collector.COLUMNS.find("collector_usec")]>=0,"timer covers counters and completed table storage")
	_check(_backend_bytes(main)==before,"manual collector callbacks preserve actual original log/HP/ammo/inventory/positions")
	var scope: Array = collector.row_at(0).duplicate(true)
	for ignored: int in 20: collector._sample()
	_check(collector.row_count==12 and collector.overflow_rows==11,"bounded full table rejects exact overflow and keeps earlier rows")
	_check(collector.row_at(0)==scope,"capacity cannot silently overwrite first/cold raw row")
	_check(collector.storage_bytes()==payload_bytes,"retained numeric memory does not grow with sample count")
	collector.mark("headless-contract-flush",false)
	_check(collector.save(directory,{"scope":"headless manual-callback contract only; no actual Window/cold rendered frames/A3 performance acceptance"})==OK,"complete bounded raw/metadata sealed outside timing")
	var csv := FileAccess.open(directory+"/raw.csv",FileAccess.READ)
	var header := csv.get_csv_line()
	var count := 0;var widths := true
	while not csv.eof_reached():
		var line := csv.get_csv_line()
		if line.size()==1 and line[0].is_empty():continue
		count+=1;widths=widths and line.size()==header.size()
	csv.close()
	_check(count==12 and widths and header.size()==collector.column_count(),"CSV exports every retained row with exact header width")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"/metadata.json"))
	_check(saved.overflow_rows==11 and not saved.complete_buffer,"overflow makes receipt incomplete rather than accepted")
	_check(saved.source_proof_after.verified,"actual source/assets/engine/old raw unchanged after manual functional sampling")
	_check(saved.metadata.rss_ready_bytes>0 and saved.rss_save_bytes>0,"owned Linux process RSS endpoints distinguished from numeric payload/static memory")
	_check(collector.reset_buffer(),"stopped, untimed table can reuse fixed allocation after raw seal")
	_check(collector.row_count==0 and collector.storage_bytes()==payload_bytes,"explicit reset reuses payload without growth")
	var weak := weakref(main)
	main._return_to_title()
	await process_frame
	await process_frame
	collector.mark("headless-original-Title-unbind",false)
	collector._sample()
	_check(not is_instance_valid(weak.get_ref()) and collector.row_at(0)[Collector.COLUMNS.find("presenter_valid")]==0,"original Title frees host; stale collector binding becomes unavailable without dereference errors")
	collector.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("A3_COLLECTOR_CONTRACT_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	root.get_node("AudioDirector").pause_for_background()
	quit(0 if failures==0 else 1)
