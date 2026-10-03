extends "res://scripts/title_menu_viewport_test.gd"
## Fresh original title -> yard entry. Native inputs, actual engine callbacks.
## No tutorial-seen/unlock/win/loadout/reference/vacuum fixture.
const Weapons := preload("res://scripts/raid/weapon_catalog.gd")
const PLAYER_PLANS := [
	["yard", [1,2,5], [90.0,180.0,180.0]],
	["warehouse", [1,3,5], [180.0,0.0,180.0]],
	["pump", [1,4,5], [90.0,0.0,180.0]],
	["railcut", [1,4,5], [270.0,270.0,180.0]],
	["depot", [1,4,5], [270.0,270.0,180.0]],
	["radio", [1,4,5], [270.0,90.0,270.0]],
]
var journey_rows := []

func _settle(frames: int = 3) -> void:
	await create_timer(0.2).timeout
	for i in frames: await process_frame
	for i in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func _write_journey() -> void:
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/first-visit-journey-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"journey":journey_rows,"captures":captures,"native_inputs":input_rows,"a0_preview_feature":OS.has_feature("a0_preview"),"scope":"Fresh isolated original title/main flow; real XTest and engine callbacks. Existing a0_preview enabled only in the isolated PCK. No tutorial/progress/resource grants/reference/vacuum helpers. Only report actually reached missions/waves; source-derived deployment strategy is not a stranger playtest."}, "  "))

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FIRST_VISIT_FAIL " + sample + " " + message)

