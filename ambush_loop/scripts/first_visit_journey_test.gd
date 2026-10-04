extends "res://scripts/title_menu_viewport_test.gd"
## Original title -> fresh yard or hash-pinned actual player save Continue.
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
var progress_seed := {}
var deploy_round := 0

class NativeWorldTrace extends Node:
	var suite: SceneTree
	var host: Node
	var presenter: Node3D
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var pick: Dictionary = presenter.pick_at(event.position)
			suite.rows.append({"action":"observed native mouse event","pressed":event.pressed,"device":event.device,"at":[event.position.x,event.position.y],"phase":host.phase,"tool":host.tool,"selected_id":host.selected.op_id if host.selected else -1,"ui_blocked":presenter.pointer_over_ui(event.position),"pick_kind":pick.get("kind","invalid"),"pick_id":str(pick.get("id","")),"pick_pos":str(pick.get("pos",Vector2.INF)),"ticks_msec":Time.get_ticks_msec()})

func _settle(frames: int = 3) -> void:
	await create_timer(0.2).timeout
	for i in frames: await process_frame
	for i in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func _write_journey() -> void:
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/first-visit-journey-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"window":[root.size.x,root.size.y],"content_scale_factor":root.content_scale_factor,"checks":checks,"failures":failures,"rows":rows,"journey":journey_rows,"captures":captures,"native_inputs":input_rows,"progress_seed":progress_seed,"a0_preview_feature":OS.has_feature("a0_preview"),"scope":"Isolated original title/main flow; fresh start or byte-identical pinned actual player save and native Continue. Real XTest and engine callbacks. Existing a0_preview enabled only in the isolated PCK. No tutorial/progress/resource grants/reference/vacuum helpers. Only report actually reached missions/waves; source-derived deployment strategy is not a stranger playtest."}, "  "))

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
	var scope := OS.get_environment("AMBUSH_JOURNEY_SCOPE")
	var resumed := OS.get_environment("AMBUSH_JOURNEY_START") == "resume"
	var gameplay := scope in ["yard","all","warehouse","remaining"]
	root.size = Vector2i(1280, 720) if gameplay else Vector2i(1600, 720)
	root.content_scale_factor = 1.0 if gameplay else 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	sample = "player_warehouse_1280_100_desktop" if resumed else ("player_yard_1280_100_desktop" if gameplay else "first_visit_yard_1600_200_desktop")
	await _title()
	if resumed:
		var receipt_path := OS.get_environment("AMBUSH_JOURNEY_SEED_RECEIPT")
		_check(FileAccess.file_exists(receipt_path), "resumed journey pins original player save receipt")
		if not FileAccess.file_exists(receipt_path):
			_save_journey()
			return
		progress_seed = JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
		_check(progress_seed.run_id == OS.get_environment("AMBUSH_TEST_RUN_ID"), "seed belongs to this guarded run")
		for name in progress_seed.files:
			_check(FileAccess.get_sha256("user://"+name) == progress_seed.files[name].sha256, "original player ConfigFile retained byte for byte " + name)
		_check(settings.has_progress() and settings.progress_level_id() == "warehouse" and settings.has_seen_tutorial("warehouse"), "inherited actual yard win naturally exposes warehouse Continue")
		await _click(main.continue_btn)
	else:
		_check(not settings.has_progress() and not settings.has_seen_tutorial("yard"), "fresh isolated player has no progress or completed tutorial")
		await _click(main.start_btn)
		_check(main.mission_select_visible(), "original native Start opens missions")
		await _click(main._mission_btns[0])
		_check(main.briefing_visible() and main.pending_mission_id() == "yard", "original native available yard opens brief")
		await _click(main._brief_go)
	await _settle()
	main = current_scene
	_check(main.scene_file_path == "res://scenes/main.tscn" and main.level.level_id == ("warehouse" if resumed else "yard") and main.phase == main.Phase.SETUP, "ordinary original title entry reaches actual SCOUT")
	_check(main.tutorial_overlay.is_open() == (not resumed), "original tutorial state matches actual player history")
	_check(main.operators.all(func(op) -> bool: return op.weapon_id == "knife"), "first visit retains authored knife-only loadouts")
	if not resumed and not await _tutorial():
		_save_journey()
		return
	if gameplay:
		_check(OS.has_feature("a0_preview") and main.presentation_3d != null, "packed original main naturally creates its existing 3D presenter")
		if main.presentation_3d == null:
			_save_journey()
			return
		view = main.presentation_3d
		var trace := NativeWorldTrace.new()
		trace.suite = self
		trace.host = main
		trace.presenter = view
		root.add_child(trace)
		for plan in PLAYER_PLANS:
			if resumed and plan[0] == "yard": continue
			if not await _mission(plan): break
			if scope in ["yard","warehouse"]: break
	_save_journey()

