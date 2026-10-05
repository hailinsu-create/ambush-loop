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
var last_fired := {}
var ammo_repack_observations := []
var journey_output := "res://build/asset_review/pr15-runtime"

class NativeWorldTrace extends Node:
	var suite: SceneTree
	var host: Node
	var presenter: Node3D
	func _input(event: InputEvent) -> void:
		if not is_instance_valid(host) or not is_instance_valid(presenter): return
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
	var file := FileAccess.open(journey_output + "/first-visit-journey-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"window":[root.size.x,root.size.y],"content_scale_factor":root.content_scale_factor,"checks":checks,"failures":failures,"rows":rows,"journey":journey_rows,"captures":captures,"native_inputs":input_rows,"progress_seed":progress_seed,"ammo_repack_observations":ammo_repack_observations,"a0_preview_feature":OS.has_feature("a0_preview"),"scope":"Isolated original title/main flow; fresh start or byte-identical pinned actual player save and native Continue. Real XTest and engine callbacks. Existing a0_preview enabled only in the isolated PCK. No tutorial/progress/resource grants/reference/vacuum helpers. Only report actually reached missions/waves; source-derived deployment strategy is not a stranger playtest."}, "  "))

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
	if not _configure_output(scope):
		quit(2)
		return
	var resumed := OS.get_environment("AMBUSH_JOURNEY_START") == "resume"
	var level_order: Array = PLAYER_PLANS.map(func(plan: Array) -> String: return plan[0])
	var gameplay := scope in level_order or scope in ["all","remaining"]
	var entry_id := "yard"
	root.size = Vector2i(1280, 720) if gameplay else Vector2i(1600, 720)
	root.content_scale_factor = 1.0 if gameplay else 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	sample = "player_resume_1280_100_desktop" if resumed else ("player_yard_1280_100_desktop" if gameplay else "first_visit_yard_1600_200_desktop")
	await _title()
	if resumed:
		var receipt_path := OS.get_environment("AMBUSH_JOURNEY_SEED_RECEIPT")
		_check(FileAccess.file_exists(receipt_path), "resumed journey pins original player save receipt")
		if not FileAccess.file_exists(receipt_path):
			_save_journey()
			return
		progress_seed = JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
		_check(progress_seed.run_id == OS.get_environment("AMBUSH_TEST_RUN_ID"), "seed belongs to this guarded run")
		# Older real-save manifests omit next_level_id; read the pinned ConfigFile.
		entry_id = str(progress_seed.origin.get("next_level_id", settings.progress_level_id()))
		_check(entry_id in level_order, "actual player receipt pins a known next mission")
		if entry_id not in level_order:
			_save_journey()
			return
		for name in progress_seed.files:
			_check(FileAccess.get_sha256("user://"+name) == progress_seed.files[name].sha256, "original player ConfigFile retained byte for byte " + name)
		_check(settings.has_progress() and settings.progress_level_id() == entry_id and settings.has_seen_tutorial(entry_id), "actual pinned player win/teaching naturally exposes Continue for " + entry_id)
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
	_check(main.scene_file_path == "res://scenes/main.tscn" and main.level.level_id == entry_id and main.phase == main.Phase.SETUP, "ordinary original title entry reaches actual SCOUT " + entry_id)
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
			if level_order.find(plan[0]) < level_order.find(entry_id): continue
			if not await _mission(plan): break
			if scope in level_order: break
	_save_journey()

func _configure_output(scope: String) -> bool:
	var label := OS.get_environment("AMBUSH_JOURNEY_OUTPUT_LABEL")
	if label == "":
		if scope == "all":
			print("FIRST_VISIT_OUTPUT_REFUSED all requires an independent output label")
			return false
		return true # Preserve the previous single-level fixture interface.
	var allowed := RegEx.create_from_string("^[A-Za-z0-9_.-]{1,64}$")
	if allowed.search(label) == null or label in [".",".."]:
		print("FIRST_VISIT_OUTPUT_REFUSED invalid label")
		return false
	journey_output += "/" + label + "-" + OS.get_environment("AMBUSH_TEST_RUN_ID")
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(journey_output)):
		print("FIRST_VISIT_OUTPUT_REFUSED candidate directory already exists")
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(journey_output)) != OK:
		print("FIRST_VISIT_OUTPUT_REFUSED cannot create candidate directory")
		return false
	print("JOURNEY_OUTPUT=" + journey_output)
	return true

