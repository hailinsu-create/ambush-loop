extends SceneTree
## Original command movement, followed by explicit saved-pose reader fixtures.
const Guard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const READER_PATH := "res://scripts/presentation/movement_dust_frame.gd"
var main: Node
var checks:=0
var failures:=0
var rows: Array=[]
var captures: Array=[]
var directory: String
var pool: Node3D

func _init() -> void:
	if not Guard.check():quit(91);return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("MOVEMENT_DUST_FAIL "+message)

func _state() -> PackedByteArray:
	return var_to_bytes([main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,main.battle_log.events,main.battle_log.snapshots,main.battle_log.playback_snapshots,main.battle_log.attempt_id,main.battle_log.wave_id,main.battle_log.terminal_tick,main.battle_log.playback_terminal_tick,main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines,op.stance,op.sprinting,op.move_path,op._path_i])])

func _run() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	directory="res://build/asset_review/pr15-runtime/movement-dust-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main._select_op(0)
	var op:OperatorUnit=main.selected
	var start:=op.global_position
	var original_hp:=op.hp
	var original_inventory:=var_to_bytes([op.ammo,op.grenades,op.mines,op.pack.items()])
	var event_count:int=main.battle_log.events.size()
	var destination:Vector2=main.grid.cell_to_world_center(Vector2i(25,17))
	_check(main.phase==main.Phase.SETUP and not main.grid.is_blocked(25,17),"actual original SCOUT and open destination reached")
	main._command_move_selected(destination)
	_check(op.is_moving(),"original SCOUT command path accepted without granting position or inventory")
	for index in 20:main._process(1.0/60.0)
	var data:Dictionary=main._snapshot_data()
	var moving:Dictionary=data.ops.filter(func(item:Dictionary)->bool:return item.id==op.op_id).front()
	_check(op.global_position!=start and op.is_moving() and moving.moving and moving.action=="walk" and moving.pos==op.global_position,"actual original command ticks move and save exact walk pose/position")
	_check(op.hp==original_hp and var_to_bytes([op.ammo,op.grenades,op.mines,op.pack.items()])==original_inventory and main.battle_log.events.size()==event_count,"original command movement retains HP/inventory/event statistics")
	var original:=_state()
	var frame:=ViewState.capture(main)
	_check(data.get("movement_fx_schema")==1 and frame.get("movement_fx_schema")==1,"planned versioned saved movement cue interface exists")
	pool=main.presentation_3d.get_node_or_null("MovementDust")
	_check(pool!=null and ResourceLoader.exists(READER_PATH),"planned strict saved movement reader and presenter pool exist")
	if pool!=null and ResourceLoader.exists(READER_PATH):
		pool.update_frame(frame,false)
		var active:Array=pool.diagnostics().active
		_check(active.any(func(item:Dictionary)->bool:return item.group=="ops" and item.id==op.op_id and item.center==Space.logic_to_world(op.global_position)),"actual moving source reaches original reader/pool world point")
		rows.append({"case":"actual-SCOUT-command-walk","from":start,"current":op.global_position,"source":moving,"diagnostics":pool.diagnostics()})
	_check(_state()==original,"capture and presentation never mutate original movement/backend/log")
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"actual original SCOUT command movement; explicit saved-pose/backend/corrupt fixtures later. Not native/full13/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("MOVEMENT_DUST_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