func _set_tool(wanted: int) -> bool:
	for step in 4:
		if main.tool == wanted: break
		await _click(main.tool_button)
	_check(main.tool == wanted, "native original ToolButton reaches tool " + str(wanted))
	return main.tool == wanted

func _inventory() -> Array:
	return main.operators.map(func(op) -> Dictionary: return {"id":op.op_id,"alive":op.alive,"pos":[op.global_position.x,op.global_position.y],"ammo":op.ammo,"pool":op.ammo_pool.duplicate(true),"pack":op.pack.slots.duplicate(true),"mines":op.mines,"ammo_pack_used":op.ammo_pack_used})

func _place_mine(cell: Vector2i) -> bool:
	await _key("1")
	if not await _set_tool(main.Tool.DEPLOY): return false
	var at: Vector2 = main.grid.cell_to_world_center(cell)
	if not await _world_click(at,0.02,"walk_near_mine_site"): return false
	if not await _wait_until(func() -> bool: return not main.selected.is_moving() and main.selected.global_position.distance_to(at)<=64.0,120,"original walk reaches mine placement range"): return false
	if not await _set_tool(main.Tool.TRIPWIRE): return false
	var before: int = main.selected.mines
	var placed: int = main.raid_mines.size()
	if not await _world_click(at,0.02,"place_carried_mine"): return false
	var ok: bool = main.selected.mines == before-1 and main.raid_mines.size() == placed+1
	_check(ok, "native mine tool consumes exactly one carried mine and creates one raid mine")
	journey_rows.append({"level":main.level.level_id,"action":"native walked and planted carried mine","phase":main.phase,"site":[at.x,at.y],"operator_pos":str(main.selected.global_position),"before":before,"after":main.selected.mines,"mines_before":placed,"mines_after":main.raid_mines.size(),"status":main.status_label.text})
	await _modal_capture(sample+"_mine_placed_wave"+str(main.raid.wave_index))
	if not await _set_tool(main.Tool.DEPLOY): return false
	return ok

