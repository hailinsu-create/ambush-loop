extends "res://scripts/shot_fx_boundary_test.gd"
## Explicit foreign pre-log fixture: preserve original attack, refuse false FX.

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_SHOOTER_FAIL "+message)

func _mismatched_shooter() -> void:
	var pair: Array=await _reset()
	var actual: OperatorUnit=pair[0]
	var target: EnemyRunner=pair[1]
	var claimed: OperatorUnit=main.operators[1]
	actual.apply_weapon("kar98k",true)
	actual.ammo=3
	actual.ammo_pool["rifle"]=3
	actual.ammo_pool["pistol"]=0
	actual.has_ammo_pack=false
	actual.ammo_pack_used=false
	actual.shot_cd=0.0
	actual.fire_permitted=true
	claimed.global_position=Vector2(104,80)
	claimed.apply_weapon("mp40",true)
	var event:=_event(claimed,target)
	var original:=event.duplicate(true)
	var before:=var_to_bytes(event)
	var hp_before:=target.hp
	var claimed_ammo:=claimed.ammo
	var callbacks := [0]
	actual.fired_shot.connect(func(_op:OperatorUnit,_pos:Vector2)->void:callbacks[0]+=1,CONNECT_ONE_SHOT)
	var fired: bool=main._try_fire_with_recorded_fx(actual,target,event)
	_check(fired and actual.ammo==2 and callbacks[0]==1,"exact actual A/id1 original success/callback/ammo3to2 is preserved")
	_check(hp_before==100.0 and target.hp==52.0 and claimed.ammo==claimed_ammo,"exact target original HP100to52 and claimed B/id2 ammo unchanged")
	_check(not event.payload.has("fx") and var_to_bytes(event)==before,"actual A cannot confirm claimed B/MP40 source or mutate its prelogged event")
	rows.append({"case":"exact-source183-foreign-shooter","actual_source_id":actual.op_id,"claimed_source_id":claimed.op_id,"actual_gun":actual.weapon_id,"claimed_gun":claimed.weapon_id,"actual_ammo":actual.ammo,"claimed_ammo":claimed.ammo,"hp_before":hp_before,"hp_after":target.hp,"original_callback_count":callbacks[0],"original_event":original,"event_after":event,"scope":"explicit valid currentlog B event passed to actual original A backend attack, not a demonstrated player UI path"})

func _run() -> void:
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	await _mismatched_shooter()
	root.get_node("AudioDirector").pause_for_background()
	var directory: String="res://build/asset_review/pr15-runtime/shot-fx-shooter-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"scope":"Exact original backend foreign-shooter source fixture. No ordinary-player route/render/native/FINAL/A3/device acceptance."},"  "))
	file.close()
	print("SHOT_FX_SHOOTER_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
