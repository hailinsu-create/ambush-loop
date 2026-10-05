extends Node
# Final fresh campaign: external read-only observer. No cold fixture or mutation RPC.
const Weapons = preload("res://scripts/raid/weapon_catalog.gd")
const Space = preload("res://scripts/presentation/world_space.gd")
const Groups = preload("res://scripts/presentation/view_state.gd")
const RECORD_FIELDS = ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]
var callback: JavaScriptObject
var presents: int = 0
var input_rows: Array = []
var replay_rows: Array = []
var record_bytes: PackedByteArray
var record_meta: Dictionary = {}
var observed_usec: int = 0
var fixture_ready := false

func _ready() -> void:
	assert(OS.has_feature("web") and OS.is_debug_build())
	process_priority = 10000
	callback = JavaScriptBridge.create_callback(_receive)
	JavaScriptBridge.get_interface("window").pr15Observer = callback
	RenderingServer.frame_post_draw.connect(_presented)

func _presented() -> void:
	presents += 1

func _receive(args: Array) -> void:
	var request: Variant = JSON.parse_string(str(args[0]))
	_dispatch(request)

func _hash(bytes: PackedByteArray) -> String:
	var h = HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return h.finish().hex_encode()

func _plain(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x,value.y]
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Rect2: return [value.position.x,value.position.y,value.size.x,value.size.y]
	if value is Dictionary:
		var out: Dictionary = {}
		for key in value: out[str(key)] = _plain(value[key])
		return out
	if value is Array or value is PackedStringArray or value is PackedInt32Array:
		var out: Array = []
		for item in value: out.append(_plain(item))
		return out
	return value

func _record(m: Node) -> Dictionary:
	var fields: Dictionary = {}
	for key: String in RECORD_FIELDS: fields[key] = m.battle_log.get(key)
	return fields

func _operators(m: Node) -> Array:
	var out: Array = []
	for op in m.operators:
		out.append({"id":op.op_id,"alive":op.alive,"hp":op.hp,"weapon":op.weapon_id,"family":Weapons.family_of(op.weapon_id),"pos":_plain(op.global_position),"facing":op.facing_deg,"moving":op.is_moving(),"slot":op.slot.slot_id if op.slot else -1,"role":int(op.role),"ammo":op.ammo,"start_ammo":op.start_ammo,"pool":_plain(op.ammo_pool),"pack":_plain(op.pack.slots),"mines":op.mines,"has_ammo_pack":op.has_ammo_pack,"ammo_pack_used":op.ammo_pack_used,"auto_grenade":op.auto_grenade})
	return out

func _settings() -> Dictionary:
	var gs = get_node("/root/GameSettings")
	var configs: Dictionary = {}
	for name: String in ["ambush_loop.cfg","ambush_loop_settings.cfg"]:
		var path: String = "user://"+name
		configs[name] = {"text":FileAccess.get_file_as_string(path),"sha256":FileAccess.get_sha256(path)} if FileAccess.file_exists(path) else null
	return {"muted":gs.muted,"music_volume":gs.music_volume,"sfx_volume":gs.sfx_volume,"force_touch_hud":gs.force_touch_hud,"quality":gs.quality_tier,"seen":gs.seen_level_tutorials.duplicate(true),"has_progress":gs.has_progress(),"next":gs.progress_level_id(),"complete":gs.is_campaign_complete(),"missions":_plain(gs.mission_entries()),"persistence_status":gs.persistence_status,"persistence_error":gs.persistence_error,"configs":configs}