func _modal_capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path := journey_output + "/viewport_" + label + ".png"
	_check(image.save_png(path)==OK,"actual candidate modal capture saved")
	captures.append({"id":label,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()],"capture_source":"DisplayServer.screen_get_image native Window crop"})

func _checkpoint_progress(id: String) -> void:
	var directory := journey_output + "/player-progress-" + id
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))==OK,"create independent natural progress archive " + id)
	var files := {}
	for name in ["ambush_loop.cfg","ambush_loop_settings.cfg"]:
		_check(FileAccess.file_exists("user://"+name),"original natural player ConfigFile exists " + id + "/" + name)
		if not FileAccess.file_exists("user://"+name): continue
		var original := FileAccess.get_file_as_bytes("user://"+name)
		var saved := FileAccess.open(directory+"/"+name,FileAccess.WRITE)
		saved.store_buffer(original)
		saved.close()
		var sha := FileAccess.get_sha256("user://"+name)
		_check(FileAccess.get_sha256(directory+"/"+name)==sha,"natural player ConfigFile copy is byte identical " + id + "/" + name)
		files[name] = {"sha256":sha,"bytes":original.size()}
	var manifest := {"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"run_id":OS.get_environment("AMBUSH_TEST_RUN_ID"),"level_checkpoint":id,"progress_level":settings.progress_level_id(),"files":files,"scope":"Read-only copy of original naturally written user ConfigFiles. No progress/seen/unlock/resource grants."}
	var file := FileAccess.open(directory+"/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "))
	file.close()
	journey_rows.append({"level":id,"action":"seal original natural player ConfigFiles","directory":directory,"manifest":manifest})

func _set_tool(wanted: int) -> bool:
	for step in 4:
		if main.tool == wanted: break
		await _click(main.tool_button)
	_check(main.tool == wanted, "native original ToolButton reaches tool " + str(wanted))
	return main.tool == wanted

func _inventory() -> Array:
	return main.operators.map(func(op) -> Dictionary: return {"id":op.op_id,"alive":op.alive,"hp":op.hp,"weapon":op.weapon_id,"pos":[op.global_position.x,op.global_position.y],"ammo":op.ammo,"start_ammo":op.start_ammo,"pool":op.ammo_pool.duplicate(true),"pack":op.pack.slots.duplicate(true),"mines":op.mines,"has_ammo_pack":op.has_ammo_pack,"ammo_pack_used":op.ammo_pack_used,"auto_grenade":op.auto_grenade})

func _observe_fired(op: Node2D, target: Vector2) -> void:
	# Signal arrives after the real shot decrements ammo, before original refill.
	last_fired[op.op_id] = {"level":main.level.level_id,"wave":main.raid.wave_index,"phase":main.phase,"tick":main.sim.tick,"weapon":op.weapon_id,"ammo":op.ammo,"has_ammo_pack":op.has_ammo_pack,"ammo_pack_used":op.ammo_pack_used,"target":[target.x,target.y]}

func _observe_repacked(op: Node2D) -> void:
	var shot: Dictionary = last_fired.get(op.op_id, {}).duplicate(true)
	var actual_pack: bool = not shot.is_empty() and shot.ammo == 0 and shot.has_ammo_pack and not shot.ammo_pack_used and op.ammo_pack_used and op.weapon_id == shot.weapon and op.ammo == op.start_ammo
	var repack_events: Array = main.battle_log.events.filter(func(event: Dictionary) -> bool: return event.type == "repack")
	var observation := {"level":main.level.level_id,"wave":main.raid.wave_index,"operator":op.op_id,"phase":main.phase,"tick":main.sim.tick,"last_real_shot":shot,"after":{"weapon":op.weapon_id,"ammo":op.ammo,"start_ammo":op.start_ammo,"has_ammo_pack":op.has_ammo_pack,"ammo_pack_used":op.ammo_pack_used},"actual_exhaustion_pack_refill":actual_pack,"latest_original_repack_event":repack_events.back() if not repack_events.is_empty() else {}}
	ammo_repack_observations.append(observation)
	journey_rows.append({"level":main.level.level_id,"action":"observe original automatic ammo repack signal","observation":observation})
	if actual_pack:
		var event: Dictionary = observation.latest_original_repack_event
		_check(not event.is_empty() and event.actor_id == op.op_id and event.wave_id == shot.wave and event.tick == shot.tick and event.payload.get("repack_kind", "") == "same_weapon", "actual ammo-zero pack refill retains matching original repack event identity and weapon")
		print("PLAYER_ACTUAL_AMMO_PACK_REFILL ", JSON.stringify(observation))
	_write_journey()