func _save_journey() -> void:
	root.get_node("AudioDirector").pause_for_background()
	_write_journey()
	print("FIRST_VISIT_JOURNEY_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _run() -> void:
	settings = root.get_node("GameSettings")
	if DisplayServer.get_name() == "headless":
		print("FIRST_VISIT_JOURNEY requires native rendered verification")
		quit(2)
		return
	root.position = Vector2i.ZERO
	var gameplay := OS.get_environment("AMBUSH_JOURNEY_SCOPE") in ["yard","all"]
	root.size = Vector2i(1280, 720) if gameplay else Vector2i(1600, 720)
	root.content_scale_factor = 1.0 if gameplay else 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	sample = "player_yard_1280_100_desktop" if gameplay else "first_visit_yard_1600_200_desktop"
	await _title()
	_check(not settings.has_progress() and not settings.has_seen_tutorial("yard"), "fresh isolated player has no progress or completed tutorial")
	await _click(main.start_btn)
	_check(main.mission_select_visible(), "original native Start opens missions")
	await _click(main._mission_btns[0])
	_check(main.briefing_visible() and main.pending_mission_id() == "yard", "original native available yard opens brief")
	await _click(main._brief_go)
	await _settle()
	main = current_scene
	_check(main.scene_file_path == "res://scenes/main.tscn" and main.level.level_id == "yard" and main.phase == main.Phase.SETUP, "ordinary fresh original entry reaches actual yard SCOUT")
	_check(main.tutorial_overlay.is_open(), "first visit naturally shows original tutorial")
	_check(main.operators.all(func(op) -> bool: return op.weapon_id == "knife"), "first visit retains authored knife-only loadouts")
	if not await _tutorial():
		_save_journey()
		return
	if gameplay:
		_check(OS.has_feature("a0_preview") and main.presentation_3d != null, "packed original main naturally creates its existing 3D presenter")
		if main.presentation_3d == null:
			_save_journey()
			return
		view = main.presentation_3d
		for plan in PLAYER_PLANS:
			if not await _mission(plan): break
			if OS.get_environment("AMBUSH_JOURNEY_SCOPE") == "yard": break
	_save_journey()

func _tutorial() -> bool:
	var tutorial = main.tutorial_overlay
	for page in tutorial.pages_for(main.level.level_id).size():
		await _settle()
		var rect: Rect2 = tutorial._next.get_global_rect()
		var reachable := _hit_visible(tutorial._next)
		rows.append({"level":main.level.level_id,"page":page,"viewport":_rect(root.get_visible_rect()),"next_rect":_rect(rect),"next_reachable":reachable,"body":tutorial._body.text,"phase":main.phase})
		await _modal_capture(sample + "_tutorial_page" + str(page))
		_check(reachable, "original tutorial next/Start is fully reachable on page " + str(page) + " " + str(rect))
		if not reachable:
			return false
		await _click(tutorial._next)
	_check(not tutorial.is_open() and settings.has_seen_tutorial(main.level.level_id), "native complete pages dismisses tutorial and writes original seen state")
	_check(main.phase == main.Phase.SETUP and not main._modal_blocks_input(), "first visit permits ordinary SCOUT commands")
	return not tutorial.is_open()

func _wait_until(predicate: Callable, seconds: float, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds*1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
		if main.phase == main.Phase.FAILED: break
	var ok: bool = predicate.call()
	_check(ok, label + " actual phase=" + str(main.phase) + " status=" + str(main.status_label.text))
	return ok

func _world_click(pos: Vector2, height: float, label: String, button: int = 1) -> bool:
	var at: Vector2
	var reachable := false
	for turn in 13:
		at = view.rig.project_logic(pos,height)
		reachable = root.get_visible_rect().grow(-2).has_point(at) and not view.pointer_over_ui(at)
		if reachable: break
		if turn < 12: await _click(_button(view._camera_controls,"↷"))
	rows.append({"action":label,"target":[pos.x,pos.y],"screen":[at.x,at.y],"camera_yaw":view.rig.yaw_deg,"reachable":reachable,"picked_kind":view.pick_at(at).get("kind","invalid")})
	_check(reachable, "native world target is in viewport outside UI " + label)
	if not reachable: return false
	await _native_click(main.get_node("HUD/Root"),button,at)
	await _settle()
	return true

func _collect(family: String, index: int) -> bool:
	await _key(str(index+1))
	_check(main.selected == main.operators[index], "native number selects original operator " + str(index))
	var stash: Node2D
	for item in main.raid_stashes:
		if Weapons.family_of(item.kind) == family and not item.collected:
			stash = item
			break
	_check(stash != null, "authored stash exists for " + family)
	if stash == null: return false
	var kind: String = stash.kind
	var stash_reference: WeakRef = weakref(stash)
	var before: Vector2 = main.selected.global_position
	if not await _world_click(stash.global_position,0.55,"stash_"+kind): return false
	if not await _wait_until(func() -> bool:
		var current = stash_reference.get_ref()
		return current == null or current.collected,
		120,"ordinary walking and0.4s search collect "+kind):
		await _modal_capture(sample+"_stash_blocked_"+family)
		return false
	journey_rows.append({"level":main.level.level_id,"action":"authored stash collected through original input/process","operator":index,"kind":kind,"start":[before.x,before.y],"end":[main.selected.global_position.x,main.selected.global_position.y],"weapon":main.selected.weapon_id,"ammo":main.selected.ammo})
	_write_journey()
	return true

func _deploy(plan: Array) -> bool:
	for index in 3:
		await _key(str(index+1))
		var slot = main.cover_slots[plan[1][index]]
		var before: Vector2 = main.selected.global_position
		if not await _world_click(slot.global_position,0.08,"cover_"+str(slot.slot_id)): return false
		rows.append({"action":"native cover outcome","operator":index,"target_slot":slot.slot_id,"selected_id":main.selected.op_id,"before":[before.x,before.y],"target":[slot.global_position.x,slot.global_position.y],"distance_before":before.distance_to(slot.global_position),"after":[main.selected.global_position.x,main.selected.global_position.y],"actual_slot":main.selected.slot.slot_id if main.selected.slot else -1,"status":main.status_label.text})
		_check(main.selected.slot == slot, "original native cover command mounts intended pad")
		if main.selected.slot != slot:
			await _modal_capture(sample+"_cover"+str(slot.slot_id)+"_blocked")
			return false
		var target: float = plan[2][index]
		for turn in 24:
			var diff: float = wrapf(target-main.selected.facing_deg,-180.0,180.0)
			if absf(diff) < 0.1: break
			await _key("d" if diff > 0.0 else "a")
		_check(absf(wrapf(target-main.selected.facing_deg,-180.0,180.0))<0.1,"native15deg rotation reaches intended world facing")
	return true

func _mission(plan: Array) -> bool:
	var id: String = plan[0]
	sample = "player_"+id+"_1280_100_desktop"
	_check(main.level.level_id == id and main.phase == main.Phase.SETUP,"original progression reaches next SCOUT "+id)
	print("PLAYER_JOURNEY_MISSION ",id)
	for index in 3:
		if not await _collect(["rifle","mg","scout"][index],index): return false
		_check(Weapons.family_of(main.selected.weapon_id)==["rifle","mg","scout"][index],"ordinary firearm pickup equips authored family")
	if not await _collect("grenade",0): return false
	if id in ["depot","radio"] and not await _collect("mine",0): return false
	if not await _deploy(plan): return false
	if main.level.has_ammo_pack:
		await _key("2")
		await _click(main.pack_button)
		_check(main.selected.has_ammo_pack,"original native UI assigns authored single ammo pack")
	if id == "warehouse":
		await _key("2")
		await _key("f")
	if id in ["depot","radio"]:
		await _key("1")
		await _key("Tab")
		if not await _world_click(main.grid.cell_to_world_center(Vector2i(7,11)),0.0,"authored_tripwire"): return false
		_check(not main.raid_mines.is_empty(),"native tool consumes collected mine")
	await _modal_capture(sample+"_armed_scout")
	for wave in main.level.wave_count():
		await _click(main.alarm_button)
		_check(main.phase == main.Phase.WATCHING and main.raid.wave_index == wave,"ordinary alarm/next-wave enters authored ALERT")
		if main.phase != main.Phase.WATCHING: return false
		await _click(main.pause_button)
		await _modal_capture(sample+"_wave"+str(wave)+"_alert")
		await _click(main.pause_button)
		if not await _wait_until(func() -> bool: return main.phase == main.Phase.SWEEP,180,"actual engine watch clears wave "+str(wave)):
			await _modal_capture(sample+"_wave"+str(wave)+"_failed")
			journey_rows.append({"level":id,"wave":wave,"phase":main.phase,"failure":main.fail_reason,"tick":main.sim.tick})
			return false
		await _modal_capture(sample+"_wave"+str(wave)+"_sweep")
		journey_rows.append({"level":id,"wave":wave,"action":"ordinary engine wave cleared","tick":main.sim.tick,"events":main.battle_log.events.size(),"ammo":main.operators.map(func(op) -> int: return op.ammo)})
		_write_journey()
	await _click(main.alarm_button)
	_check(main.phase==main.Phase.WON and main.raid.waves_cleared==main.level.wave_count(),"ordinary final SWEEP extract wins "+id)
	await _modal_capture(sample+"_won")
	journey_rows.append({"level":id,"action":"original WON/progress","waves":main.raid.waves_cleared,"terminal":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"progress":settings.progress_level_id()})
	_write_journey()
	await _click(main.continue_button)
	if id == "radio":
		_check(main.credits_overlay.is_open(),"ordinary final CTA opens original campaign credits")
		return true
	if not await _wait_until(func() -> bool: return not main.night_handoff.is_open(),15,"original night handoff finishes"): return false
	return await _tutorial()