func _state() -> Dictionary:
	var m = get_tree().current_scene
	if m == null: return {"scene":"transition","presents":presents,"settings":_settings()}
	var out: Dictionary = {"fixture_ready":fixture_ready,"window_size":_plain(get_tree().root.size),"scale":get_tree().root.content_scale_factor,"screen_transform":[_plain(get_tree().root.get_screen_transform().x),_plain(get_tree().root.get_screen_transform().y),_plain(get_tree().root.get_screen_transform().origin)],"gui_focus":str(get_viewport().gui_get_focus_owner().get_path()) if get_viewport().gui_get_focus_owner() else "","gui_hover":str(get_viewport().gui_get_hovered_control().get_path()) if get_viewport().gui_get_hovered_control() else "","scene":m.scene_file_path,"presents":presents,"engine_frames":Engine.get_process_frames(),"ticks_usec":Time.get_ticks_usec(),"viewport":_plain(get_viewport().get_visible_rect()),"settings":_settings(),"observer_usec":observed_usec,"input_count":input_rows.size(),"input_tail":input_rows[-1] if not input_rows.is_empty() else null}
	if not "phase" in m:
		out.merge({"mission_select":m.mission_select_visible(),"briefing":m.briefing_visible(),"pending":m.pending_mission_id(),"continue_disabled":m.continue_btn.disabled})
		return out
	out.merge({"level":m.level.level_id,"phase":int(m.phase),"tool":int(m.tool),"status":m.status_label.text,"fail_reason":m.fail_reason,"attempt":m.battle_log.attempt_id,"wave":m.raid.wave_index,"wave_count":m.level.wave_count(),"waves_cleared":m.raid.waves_cleared,"run_id":m.run_id,"sim":{"tick":m.sim.tick,"paused":m.sim.paused,"speed":m.sim.speed,"accum":m.sim._accum},"selected":m.selected.op_id if m.selected else -1,"operators":_operators(m),"modal":{"tutorial":m.tutorial_overlay.is_open(),"tutorial_page":m.tutorial_overlay._page,"tutorial_body":m.tutorial_overlay._body.text,"pause":m.pause_overlay.is_open(),"backpack":m.backpack_panel.is_open(),"handoff":m.night_handoff.is_open(),"handoff_from":m.night_handoff.from_id(),"handoff_to":m.night_handoff.to_id(),"credits":m.credits_overlay.is_open()},"replay":{"tick":m.replay.scrub_tick,"max":m.replay.max_tick(),"speed":m.replay.speed,"playing":m.replay.playing},"log":{"events":m.battle_log.events.size(),"snapshots":m.battle_log.snapshots.size(),"playback_frames":m.battle_log.playback_snapshots.size(),"playback_tick":m.battle_log.current_playback_tick(),"terminal":m.battle_log.terminal_tick,"playback_terminal":m.battle_log.playback_terminal_tick,"terminal_reason":m.battle_log.terminal_reason},"focus_actor":m.replay_focus_actor,"focus_type":m.replay_focus_type,"event_log_open":m._event_log_open,"event_ring_visible":m.presentation_3d._event_ring.visible if m.presentation_3d else false,"mines_count":m.raid_mines.size(),"stashes":[],"covers":[],"loot":[]})
	var credits_scroll: ScrollContainer = m.credits_overlay.find_child("CreditsScroll",true,false)
	if credits_scroll:
		out["credits_scroll"] = {"vertical":credits_scroll.scroll_vertical,"max":credits_scroll.get_v_scroll_bar().max_value,"page":credits_scroll.get_v_scroll_bar().page}
	for stash in m.raid_stashes:
		if is_instance_valid(stash): out.stashes.append({"id":stash.get_instance_id(),"kind":stash.kind,"family":Weapons.family_of(stash.kind),"collected":stash.collected,"pos":_plain(stash.global_position)})
	for slot in m.cover_slots: out.covers.append({"id":slot.slot_id,"pos":_plain(slot.global_position)})
	for loot in m.loot_piles:
		if is_instance_valid(loot): out.loot.append({"id":loot.get_instance_id(),"kind":loot.kind,"amount":loot.ammo_amount,"collected":loot.collected,"pos":_plain(loot.global_position)})
	if m.presentation_3d:
		var v = m.presentation_3d
		out["view"] = {"yaw":v.rig.yaw_deg,"pitch":v.rig.pitch_deg,"gesture":{"contacts":v.gestures.contacts.size(),"ui_contacts":v.gestures.ui_contacts.size(),"pending_id":v.gestures.pending_id,"suppressed":v.gestures.suppressed_contacts.size(),"middle_down":v.gestures.middle_down},"attempt":v.frame.get("attempt_id",""),"level":v.frame.get("level_id",""),"wave":v.frame.get("wave_id",-1),"tick":v.frame.get("playback_tick",-1),"seq":v.frame.get("frame_seq",-1),"recorded_phase":v.frame.get("recorded_phase",-1),"roots":v.actors.size()}
	return out

