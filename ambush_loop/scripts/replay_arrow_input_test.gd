extends SceneTree
## Bounded synthetic InputEventKey seam after authentic source bind.
const Guard := preload("res://scripts/test_storage_guard.gd")
var checks := 0
var failures := 0
var main: Node
var rows := []
func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("REPLAY_ARROW_FAIL "+message)
func _send(physical: int, logical: int, pressed: bool=true, echo: bool=false) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=physical
	event.keycode=logical
	event.pressed=pressed
	event.echo=echo
	main._unhandled_input(event)
func _case(label: String, physical: int, logical: int, expected: int, pressed: bool=true, echo: bool=false) -> void:
	main.replay.set_tick(100)
	main._apply_replay_scrub()
	_send(physical,logical,pressed,echo)
	_check(main.replay.scrub_tick==expected,label+" expected "+str(expected)+" got "+str(main.replay.scrub_tick))
	_check(not main.replay.playing,label+" original paused transport preserved")
	rows.append({"label":label,"physical":physical,"logical":logical,"pressed":pressed,"echo":echo,"tick":main.replay.scrub_tick,"expected":expected})
func _run() -> void:
	var path:=OS.get_environment("AMBUSH_NATIVE_RECORD_DIR").path_join("native-player-yard-record.bin")
	var raw_sha:=FileAccess.get_sha256(path)
	_check(raw_sha=="4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164","fixed original a05 native yard raw")
	if raw_sha!="4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164": quit(2); return
	var raw: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
	var source:=BattleLog.new()
	for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:source.set(key,raw[key])
	var preserved:=var_to_bytes(raw)
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main.battle_log=source
	main.phase=main.Phase.WON # Cold source bind only, never a new victory.
	main._on_replay_pressed()
	main.replay.pause()
	var live: Dictionary=main._snapshot_data().duplicate(true)
	var sim_state: Array=[main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]
	_case("logical-only right",0,KEY_RIGHT,106)
	_case("logical-only left",0,KEY_LEFT,94)
	_case("physical-only right",KEY_RIGHT,0,106)
	_case("physical-only left",KEY_LEFT,0,94)
	_case("physical right wins foreign logical left",KEY_RIGHT,KEY_LEFT,106)
	_case("physical left wins foreign logical right",KEY_LEFT,KEY_RIGHT,94)
	_case("released logical right",0,KEY_RIGHT,100,false)
	_case("echo logical right",0,KEY_RIGHT,100,true,true)
	_case("unknown key",0,0,100)
	_case("other logical shortcut keeps existing rule",0,KEY_P,100)
	main.replay.set_tick(1)
	_send(0,KEY_LEFT)
	_check(main.replay.scrub_tick==0 and not main.replay.playing,"logical-only left clamps0 and pauses")
	main.replay.set_tick(main.replay.max_tick()-2)
	_send(0,KEY_RIGHT)
	_check(main.replay.scrub_tick==main.replay.max_tick() and not main.replay.playing,"logical-only right clamps source terminal and pauses")
	main.replay.set_tick(100)
	main._toggle_pause_menu()
	_send(0,KEY_RIGHT)
	_check(main.pause_overlay.is_open() and main.replay.scrub_tick==100,"logical fallback cannot bypass original modal gate")
	main.pause_overlay.dismiss()
	_check(main._snapshot_data()==live and [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]==sim_state,"synthetic arrow seams preserve live/sim")
	var after := {}
	for key in raw: after[key]=source.get(key)
	_check(var_to_bytes(after)==preserved and FileAccess.get_sha256(path)==raw_sha,"source values and actual native raw bytes remain unchanged")
	var directory: String="res://build/asset_review/pr15-runtime/replay-arrow-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"producer_source_sha":"a05fa959093ef5b6733466091a04fbb46647f97b","raw_sha256":raw_sha,"checks":checks,"failures":failures,"rows":rows,"scope":"Synthetic InputEventKey dispatch directly into original unhandled-input seam over authentic a05 saved source. Cold3D node construction, not normal gameplay or native XTest/rendered/final FX-A3 acceptance."},"  "))
	file.close()
	root.get_node("AudioDirector").pause_for_background()
	print("REPLAY_ARROW_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
