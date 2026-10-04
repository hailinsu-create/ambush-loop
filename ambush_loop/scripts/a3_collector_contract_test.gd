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


func _collector_for_receipt(path: String, main: Node) -> Node:
	var original_path := OS.get_environment("AMBUSH_A3_PROVENANCE_FILE")
	OS.set_environment("AMBUSH_A3_PROVENANCE_FILE",path) # Owned explicit receipt clone only.
	var target := Collector.new();target.capacity=8;root.add_child(target);target.stop()
	OS.set_environment("AMBUSH_A3_PROVENANCE_FILE",original_path)
	target.follow_current_scene=false;target.host=main
	return target


func _seal_receipt_cases(main: Node, receipt: Dictionary, receipt_path: String) -> void:
	var original_bytes := _backend_bytes(main)
	var original_receipt_hash := FileAccess.get_sha256(receipt_path)
	var consumer := OS.get_environment("AMBUSH_TEST_SOURCE_SHA")
	var positive: Node = _collector_for_receipt(receipt_path,main)
	positive.mark("headless-manual-valid-first-chunk",true)
	positive._sample();positive._sample()
	var first_path := directory+"/valid-first-chunk"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(first_path))
	positive.mark("headless-valid-flush",false)
	_check(positive.save(first_path)==OK,"nonoverflow headless functional chunk seals with unchanged full source/warm receipt")
	var first_hash := FileAccess.get_sha256(first_path+"/raw.csv")
	var first_saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(first_path+"/metadata.json"))
	_check(first_saved.receipt_stable and first_saved.warm_import_proof_complete and first_saved.chunk_source_and_buffer_valid and not first_saved.run_incomplete,"positive functional seal distinguishes valid buffer/proof from render measurement")
	_check(first_saved.metadata.source_proof_before.receipt_sha256==original_receipt_hash and first_saved.source_proof_after.receipt_sha256==original_receipt_hash,"both positive proofs pin original receipt bytes")
	var last_frame: int = int(positive.row_at(positive.row_count-1)[0])
	var last_usec: int = int(positive.row_at(positive.row_count-1)[1])
	_check(positive.reset_buffer(),"valid stopped/untimed sealed functional chunk can reset without incomplete acknowledgement")
	_check(positive.row_count==0 and positive.storage_bytes()==8*positive.column_count()*8 and positive.run_overflow_rows==0 and not positive._run_incomplete,"valid reset retains fixed allocation and complete lifetime state")
	positive.mark("headless-manual-valid-second-chunk",true)
	positive._sample();positive._sample()
	var second_path := directory+"/valid-second-chunk"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(second_path))
	positive.mark("headless-second-flush",false)
	_check(positive.save(second_path)==OK,"second unique functional chunk seals after reset")
	_check(positive.row_at(0)[0]>last_frame and positive.row_at(0)[1]>last_usec and FileAccess.get_sha256(first_path+"/raw.csv")==first_hash,"absolute frames/time advance across reset and first raw CSV remains exact")
	_check(positive.row_at(0)[4]==0 and positive.row_at(1)[4]==0 and positive.row_at(1)[34]==0,"headless valid chunks remain unmeasured with render counters unavailable")
	positive.queue_free()

	var empty_receipt: Dictionary = receipt.duplicate(true);empty_receipt.imported_cache=[]
	empty_receipt.cache_scope="explicit functional clone excluding loaded imported resources"
	var empty_path := _receipt_copy(empty_receipt,"valid-source-empty-warm-inventory")
	var empty_proof := Provenance.verify(empty_path,consumer)
	_check(empty_proof.get("verified",false) and empty_proof.imported_cache_files_verified==0,"empty warm inventory clone verifies only source, not loaded-resource performance")
	var empty: Node = _collector_for_receipt(empty_path,main)
	empty.mark("headless-empty-warm-proof",true);empty._sample();empty._sample()
	_check(empty.row_at(1)[4]==0 and empty.row_at(1)[5]=="warm_import_proof_incomplete","actual empty loaded-resource proof is preserved but excluded in raw")
	var empty_chunk := directory+"/empty-warm-rejected";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(empty_chunk))
	empty.mark("empty-warm-flush",false)
	_check(empty.save(empty_chunk)==ERR_INVALID_DATA,"source-only receipt cannot seal accepted loaded-resource performance chunk")
	var empty_saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(empty_chunk+"/metadata.json"))
	_check(empty_saved.receipt_stable and not empty_saved.warm_import_proof_complete and not empty_saved.chunk_source_and_buffer_valid and empty_saved.run_incomplete,"empty inventory rejection receipt preserves distinct stable-source and missing-load facts")
	_check(not empty.reset_buffer(),"empty loaded-resource proof cannot reset as an accepted chunk")
	empty.queue_free()

	var changed_path := _receipt_copy(receipt,"valid-source-receipt-changed-after-hook")
	var changed: Node = _collector_for_receipt(changed_path,main)
	changed.mark("headless-receipt-stability",true);changed._sample();changed._sample()
	var before_hash: String = changed.metadata.source_proof_before.receipt_sha256
	var changed_receipt: Dictionary = receipt.duplicate(true)
	changed_receipt.functional_receipt_note="same source/engine/record/cache, changed receipt after hook"
	_check(_receipt_copy(changed_receipt,"valid-source-receipt-changed-after-hook")==changed_path,"only owned receipt clone replaced outside manual sampling")
	var changed_proof := Provenance.verify(changed_path,consumer)
	_check(changed_proof.get("verified",false) and changed_proof.receipt_sha256!=before_hash,"changed receipt still individually verifies identical source bytes, demonstrating stability gate necessity")
	var changed_chunk := directory+"/changed-receipt-rejected";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(changed_chunk))
	changed.mark("changed-receipt-flush",false)
	_check(changed.save(changed_chunk)==ERR_INVALID_DATA,"individually valid before/after receipts cannot substitute for one fixed receipt")
	var changed_saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(changed_chunk+"/metadata.json"))
	_check(changed_saved.metadata.source_proof_before.verified and changed_saved.source_proof_after.verified and changed_saved.warm_import_proof_complete and not changed_saved.receipt_stable and not changed_saved.chunk_source_and_buffer_valid,"changed-receipt raw/metadata retains both valid proofs and explicit mismatch")
	_check(not changed.reset_buffer(),"changed provenance cannot reset as accepted chunk")
	changed.queue_free()
	_check(_backend_bytes(main)==original_bytes and FileAccess.get_sha256(receipt_path)==original_receipt_hash and OS.get_environment("AMBUSH_A3_PROVENANCE_FILE")==receipt_path,"all functional seal/receipt clones preserve original source/backend/receipt/env")


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
	var corrupt: Dictionary = receipt.duplicate(true);corrupt.consumer_game_tree="0".repeat(40)
	_check(Provenance.verify(_receipt_copy(corrupt,"wrong-game-tree"),consumer).get("reason")=="expected_game_tree_mismatch","receipt tree bound to independently supplied fixed Git game tree")
	corrupt=receipt.duplicate(true);corrupt.engine.sha256="0".repeat(64)
	_check(Provenance.verify(_receipt_copy(corrupt,"wrong-engine"),consumer).get("reason")=="engine_bytes_mismatch","wrong actual executable hash rejected")
	corrupt=receipt.duplicate(true);corrupt.source_files[0].sha256="0".repeat(64)
	_check(Provenance.verify(_receipt_copy(corrupt,"wrong-source"),consumer).get("reason")=="source_bytes_mismatch","wrong actual source/asset hash rejected")
	corrupt=receipt.duplicate(true);corrupt.source_files.pop_back()
	_check(Provenance.verify(_receipt_copy(corrupt,"missing-source"),consumer).get("reason")=="source_tree_mismatch","nonempty subset cannot verify complete fixed source tree")
	corrupt=receipt.duplicate(true);corrupt.source_files.append(corrupt.source_files[0].duplicate(true))
	_check(Provenance.verify(_receipt_copy(corrupt,"duplicate-source"),consumer).get("reason")=="invalid_or_duplicate_source_path","duplicate source receipt cannot stand for missing project bytes")
	corrupt=receipt.duplicate(true);corrupt.source_files[0].path="../foreign.gd"
	_check(Provenance.verify(_receipt_copy(corrupt,"outside-source"),consumer).get("reason")=="invalid_or_duplicate_source_path","outside-root source entry rejected")
	_check(not receipt.producer_records.is_empty(),"functional suite includes actual immutable old record provenance")
	_check(proof.get("complete_source_tree_verified",false) and proof.get("imported_cache_files_verified",0)>0,"all fixed tracked source tree and existing warm imported cache bytes verified")
	corrupt=receipt.duplicate(true);corrupt.imported_cache.pop_back()
	_check(Provenance.verify(_receipt_copy(corrupt,"missing-cache"),consumer).get("reason")=="imported_cache_inventory_incomplete","missing actual warm imported resource cannot masquerade as complete cache proof")
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
	_check(not collector.reset_buffer(),"even untimed stopped table requires successful raw seal before reset")
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
	_check(collector.save(directory,{"scope":"headless manual-callback contract only; no actual Window/cold rendered frames/A3 performance acceptance"})==ERR_INVALID_DATA,"overflow raw/metadata retained while validity gate rejects chunk")
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
	_check(not collector.reset_buffer(),"invalid chunk cannot reset as an accepted performance chunk")
	_check(collector.reset_buffer(true),"explicit acknowledged incomplete functional archive can reuse sealed fixed allocation")
	_check(collector.row_count==0 and collector.storage_bytes()==payload_bytes,"explicit reset reuses payload without growth")
	_check(collector.run_overflow_rows==11 and collector._run_incomplete,"reset never erases lifetime overflow or invalid-run state")
	_check(collector.save(directory)==ERR_ALREADY_IN_USE,"reuse cannot overwrite previously sealed cold raw file")
	_seal_receipt_cases(main,receipt,receipt_path)
	var weak: WeakRef = weakref(main)
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