func _control(c: Control) -> Dictionary:
	if c == null: return {"missing":true}
	var r: Rect2 = c.get_global_rect()
	return {"path":str(c.get_path()),"name":str(c.name),"text":c.text if c is BaseButton or c is Label else "","rect":_plain(r),"visible":c.is_visible_in_tree(),"disabled":c.disabled if c is BaseButton else false,"value":c.value if c is Range else null}

func _controls() -> Dictionary:
	var m = get_tree().current_scene
	var out: Dictionary = {}
	if not "phase" in m:
		out["title_start"] = _control(m.start_btn)
		out["title_continue"] = _control(m.continue_btn)
		out["brief_go"] = _control(m._brief_go)
		for i in m._mission_btns.size(): out["mission_row:"+str(get_node("/root/GameSettings").LEVEL_ORDER[i])] = _control(m._mission_btns[i])
		return out
	for pair in [["alarm","alarm_button"],["pause","pause_button"],["speed","speed_button"],["tool","tool_button"],["pack","pack_button"],["replay","replay_button"],["scrub","scrub_slider"],["continue","continue_button"]]: out[pair[0]] = _control(m.get(pair[1]))
	if m.touch_hud != null and m.touch_hud._replay_scrub.is_visible_in_tree():
		out["scrub"] = _control(m.touch_hud._replay_scrub)
		out["pause"] = _control(m.touch_hud._replay_pause)
		out["speed"] = _control(m.touch_hud._replay_speed)
	out["log"] = _control(m.log_button)
	out["event_list"] = _control(m.event_list)
	out["tutorial_next"] = _control(m.tutorial_overlay._next)
	out["backpack_auto"] = _control(m.backpack_panel._auto_btn)
	out["backpack_close"] = _control(m.backpack_panel._close_btn)
	out["handoff_cta"] = _control(m.night_handoff._cta)
	out["pause_title"] = _control(m.pause_overlay._title_btn)
	out["pause_close"] = _control(m.pause_overlay._close_btn)
	out["pause_mute"] = _control(m.pause_overlay._mute_btn)
	out["pause_quality"] = _control(m.pause_overlay._quality_btn)
	out["pause_touch"] = _control(m.pause_overlay._touch_btn)
	out["pause_music"] = _control(m.pause_overlay._music)
	out["pause_sfx"] = _control(m.pause_overlay._sfx)
	out["credits_scroll"] = _control(m.credits_overlay.find_child("CreditsScroll",true,false))
	out["credits_back"] = _control(m.credits_overlay.find_child("ReturnButton",true,false))
	if m.presentation_3d:
		out["camera_panel"] = _control(m.presentation_3d._camera_panel)
		out["camera_toggle"] = _control(m.presentation_3d._camera_toggle)
		for button in m.presentation_3d._camera_controls.find_children("*","Button",true,false):
			if button.text == "↷": out["camera_clockwise"] = _control(button)
	if m.event_list != null and m.event_list.is_visible_in_tree():
		var list: ItemList = m.event_list
		var area: Rect2 = list.get_global_rect()
		for i in list.item_count:
			var ir: Rect2 = list.get_item_rect(i)
			var at: Vector2 = ir.get_center() - Vector2(0, list.get_v_scroll_bar().value)
			var hit: int = list.get_item_at_position(at, true)
			var global_at: Vector2 = list.global_position + at
			var glyph: Vector2 = list.get_theme_font("font").get_string_size(list.get_item_text(i), HORIZONTAL_ALIGNMENT_LEFT, -1, list.get_theme_font_size("font_size"))
			var text_width := minf(glyph.x, ir.size.x)
			out["event_row:"+str(i)] = {"rect":[list.global_position.x+ir.position.x, global_at.y-ir.size.y/2,ir.size.x,ir.size.y],"visible":area.has_point(global_at) and hit == i,"disabled":false,"path":str(list.get_path()),"name":"event_row:"+str(i),"text":list.get_item_text(i),"event":_plain(m._event_list_items[i]),"readonly_hit_index":hit,"scroll":list.get_v_scroll_bar().value,"text_width":text_width,"fractions":_plain([list.global_position+Vector2(ir.position.x+text_width*0.05,at.y),list.global_position+Vector2(ir.position.x+text_width*0.5,at.y),list.global_position+Vector2(ir.position.x+text_width*0.95,at.y)])}
	return out