func _native_rifle_pack_strategy() -> bool:
	await _key("1")
	var before := _inventory()
	await _key("i")
	_check(main.backpack_panel.is_open(), "original native I opens SCOUT rifle backpack")
	if not main.backpack_panel.is_open(): return false
	if main.selected.auto_grenade: await _click(main.backpack_panel._auto_btn)
	_check(not main.selected.auto_grenade, "original backpack button disables rifle automatic grenade in SCOUT")
	await _modal_capture(sample + "_scout_backpack_auto_off")
	await _click(main.backpack_panel._close_btn)
	var ok: bool = not main.backpack_panel.is_open() and not main._modal_blocks_input() and not main.selected.auto_grenade
	_check(ok, "original backpack close returns to SCOUT with chosen strategy retained")
	journey_rows.append({"level":main.level.level_id,"action":"native SCOUT rifle pack and no automatic grenade strategy","before":before,"after":_inventory(),"scope":"Original pack/UI policy choice; no ammo/HP/weapon grants or forced shots. Scout collects SWEEP loot to preserve rifle remaining ammunition for a real exhaustion observation."})
	return ok

func _place_mine(cell: Vector2i) -> bool:
	await _key("1")
	if not await _set_tool(main.Tool.DEPLOY): return false
	var at: Vector2 = main.grid.cell_to_world_center(cell)
	var standing: Vector2 = main.grid.cell_to_world_center(cell+Vector2i(1,0))
	if not await _world_click(standing,0.02,"walk_near_mine_site",1,"ground"): return false
	if not await _wait_until(func() -> bool: return not main.selected.is_moving() and main.selected.global_position.distance_to(at)<=64.0,120,"original walk reaches mine placement range"): return false
	if not await _set_tool(main.Tool.TRIPWIRE): return false
	var before: int = main.selected.mines
	var placed: int = main.raid_mines.size()
	if not await _world_click(at,0.02,"place_carried_mine",1,"ground"): return false
	var ok: bool = main.selected.mines == before-1 and main.raid_mines.size() == placed+1
	_check(ok, "native mine tool consumes exactly one carried mine and creates one raid mine")
	journey_rows.append({"level":main.level.level_id,"action":"native carried mine attempt","ok":ok,"phase":main.phase,"site":[at.x,at.y],"operator_pos":str(main.selected.global_position),"before":before,"after":main.selected.mines,"mines_before":placed,"mines_after":main.raid_mines.size(),"status":main.status_label.text})
	await _modal_capture(sample+("_mine_placed_wave" if ok else "_mine_blocked_wave")+str(main.raid.wave_index))
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
		await _key("3" if main.level.level_id == "railcut" else "1")
		if not await _set_tool(main.Tool.DEPLOY): return false
		var before_pickup := _inventory()
		var event_start: int = main.battle_log.events.size()
		if not await _world_click(at,0.12,"SWEEP_loot_"+kind): return false
		if not await _wait_until(func() -> bool:
			var current = ref.get_ref()
			return current == null or current.collected,
			120,"original SWEEP walk and automatic nearby loot " + kind): return false
		if not await _wait_until(func() -> bool: return not main.selected.is_moving(),120,"original SWEEP walking finishes"): return false
		var loot_events: Array = main.battle_log.events.slice(event_start).filter(func(event: Dictionary) -> bool: return event.type == "loot")
		_check(not loot_events.is_empty(), "actual nearby collection records original loot events")
		journey_rows.append({"level":main.level.level_id,"wave":wave,"action":"native SWEEP drop collected","kind":kind,"amount":amount,"target":str(at),"before":before_pickup,"after":_inventory(),"loot_events":loot_events,"status":main.status_label.text})
		_write_journey()
	if main.level.level_id in ["warehouse","pump","railcut"] and wave == 0:
		var before_resupply := _inventory()
		if not await _collect("ammo",1): return false
		journey_rows.append({"level":main.level.level_id,"wave":wave,"action":"SWEEP original authored ammo resupply","before":before_resupply,"inventory":_inventory()})
	if main.level.level_id == "warehouse" and wave == 0:
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

