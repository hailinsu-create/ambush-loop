extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("VISUAL_SNAPSHOT: " + message)


func _plain(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		for child in value.values():
			if not _plain(child):
				return false
	elif value is Array:
		for child in value:
			if not _plain(child):
				return false
	return true


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	var initial_kit: String = main.operators[1].weapon_id
	main.operators[1].receive_item("m1911", 5)
	main.operators[1].equip_from_pack(initial_kit)
	main.raid_force_alarm()
	var first: Dictionary = main.battle_log.snapshots.front()
	_check(first.data.visual_schema == 1 and _plain(first.data), "versioned history contains only plain values")
	var limit := 0
	while main.phase == main.Phase.WATCHING and limit < 3000:
		main._sim_tick()
		limit += 1
	_check(main.phase == main.Phase.SWEEP, "actual first wave reaches legal equipment phase")
	first = main.battle_log.snapshots.filter(func(s: Dictionary) -> bool: return s.tick == 6).front()
	main._select_op(1)
	main._on_pack_equip("m1911")
	main.selected.toggle_crouch()
	main._toggle_auto_grenade()
	var loot = main.loot_piles.front()
	var captured: Dictionary = main._snapshot_data()
	var old_id: String = captured.loot[0].id
	main.loot_piles.erase(loot)
	loot.queue_free()
	main._spawn_loot_at(Vector2(700, 400), 2, "ammo")
	var new_data: Dictionary = main._snapshot_data()
	_check(new_data.loot.back().id != old_id, "removing an object cannot reuse its recording identity")
	main._on_sweep_commit()
	for i in 120:
		main._sim_tick()
	var second: Dictionary = main.battle_log.snapshots.filter(func(s: Dictionary) -> bool: return s.wave_id == 1).back()
	_check(first.data.ops[1].weapon == initial_kit and second.data.ops[1].weapon == "m1911", "different waves retain their actual equipment")
	_check(second.data.ops[1].stance == OperatorUnit.Stance.CROUCH and not second.data.ops[1].auto_grenade, "pose and grenade policy are recorded")
	_check(second.data.ops[1].inventory.size() > 0 and second.data.ops[1].ammo_pool.has("pistol"), "backpack and ammo pools are copied")
	_check(not second.data.enemies.is_empty() and second.data.enemies[0].has("facing"), "enemies record orientation and action state")
	_check(second.data.has("sentries") and second.data.covers.size() == main.cover_slots.size() and second.data.has("barrels"), "historical environment, patrols and objects are recorded")
	_tool_contract(main)
	main.battle_log.add_snapshot(main.sim.tick, main._snapshot_data())
	second = main.battle_log.snapshots.back()
	main._flash("LIVE_ONLY 自动手雷 开", Color.WHITE)
	main._on_replay_pressed()
	_check(main.flash_label.text.is_empty() and main.flash_text().is_empty(), "entering history clears transient live banners and their plate")
	main.operators[1].weapon_id = "knife"
	main.operators[1].display_name = "LIVE_ONLY"
	main.operators[1].hp = 3.0
	main.operators[1].ammo = 0
	main.operators[1].stance = OperatorUnit.Stance.STAND
	main.operators[1].fire_mode = OperatorUnit.FireMode.HOLD_FOR_AMBUSH
	main.level.title = "LIVE_LEVEL"
	main.loop_index += 90
	main.operators[0].stance = OperatorUnit.Stance.STAND
	main.operators[0].global_position = Vector2(32, 32)
	main.operators[0].pack.slots.clear()
	main.enemies[0].facing_deg = -45.0
	main.grid.blocked.fill(0)
	main.escape_world = Vector2(999, 999)
	main.cover_slots[0].global_position += Vector2(32, 0)
	main.run_id += 200
	var live: Dictionary = main._snapshot_data().duplicate(true)
	for snap in [first, second, first, second]:
		main.replay.set_tick(BattleLog.record_tick(snap))
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		var frame := ViewState.capture(main)
		_hud_contract(main, frame)
		_check(frame.ops[0].weapon == snap.data.ops[0].weapon and frame.ops[0].stance == snap.data.ops[0].stance, "backward/forward scrub uses historical kit and stance")
		_check(frame.blocked == snap.data.blocked and frame.escape == snap.data.escape and frame.covers == snap.data.covers, "replay world layout cannot borrow current geometry")
		_check(frame.enemies == ViewState.capture(main).enemies and (frame.enemies.is_empty() or frame.enemies[0].facing == snap.data.enemies[0].facing), "historical enemy orientation is retained")
		_check(frame.is_read_only() and frame.ops[0].inventory.is_read_only(), "nested history is immutable")
		var selection: Array = frame.ops.filter(func(o: Dictionary) -> bool: return o.id == frame.selected_id)
		_check(main.presentation_3d.focus_selected() and main.presentation_3d.rig.focus == Space.logic_to_world(selection[0].pos), "selected camera focus uses the historical position")
		var body: Node3D = main.presentation_3d.actors["ops:2"].get_node("Body")
		_check(body is preload("res://scripts/presentation/actor_visual.gd") and body.scale == Vector3.ONE and (frame.ops[1].stance != 1 or not frame.ops[1].alive or body.sampled_action in ["crouch", "crouch_walk"]), "rigged proxy uses historical crouch bones without shrinking its root")
	_check(live == main._snapshot_data(), "capture, rendering, focus and scrubs cannot write live state")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://build/asset_review/pr15-runtime")
		for phone in [false, true]:
			root.get_node("GameSettings").set_force_touch_hud(phone)
			main._update_hud()
			if phone:
				_check(main.touch_hud != null and main.touch_hud._row_setup.visible and not main.touch_hud._row_watch.visible, "phone replay provides the return action row")
				if main.touch_hud != null:
					_check(main.touch_hud._hint.position.y >= 48.0, "phone replay hint stays below the recorded title band")
					_check(main.touch_hud._replay_scrub.is_visible_in_tree() and main.touch_hud._replay_time.text.contains("复盘"), "phone replay has a visible synchronized timeline")
					_check(main.touch_hud._btns["alarm"].visible and not main.touch_hud._btns["alarm"].disabled and main.touch_hud._btns["alarm"].text == "返回搜刮", "phone replay return button is visible and enabled")
					for cmd in main.touch_hud._btns:
						if str(cmd) != "alarm":
							_check(not main.touch_hud._btns[cmd].visible, "phone replay hides live command %s" % str(cmd))
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://build/asset_review/pr15-runtime/history_hud_%s.png" % ("phone" if phone else "desktop")
			_check(root.get_texture().get_image().save_png(path) == OK, "rendered historical HUD is saved")
			print("VISUAL_SNAPSHOT_CAPTURE ", path)
		await _phone_scrub_contract(main)
	_compatibility(main)
	main._on_alarm_pressed()
	_check(main.phase == main.Phase.SETUP and not main.c2.portraits._historical and main.c2.minimap._host == main, "return action restores live portraits and minimap binding")
	_check(not main.mode_button.disabled and main.role_cards[0]._can_pick and main.role_cards[0]._hp.visible, "live card controls and HP recover after replay")
	root.get_node("AudioDirector").pause_for_background()
	print("VISUAL_SNAPSHOT_OK" if failures == 0 else "VISUAL_SNAPSHOT_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _phone_scrub_contract(main: Node) -> void:
	var slider: HSlider = main.touch_hud._replay_scrub
	var rect := slider.get_global_rect()
	for fraction in [0.2, 0.8]:
		var touch := InputEventScreenTouch.new()
		touch.index = 11
		touch.position = Vector2(lerpf(rect.position.x + 8.0, rect.end.x - 8.0, fraction), rect.get_center().y)
		touch.pressed = true
		Input.parse_input_event(touch)
		await process_frame
		touch.pressed = false
		Input.parse_input_event(touch)
		await process_frame
		_check(absf(float(main.replay.scrub_tick) / main.replay.max_tick() - fraction) < 0.03, "native phone touch moves the historical timeline to %.1f" % fraction)
		_check(main.phase == main.Phase.REPLAY and main.operators[1].weapon_id == "knife", "native phone scrub remains read-only against the poisoned live actor")


func _hud_contract(main: Node, frame: Dictionary) -> void:
	main.c2.refresh_hud_light()
	_check(frame.hud_schema == 1 and frame.level_title != "LIVE_LEVEL", "historical HUD fields are versioned and do not borrow live level metadata")
	_check(main.level_label.text == frame.level_title and main.title_label.text.contains("波 %d/%d" % [frame.wave_id + 1, frame.wave_count]) and main.title_label.text.contains("第 %d 世" % frame.attempt_number), "header follows recorded level, attempt and wave")
	for i in 3:
		var op: Dictionary = frame.ops[i]
		var card = main.role_cards[i]
		var portrait: Button = main.c2.portraits._cards[i]
		_check(card._gun.get("weapon_id") == op.weapon and portrait.get_node("Gun").get("weapon_id") == op.weapon, "left rail and portrait show historical kit despite live knife")
		_check(card._name.text == op.display_name and portrait.get_node("Nam").text == op.display_name, "historical names survive live name changes")
		_check(card._hp_target == op.hp and card._hp_shown == op.hp and card._hp.value == op.hp, "scrub HP is immediate and never interpolates from live state")
		_check(card._meta.text.contains(op.inventory_line) and card._meta.text.contains(op.fire_mode_label), "inventory and fire policy come from the record")
		_check(not card._can_pick and portrait.disabled, "historical cards are read-only controls")
	var selected_ops: Array = frame.ops.filter(func(o: Dictionary) -> bool: return o.id == frame.selected_id)
	var selected_record: Dictionary = selected_ops[0]
	_check(main.mode_button.disabled and main.mode_button.text.contains(selected_record.fire_mode_label) and not main.pack_button.visible, "selected mode label is historical and equipment allocation is hidden")
	_check(main.c2.minimap._historical and main.c2.minimap._host == null and main.c2.minimap._grid == null and main.c2.minimap._history == frame, "minimap uses an immutable historical frame with no live host/grid")
	var pan: Vector2 = main._cam_pan
	var focus: Vector3 = main.presentation_3d.rig.focus
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.double_click = true
	ev.button_index = MOUSE_BUTTON_LEFT
	main.c2.portraits._cards[1].gui_input.emit(ev)
	_check(main.c2.portraits.dispatch_tap(main.c2.portraits.card_global_rect(1).get_center()) == "" and main._cam_pan == pan and main.presentation_3d.rig.focus == focus, "historical portrait synthetic double-click/tap cannot pan to a live actor")


func _compatibility(main: Node) -> void:
	var log := BattleLog.new()
	log.snapshots = [{"tick": 0, "data": {"ops": [{"id": 1, "pos": Vector2(96, 96), "alive": true}], "enemies": []}}]
	main.replay.bind(log)
	main._apply_replay_scrub()
	main.presentation_3d.refresh()
	var old := ViewState.capture(main)
	_check(old.historical_defaults and old.ops[0].weapon == "" and old.ops[0].action == "idle", "old partial snapshots use neutral actor defaults")
	_check(old.blocked.is_empty() and old.covers.is_empty() and old.level_id == "" and old.selected_id == -1, "old history does not invent current world fields")
	_check(not main.presentation_3d.focus_selected(), "missing historical selection cannot focus a live operator")
	_check(main.status_label.text.contains("旧记录"), "partial history is visibly identified")
	_check(main.level_label.text == "历史关卡" and main.title_label.text.contains("第 — 世") and main.mode_button.text.contains("未记录"), "legacy HUD uses neutral labels, never current level/attempt/fire mode")
	_check(main.role_cards[0]._name.text == "队员1" and main.role_cards[0]._role.text.contains("装备未记录") and not main.role_cards[0]._hp.visible and not main.role_cards[0]._pips.visible, "partial actor HUD does not invent name, equipment or HP/ammo capacity")
	_check(main.c2.minimap._history.blocked.is_empty() and main.c2.portraits._cards[0].get_node("Gun").get("weapon_id") == "", "legacy minimap and portrait cannot borrow current fields")
	log.snapshots[0].data["visual_schema"] = 99
	var retained: Array = log.snapshots.duplicate(true)
	main.replay.bind(log)
	main._apply_replay_scrub()
	main.presentation_3d.refresh()
	var unknown := ViewState.capture(main)
	_check(unknown.visual_unsupported and unknown.ops.is_empty() and unknown.blocked.is_empty(), "unsupported future format is not silently interpreted")
	_check(main.status_label.text.contains("暂不支持") and log.snapshots == retained, "unsupported source history remains intact with a notice")
	_check(not main.role_cards[0].visible and not main.c2.portraits._cards[0].visible and main.c2.minimap._history.ops.is_empty(), "unsupported history clears stale HUD cards and map actors")


func _tool_contract(main: Node) -> void:
	# Explicit visual fixtures validate copying/lifetimes; no simulation steps follow.
	var mine := RaidMine.new()
	main.get_node("World").add_child(mine)
	mine.global_position = Vector2(700, 450)
	main.raid_mines.append(mine)
	var grenade := RaidGrenade.new()
	main.get_node("World").add_child(grenade)
	grenade.setup(Vector2(670, 450), Vector2(740, 450), 10.0, 78.0, 78.0, "mills")
	main.raid_grenades.append(grenade)
	var decoy := RaidDecoy.new()
	main.get_node("World").add_child(decoy)
	decoy.setup()
	decoy.global_position = Vector2(740, 470)
	main.raid_decoys.append(decoy)
	var data: Dictionary = main._snapshot_data()
	_check(data.mines.back().armed and not data.mines.back().spent, "mine state is copied")
	_check(data.grenades.back().variant == "mills" and data.grenades.back().target == Vector2(740, 450), "projectile variant and trajectory are copied")
	_check(data.decoys.back().life == decoy.life and _plain(data), "tool lifetimes contain no live nodes")
	mine.spent = true
	grenade.target = Vector2.ZERO
	decoy.life = 3.0
	_check(not data.mines.back().spent and data.grenades.back().target == Vector2(740, 450) and data.decoys.back().life != decoy.life, "retained tool values do not alias live instances")
	mine.spent = false
	grenade.target = Vector2(740, 450)
	decoy.life = 1.6