func _project(r: Dictionary) -> Dictionary:
	var m = get_tree().current_scene
	if not "phase" in m or m.presentation_3d == null: return {"error":"no presenter"}
	var v = m.presentation_3d
	var at: Vector2 = v.rig.project_logic(Vector2(float(r.pos[0]),float(r.pos[1])),float(r.height))
	at = Vector2(roundf(at.x),roundf(at.y))
	var picked: Dictionary = v.pick_at(at)
	var neighbors: Array = []
	for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]: neighbors.append(_plain(v.pick_at(at+offset)))
	return {"screen":_plain(at),"pick":_plain(picked),"neighbors":neighbors,"in_viewport":get_viewport().get_visible_rect().grow(-2).has_point(at),"over_ui":v.pointer_over_ui(at),"yaw":v.rig.yaw_deg}

func _domain(m: Node) -> Dictionary:
	var enemies: Array = []
	for e in m.enemies:
		if is_instance_valid(e): enemies.append({"id":e.label_id,"alive":e.alive,"hp":e.hp,"pos":_plain(e.global_position)})
	return {"sim":[m.sim.tick,m.sim.speed,m.sim.paused,m.sim._accum,m.run_id],"operators":_operators(m),"enemies":enemies,"raid_wave":m.raid.wave_index,"waves_cleared":m.raid.waves_cleared,"selected":m.selected.op_id if m.selected else -1,"door_locked":m.door_locked,"blocked":_plain(m.grid.blocked),"stashes":m.raid_stashes.size(),"loot":m.loot_piles.size(),"mines":m.raid_mines.size(),"grenades":m.raid_grenades.size(),"decoys":m.raid_decoys.size()}

func _validation(m: Node) -> Dictionary:
	var failures: Array = []
	var source = m.battle_log
	var latest: int = -1
	for i in source.events.size():
		var ev: Dictionary = source.events[i]
		if ev.attempt_id != source.attempt_id or ev.seq != i or ev.event_id != "%s:%d:%d" % [source.attempt_id,ev.wave_id,i]: failures.append("event identity "+str(i))
		if ev.wave_id < 0 or ev.wave_id >= m.level.wave_count(): failures.append("event wave "+str(i))
		if BattleLog.record_tick(ev) < latest: failures.append("event timeline "+str(i))
		latest = BattleLog.record_tick(ev)
	latest = -1
	for i in source.playback_snapshots.size():
		var frame: Dictionary = source.playback_snapshots[i]
		if frame.attempt_id != source.attempt_id or frame.frame_seq != i: failures.append("frame identity "+str(i))
		if frame.playback_tick < latest: failures.append("playback timeline "+str(i))
		latest = frame.playback_tick
	return {"failures":failures,"events":source.events.size(),"frames":source.playback_snapshots.size(),"attempt":source.attempt_id,"terminal_reason":source.terminal_reason}