func _world_click(pos: Vector2, height: float, label: String, button: int = 1, wanted_kind: String = "") -> bool:
	var at: Vector2
	var reachable := false
	var picked: Dictionary
	for turn in 13:
		at = view.rig.project_logic(pos,height)
		# XTest receives integer physical pixels. Probe the same pixel it sends.
		var transform: Transform2D = root.get_screen_transform()
		var physical := Vector2(Vector2i(transform*at))
		at = transform.affine_inverse()*physical
		reachable = root.get_visible_rect().grow(-2).has_point(at) and not view.pointer_over_ui(at)
		picked = view.pick_at(at)
		if wanted_kind != "":
			reachable = reachable and picked.get("kind","") == wanted_kind
			if wanted_kind != "ground":
				reachable = reachable and pos.distance_to(picked.get("pos",Vector2.INF)) < 1.0
			else:
				for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
					reachable = reachable and view.pick_at(at+offset).get("kind","") == "ground"
		if reachable: break
		rows.append({"action":"original camera UI reveal target","target_action":label,"wanted_kind":wanted_kind,"observed_kind":picked.get("kind","invalid"),"observed_pos":str(picked.get("pos",Vector2.INF)),"yaw":view.rig.yaw_deg})
		if turn < 12: await _click(_button(view._camera_controls,"↷"))
	rows.append({"action":label,"target":[pos.x,pos.y],"screen":[at.x,at.y],"camera_yaw":view.rig.yaw_deg,"reachable":reachable,"picked_kind":picked.get("kind","invalid"),"picked_id":str(picked.get("id","")),"picked_pos":str(picked.get("pos",Vector2.INF))})
	_check(reachable, "native world target is in viewport outside UI with intended visible pick " + label)
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
	if not await _world_click(stash.global_position,0.55,"stash_"+kind,1,"stashes"): return false
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
		if main.selected.slot != slot:
			if not await _world_click(slot.global_position,0.08,"cover_"+str(slot.slot_id),1,"covers"): return false
		else:
			rows.append({"action":"retain actual unmoved operator on original cover","operator":index,"slot":slot.slot_id,"pos":str(main.selected.global_position)})
		var immediate_slot: int = main.selected.slot.slot_id if main.selected.slot else -1
		await create_timer(0.8).timeout
		rows.append({"action":"native cover outcome","operator":index,"target_slot":slot.slot_id,"selected_id":main.selected.op_id,"before":[before.x,before.y],"target":[slot.global_position.x,slot.global_position.y],"distance_before":before.distance_to(slot.global_position),"after":[main.selected.global_position.x,main.selected.global_position.y],"slot_after_settle":immediate_slot,"actual_slot":main.selected.slot.slot_id if main.selected.slot else -1,"additional_wait_s":0.8,"status":main.status_label.text})
		_check(main.selected.slot == slot, "original native cover command mounts intended pad")
		if main.selected.slot != slot:
			await _modal_capture(sample+"_cover"+str(slot.slot_id)+"_blocked")
			return false
		var target: float = plan[2][index]
		var initial_facing: float = main.selected.facing_deg
		var quantum := 8.0 if main.selected.role == main.selected.Role.MG else 15.0
		var tolerance := quantum*0.5+0.01
		var key_count := 0
		for turn in 24:
			var diff: float = wrapf(target-main.selected.facing_deg,-180.0,180.0)
			if absf(diff) <= tolerance: break
			await _turn_key("d" if diff > 0.0 else "a")
			key_count += 1
		var oriented: bool = absf(wrapf(target-main.selected.facing_deg,-180.0,180.0)) <= tolerance
		rows.append({"action":"original native keyboard facing","operator":index,"initial_facing":initial_facing,"intended_facing":target,"actual_facing":main.selected.facing_deg,"original_quantum_deg":quantum,"keys":key_count,"tolerance_deg":tolerance,"nearest_reachable":oriented})
		_check(oriented,"native original8deg MG/15deg other rotation reaches nearest lawful facing")
		if not oriented:
			await _modal_capture(sample+"_facing_blocked_deploy"+str(deploy_round))
			return false
	return true

func _turn_key(name: String) -> void:
	# Turning has no modal fade. Keep real XTest and real event-processing frames.
	var output := []
	var before: float = main.selected.facing_deg
	var status := OS.execute("python3", [ProjectSettings.globalize_path("res://scripts/native_x11_test_input.py"), "key", name], output, true)
	_check(status == 0, "native turn key helper exit0 " + name + " " + str(output))
	for frame in 2: await process_frame
	input_rows.append({"id":sample,"key":name,"helper_exit":status,"wait":"two actual process frames; no modal fade","facing_before":before,"facing_after":main.selected.facing_deg})