func _sweep(plan: Array, wave: int) -> bool:
	_check(main.phase == main.Phase.SWEEP, "real SWEEP opens ordinary loot commands")
	var available := []
	for loot in main.loot_piles:
		if is_instance_valid(loot) and not loot.collected:
			available.append({"kind":loot.kind,"amount":loot.ammo_amount,"pos":str(loot.global_position)})
	journey_rows.append({"level":main.level.level_id,"wave":wave,"action":"SWEEP inventory and actual remaining drops","inventory":_inventory(),"drops":available})
	for pickup in 20:
		var loot: Node2D
		for candidate in main.loot_piles:
			if is_instance_valid(candidate) and not candidate.collected:
				loot = candidate
				break
		if loot == null: break
		var kind: String = loot.kind
		var amount: int = loot.ammo_amount
		var at: Vector2 = loot.global_position
		var ref: WeakRef = weakref(loot)
		await _key("1")
		if not await _set_tool(main.Tool.DEPLOY): return false
		var before_pickup := _inventory()
		if not await _world_click(at,0.12,"SWEEP_loot_"+kind): return false
		if not await _wait_until(func() -> bool:
			var current = ref.get_ref()
			return current == null or current.collected,
			120,"original SWEEP walk and automatic nearby loot " + kind): return false
		if not await _wait_until(func() -> bool: return not main.selected.is_moving(),120,"original SWEEP walking finishes"): return false
		journey_rows.append({"level":main.level.level_id,"wave":wave,"action":"native SWEEP drop collected","kind":kind,"amount":amount,"target":str(at),"before":before_pickup,"after":_inventory(),"status":main.status_label.text})
		_write_journey()
	if main.level.level_id == "warehouse" and wave == 0:
		if not await _collect("ammo",1): return false
		journey_rows.append({"level":"warehouse","wave":wave,"action":"SWEEP original authored ammo resupply","inventory":_inventory()})
		if not await _collect("mine",0): return false
		if not await _place_mine(Vector2i(24,5)): return false
	await _modal_capture(sample+"_wave"+str(wave)+"_sweep_looted")
	if wave+1 < main.level.wave_count() and not await _deploy(plan): return false
	return true

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
	var picked: Dictionary = view.pick_at(at)
	rows.append({"action":label,"target":[pos.x,pos.y],"screen":[at.x,at.y],"camera_yaw":view.rig.yaw_deg,"reachable":reachable,"picked_kind":picked.get("kind","invalid"),"picked_id":str(picked.get("id","")),"picked_pos":str(picked.get("pos",Vector2.INF))})
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
	deploy_round += 1
	for index in 3:
		await _key(str(index+1))
		var slot = main.cover_slots[plan[1][index]]
		var before: Vector2 = main.selected.global_position
		if slot.slot_id == 5: await _modal_capture(sample+"_cover5_before_deploy"+str(deploy_round))
		if not await _world_click(slot.global_position,0.08,"cover_"+str(slot.slot_id)): return false
		var immediate_slot: int = main.selected.slot.slot_id if main.selected.slot else -1
		await create_timer(0.8).timeout
		rows.append({"action":"native cover outcome","operator":index,"target_slot":slot.slot_id,"selected_id":main.selected.op_id,"before":[before.x,before.y],"target":[slot.global_position.x,slot.global_position.y],"distance_before":before.distance_to(slot.global_position),"after":[main.selected.global_position.x,main.selected.global_position.y],"slot_after_settle":immediate_slot,"actual_slot":main.selected.slot.slot_id if main.selected.slot else -1,"additional_wait_s":0.8,"status":main.status_label.text})
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
		if not await _place_mine(Vector2i(7,11)): return false
		if not await _deploy(plan): return false
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
		if not await _sweep(plan,wave): return false
	await _click(main.alarm_button)
	_check(main.phase==main.Phase.WON and main.raid.waves_cleared==main.level.wave_count(),"ordinary final SWEEP extract wins "+id)
	await _modal_capture(sample+"_won")
	journey_rows.append({"level":id,"action":"original WON/progress","waves":main.raid.waves_cleared,"terminal":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"progress":settings.progress_level_id()})
	var source = main.battle_log
	var stream_path := "res://build/asset_review/pr15-runtime/native-player-"+id+"-record.bin"
	var stream_file := FileAccess.open(stream_path,FileAccess.WRITE)
	stream_file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick}))
	stream_file.close()
	journey_rows.append({"level":id,"action":"archive actual native player battle and command recording","path":stream_path,"sha256":FileAccess.get_sha256(stream_path),"attempt":source.attempt_id,"playback_schema":source.playback_schema,"playback_terminal_tick":source.playback_terminal_tick,"playback_frames":source.playback_snapshots.size()})
	_write_journey()
	await _click(main.continue_button)
	if id == "radio":
		_check(main.credits_overlay.is_open(),"ordinary final CTA opens original campaign credits")
		return true
	_check(main.night_handoff.is_open(), "original Continue opens authored next-night handoff")
	if not main.night_handoff.is_open(): return false
	await _modal_capture(sample+"_next_night_handoff")
	await _click(main.night_handoff._cta)
	_check(not main.night_handoff.is_open(), "original native handoff CTA enters next night")
	if main.night_handoff.is_open(): return false
	sample = "player_"+main.level.level_id+"_1280_100_desktop"
	return await _tutorial()