func _frame_checks(m: Node) -> Dictionary:
	if m.phase != m.Phase.REPLAY: return {"status":"not replay"}
	var v = m.presentation_3d
	var snap: Dictionary = m.replay.snapshot_at_or_before(m.replay.scrub_tick)
	var f: Dictionary = v.frame
	var failures: Array = []
	var checks: int = 0
	for pair in [[f.get("attempt_id"),m.battle_log.attempt_id],[f.get("level_id"),m.level.level_id],[f.get("wave_id"),snap.get("wave_id")],[f.get("frame_seq"),snap.get("frame_seq")],[f.get("playback_tick"),m.replay.scrub_tick],[f.get("recorded_phase"),snap.get("data",{}).get("phase")],[f.get("events"),m.replay.events_up_to(m.replay.scrub_tick)]]:
		checks += 1
		if pair[0] != pair[1]: failures.append("frame field "+str(checks))
	for group: String in ["ops","enemies","sentries"]:
		for item: Dictionary in f.get(group,[]):
			var proxy = v.actors.get(group+":"+str(item.id))
			checks += 2
			if proxy == null: failures.append("missing3D "+group); continue
			if not proxy.position.is_equal_approx(Space.logic_to_world(item.pos)): failures.append("root "+group)
			var body = proxy.get_node_or_null("Body")
			if body == null or body.skeleton.get_bone_count() != 20: failures.append("20bones "+group)
	return {"checks":checks,"failures":failures,"tick":m.replay.scrub_tick}

func _copy_bytes(r: Dictionary) -> Dictionary:
	var m = get_tree().current_scene
	if not "phase" in m or m.phase not in [m.Phase.WON,m.Phase.FAILED]: return {"error":"copy requires natural terminal"}
	var offset: int = int(r.get("offset",0))
	if offset == 0:
		record_bytes = var_to_bytes(_record(m))
		record_meta = {"level":m.level.level_id,"attempt":m.battle_log.attempt_id,"schema":m.battle_log.playback_schema,"terminal":m.battle_log.playback_terminal_tick,"reason":m.battle_log.terminal_reason,"bytes":record_bytes.size(),"sha256":_hash(record_bytes),"validation":_validation(m)}
	var count: int = mini(int(r.get("count",1048576)),1048576)
	return {"meta":record_meta,"offset":offset,"chunk_base64":Marshalls.raw_to_base64(record_bytes.slice(offset,mini(offset+count,record_bytes.size())))}

func _dispatch(r: Dictionary) -> void:
	var value: Variant
	var started: int = Time.get_ticks_usec()
	match str(r.action):
		"state": value = _state()
		"controls": value = _controls()
		"project_targets": value = _project(r)
		"copy_record_bytes": value = _copy_bytes(r)
		"fingerprints":
			var m = get_tree().current_scene
			value = {"inputs":input_rows,"replay_rows":replay_rows}
			if "phase" in m: value.merge({"record_sha256":_hash(var_to_bytes(_record(m))),"domain":_domain(m),"full_snapshot":_plain(m._snapshot_data()),"record_validation":_validation(m),"frame_checks":_frame_checks(m)})
		_: value = {"error":"read-only action not allowed"}
	observed_usec += Time.get_ticks_usec()-started
	JavaScriptBridge.get_interface("window").pr15ObserverReply = JSON.stringify({"id":r.id,"value":value})

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag:
		var m = get_tree().current_scene
		var row: Dictionary = {"us":Time.get_ticks_usec(),"scene":m.scene_file_path,"engine_frame":Engine.get_process_frames(),"presents":presents,"phase":int(m.phase) if "phase" in m else -1,"attempt":m.battle_log.attempt_id if "phase" in m else ""}
		if event is InputEventKey: row.merge({"kind":"key","keycode":event.physical_keycode,"pressed":event.pressed,"echo":event.echo})
		elif event is InputEventMouseButton: row.merge({"kind":"mouse","button":event.button_index,"pressed":event.pressed,"pos":_plain(event.position),"device":event.device})
		elif event is InputEventScreenTouch: row.merge({"kind":"touch","index":event.index,"pressed":event.pressed,"canceled":event.canceled,"pos":_plain(event.position)})
		else: row.merge({"kind":"drag","index":event.index,"pos":_plain(event.position)})
		input_rows.append(row)

func _process(delta: float) -> void:
	var m = get_tree().current_scene
	if m != null and "phase" in m and m.phase == m.Phase.REPLAY:
		replay_rows.append({"us":Time.get_ticks_usec(),"tick":m.replay.scrub_tick,"rate":m.replay.speed,"playing":m.replay.playing,"delta":delta,"view_tick":m.presentation_3d.frame.get("playback_tick",-1),"attempt":m.battle_log.attempt_id})