func _mission(plan: Array) -> bool:
	var id: String = plan[0]
	sample = "player_"+id+"_1280_100_desktop"
	_check(main.level.level_id == id and main.phase == main.Phase.SETUP,"original progression reaches next SCOUT "+id)
	print("PLAYER_JOURNEY_MISSION ",id)
	last_fired.clear()
	for op in main.operators:
		if not op.fired_shot.is_connected(_observe_fired): op.fired_shot.connect(_observe_fired)
		if not op.ammo_repacked.is_connected(_observe_repacked): op.ammo_repacked.connect(_observe_repacked)
	for index in 3:
		if not await _collect(["rifle","mg","scout"][index],index): return false
		_check(Weapons.family_of(main.selected.weapon_id)==["rifle","mg","scout"][index],"ordinary firearm pickup equips authored family")
	if not await _collect("grenade",0): return false
	if id in ["depot","radio"] and not await _collect("mine",0): return false
	if not await _deploy(plan): return false
	if main.level.has_ammo_pack:
		await _key("1" if id == "railcut" else "2")
		await _click(main.pack_button)
		_check(main.selected.has_ammo_pack,"original native UI assigns authored single ammo pack")
	if id == "railcut" and not await _native_rifle_pack_strategy(): return false
	if id == "warehouse":
		await _key("2")
		await _key("f")
	if id in ["depot","radio"]:
		if not await _place_mine(Vector2i(7,11)): return false
		if not await _deploy(plan): return false
	await _modal_capture(sample+"_armed_scout")
	journey_rows.append({"level":id,"action":"original SCOUT armed inventory","strategy_slots":plan[1],"strategy_facing":plan[2],"inventory":_inventory(),"strategy_provenance":"source-derived original authored stash/cover/routes; real native inputs; not stranger playtest"})
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
	journey_rows.append({"level":id,"action":"original WON/progress","waves":main.raid.waves_cleared,"terminal":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"progress":settings.progress_level_id(),"inventory":_inventory()})
	var source = main.battle_log
	var stream_path := journey_output + "/native-player-"+id+"-record.bin"
	var stream_file := FileAccess.open(stream_path,FileAccess.WRITE)
	stream_file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick}))
	stream_file.close()
	journey_rows.append({"level":id,"action":"archive actual native player battle and command recording","path":stream_path,"sha256":FileAccess.get_sha256(stream_path),"attempt":source.attempt_id,"playback_schema":source.playback_schema,"playback_terminal_tick":source.playback_terminal_tick,"playback_frames":source.playback_snapshots.size()})
	_checkpoint_progress(id)
	_write_journey()
	await _click(main.continue_button)
	if id == "radio":
		_check(main.credits_overlay.is_open(),"ordinary final CTA opens original campaign credits")
		if not main.credits_overlay.is_open(): return false
		await _modal_capture(sample+"_credits_open")
		var scroll := main.credits_overlay.find_child("CreditsScroll",true,false) as ScrollContainer
		_check(scroll != null,"original credits scroll exists")
		if scroll == null: return false
		var before := scroll.scroll_vertical
		for i in 5: await _native_click(scroll,5)
		_check(scroll.scroll_vertical>before,"native credits wheel scroll reaches original recap")
		await _modal_capture(sample+"_credits_scrolled")
		var back: Button
		for button in main.credits_overlay.find_children("*","Button",true,false):
			if button.text == "返回标题": back = button
		_check(back != null,"original credits return button exists")
		if back == null: return false
		journey_rows.append({"level":id,"action":"original native credits open and scroll","is_open":main.credits_overlay.is_open(),"scroll_before":before,"scroll_after":scroll.scroll_vertical})
		await _click(back)
		await _settle()
		main = current_scene
		_check(main.scene_file_path=="res://scenes/title.tscn","original native credits button returns to Title")
		await _modal_capture(sample+"_credits_return_title")
		_checkpoint_progress("radio-credits-return")
		journey_rows.append({"level":id,"action":"original native credits returned Title","scene":main.scene_file_path,"record_sha256":FileAccess.get_sha256(stream_path)})
		_write_journey()
		return main.scene_file_path=="res://scenes/title.tscn"
	_check(main.night_handoff.is_open(), "original Continue opens authored next-night handoff")
	if not main.night_handoff.is_open(): return false
	await _modal_capture(sample+"_next_night_handoff")
	await _click(main.night_handoff._cta)
	_check(not main.night_handoff.is_open(), "original native handoff CTA enters next night")
	if main.night_handoff.is_open(): return false
	sample = "player_"+main.level.level_id+"_1280_100_desktop"
	return await _tutorial()
