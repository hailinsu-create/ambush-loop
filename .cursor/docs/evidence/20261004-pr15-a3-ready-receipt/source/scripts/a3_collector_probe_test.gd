extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Collector := preload("res://scripts/a3_render_metrics.gd")
var checks:=0
var failures:=0

func _init() -> void:
	if not Guard.check():quit(91);return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("A3_COLLECTOR_PROBE_FAIL "+message)

func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,720);root.position=Vector2i.ZERO;root.content_scale_factor=1.0
	var collector:=Collector.new();root.add_child(collector) # Hook and source verification BEFORE scene creation.
	collector.mark("cold-production-scene-first-load",false,"cold_scene_loading")
	root.get_node("GameSettings").pending_level_id="yard"
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main:Node=current_scene
	main.set_process(false) # Explicit frozen-render instrumentation control.
	var before:=var_to_bytes([main.battle_log.events,main.battle_log.playback_snapshots,main.sim.tick,main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines])])
	collector.host=main
	collector.mark("actual-SCOUT-frozen-render-probe",true)
	var start:=Time.get_ticks_usec()
	while Time.get_ticks_usec()-start<3_000_000:await process_frame
	collector.mark("flush",false)
	collector.stop()
	var directory:="res://build/asset_review/pr15-runtime/a3-collector-probe-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(collector.row_count>5,"actual post-draw collector receives original rendered frames")
	var rows:Array=[]
	for index:int in collector.row_count:rows.append(collector.row_at(index))
	_check(rows.all(func(row:Array)->bool:return row.size()==collector.column_count()),"all raw rows carry exact scalar header width")
	_check(rows.slice(1).all(func(row:Array)->bool:return row[2]>0 and row[30]>=0),"actual intervals and write-inclusive instrumentation usecs are positive/finite")
	_check(var_to_bytes([main.battle_log.events,main.battle_log.playback_snapshots,main.sim.tick,main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines])])==before,"collector never mutates frozen original battle/inventory/positions/record")
	_check(collector.metadata.source_proof_before.get("verified",false),"tracked source/engine/record proof verified before timing")
	_check(collector.overflow_rows==0 and collector.symbol_overflow==0,"all original raw rows retained without buffer overflow")
	_check(collector.save(directory,{"scope":"cold-first-scene plus three-second explicit frozen SCOUT instrumentation probe; not six-phase/A3 sustained/device acceptance"})==OK,"flush outside timing succeeds")
	print("A3_COLLECTOR_PROBE_TEST checks=%d failures=%d rows=%d output=%s" % [checks,failures,collector.row_count,directory])
	root.get_node("AudioDirector").pause_for_background()
	quit(0 if failures==0 else 1)
