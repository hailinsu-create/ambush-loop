extends "res://scripts/viewport_hud_test.gd"
## Read-only saved depot counterexample and bounded event text surfaces.
const Log := preload("res://scripts/replay/battle_log.gd")
const DEPOT_SHA := "ec232057b98e04262fd60f4e44933c7545f396ded83be68a05cdea26b4ebb3e0"
var loot_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("LOOT_EVENT_TEXT_FAIL " + message)

func _fixture(payload: Dictionary, expected: String) -> void:
	var event := {"type":"loot","actor_id":1,"target_id":-1,"tick":3,"timeline_tick":600,"position":Vector2.ZERO,"payload":payload}
	var log := Log.new()
	var raw := var_to_bytes(event)
	var text: String = log.format_event(event)
	_check(text == "10.0s  队员1 拾取 " + expected,"source kind/quantity/global time: " + str(payload))
	_check(var_to_bytes(event) == raw,"formatter preserves original sparse event bytes")
	loot_rows.append({"scope":"formatter fixture","payload":payload,"text":text})

func _fixtures() -> void:
	# Names/meaning are listed independently of the formatter and catalog lookup.
	for pair in [["mine","地雷"],["grenade","手雷"],["decoy","诱饵"],["radio_part","电台零件"],["knife","刀"],["ammo","弹药"],["pistol_ammo","手枪弹"],["rifle_ammo","步枪弹"],["mg_ammo","机枪弹"],["scout_ammo","狙弹"],["shotgun_ammo","散弹"],["smg_ammo","冲锋枪弹"]]:
		_fixture({"kind":pair[0],"amount":2},str(pair[1]) + "（数量 2）")
	for pair in [["pistol","手枪"],["rifle","步枪"],["mg","机枪"],["scout","狙"],["shotgun","散弹"],["smg","冲锋枪"],["m1911","M1911"],["luger","卢格"],["m1_garand","M1加兰德"],["kar98k","Kar98k"],["thompson","汤姆逊"],["mp40","MP40"],["bar","BAR"],["mg42","MG42"],["springfield","春田"],["kar98k_zf","98K瞄准镜"]]:
		_fixture({"kind":pair[0],"amount":7},str(pair[1]) + "（携弹 7）")
	_fixture({"kind":"future_crate","amount":4},"物品（future_crate）（数量 4）")
	_fixture({"amount":1},"物品（类型未记录）（数量 1）")
	_fixture({"kind":"mine"},"地雷（数量 ?）")
	_fixture({"kind":"mine","amount":null},"地雷（数量 ?）")
	_fixture({"kind":"mine","amount":0},"地雷（数量 0）")
	_fixture({"kind":"mine","amount":-2},"地雷（数量 -2）")
	_fixture({},"物品（类型未记录）（数量 ?）")
	var old := {"type":"loot","actor_id":2,"tick":60,"payload":{"kind":"ammo","amount":3}}
	_check(Log.new().format_event(old) == "1.0s  队员2 拾取 弹药（数量 3）","legacy local tick still formats without rebinding identity or weapon")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var path := OS.get_environment("AMBUSH_NATIVE_RECORD_DIR").path_join("native-player-depot-record.bin")
	_check(FileAccess.get_sha256(path) == DEPOT_SHA,"original fixed3b depot source SHA")
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var source := Log.new()
	for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]: source.set(key,raw[key])
	var mine: Dictionary = source.events[38]
	_check(mine.event_id == "f3bbcc8550a908a5e5740cfa16df238b:1:38" and mine.payload == {"kind":"mine","amount":1},"actual source counterexample is saved mine1, not synthetic inventory")
	var previous := {}
	var following := {}
	for frame in source.playback_snapshots:
		if int(frame.playback_tick) < int(mine.playback_tick): previous = frame
		elif following.is_empty(): following = frame
	var before: Dictionary = previous.data.ops[0]
	var after: Dictionary = following.data.ops[0]
	_check(int(before.mines) == 0 and int(after.mines) == 1 and int(before.ammo) == 8 and int(after.ammo) == 8,"actual adjacent saved frames: mine0 to1, ammo8 unchanged")
	var expected := "10.7s  队员1 拾取 地雷（数量 1）"
	_check(source.format_event(mine) == expected,"original depot mine text says actual item/quantity, not +1 bullet")
	for event in source.events:
		if event.type != "loot": continue
		var label: String = "地雷" if event.payload.kind == "mine" else "弹药"
		_check(source.format_event(event) == "%.1fs  队员%d 拾取 %s（数量 %s）" % [float(event.timeline_tick)/60.0,event.actor_id,label,str(event.payload.amount)],"all four original depot loot events use saved type/quantity")
	loot_rows.append({"scope":"original fixed3b read-only","event":mine,"before":{"mines":before.mines,"ammo":before.ammo},"after":{"mines":after.mines,"ammo":after.ammo},"text":source.format_event(mine)})
	_fixtures()
	var fingerprint: String = source.fingerprint()
	var settings = root.get_node("GameSettings")
	settings.pending_level_id = "depot"
	settings.mark_tutorial_seen("depot")
	settings.set_force_touch_hud(false)
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	main.phase = main.Phase.WATCHING # Text surface fixture, no actual ALERT battle.
	main.battle_log = source
	var state: Dictionary = main._snapshot_data().duplicate(true)
	main._fill_event_list([mine],1,"现场文字 fixture")
	_check(main.event_list.get_item_text(0) == expected and main._snapshot_data() == state,"live ItemList central text leaves inventory/state unchanged")
	main.phase = main.Phase.REPLAY
	main.replay.bind(source)
	main.replay.pause()
	main.replay.set_tick(main.replay.playback_time(mine))
	main._apply_replay_scrub()
	var foreign := Log.new()
	foreign.begin_attempt("foreign-loot-text")
	foreign.add_event(0,"loot",1,-1,Vector2.ZERO,{"kind":"ammo","amount":99})
	main.battle_log = foreign
	state = main._snapshot_data().duplicate(true)
	var foreign_fingerprint: String = foreign.fingerprint()
	main._focus_battle_event(mine)
	_check(main.status_label.text == "定位 · " + expected and main.replay.log == source,"history focus uses exact saved mine event rather than foreign live ammo")
	main._fill_event_list([mine],1,"原记录")
	_check(main.event_list.get_item_text(0) == expected and main._event_list_items[0] == mine,"history ItemList retains saved event identity and text")
	var saved_list = main.event_list
	var saved_log = main.event_log
	var fallback := RichTextLabel.new()
	main.add_child(fallback)
	main.event_list = null
	main.event_log = fallback
	main._fill_event_list([mine],1,"原记录")
	_check(fallback.text == "[b]原记录[/b]\n" + expected,"history RichText fallback uses same original type/quantity")
	main.event_list = saved_list
	main.event_log = saved_log
	fallback.queue_free()
	_check(main._snapshot_data() == state and foreign.fingerprint() == foreign_fingerprint and source.fingerprint() == fingerprint,"display/focus preserves live inventory and both source logs")
	main._update_hud()
	view.refresh()
	if DisplayServer.get_name() != "headless":
		main._toggle_event_log()
		for _i in 5: await process_frame
		main._focus_battle_event(mine)
		await _modal_capture("loot_depot_saved_mine_history")
	_check(FileAccess.get_sha256(path) == DEPOT_SHA,"original record bytes unchanged; no inventory or event/time rewrite")
	root.get_node("AudioDirector").pause_for_background()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/loot-event-text-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":loot_rows,"captures":captures,"scope":"Read-only original fixed3b depot4loot/mine1/ammo8 plus explicitly synthetic catalog/boundary/text surfaces. Saved3D source bind/focus and rendered text only; not normal journey/full recording3D/ALERT inventory behavior or device acceptance."},"  "))
	print("LOOT_EVENT_TEXT_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
