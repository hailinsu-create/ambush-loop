extends "res://scripts/static_teaching_context_test.gd"
## Original late escape/retry plus explicit legacy/corrupt-context formatter fixtures.
var intel_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("ESCAPE_INTEL_FAIL " + sample + " " + message)

func _mutated(context: Dictionary, path: Array, value: Variant) -> Dictionary:
	var copy := context.duplicate(true)
	var cursor: Dictionary = copy
	for i in path.size()-1: cursor = cursor[path[i]]
	cursor[path[-1]] = value
	return copy

func _unit_contexts(observed: Dictionary) -> void:
	sample = "explicit_legacy_and_context_boundary_fixtures"
	var store: Variant = IntelStore.new()
	var path := PackedVector2Array([Vector2.ZERO,Vector2(40,0)])
	store.add_path(1,path,6.0,"escape","侧翼奔袭从东廊漏出","flank",360,4)
	var old_bytes := var_to_bytes(store.records)
	var legacy: String = store.leak_advice_line(LevelDef.by_id("railcut"),"侧翼")
	_check(legacy.contains("敌4") and legacy.contains("未确认") and not legacy.contains("1.4") and not legacy.contains("2.2") and not legacy.contains("改一处"),"old8-argument record is readable without guessing current-level spawn/deadline")
	_check(var_to_bytes(store.records) == old_bytes and not store.records[0].has("escape_context"),"old memory bytes are not upgraded during display")
	_check(store.has_method("validated_escape_context") and store.has_method("make_escape_context"),"versioned saved-event validation interface exists")
	if not store.has_method("validated_escape_context") or not store.has_method("make_escape_context"): return
	var expected := {"schema":1,"level_id":"radio","attempt_id":observed.spawn.attempt_id,"wave_id":2,"actor_id":5,"spawn":observed.spawn.duplicate(true),"escape":observed.escape.duplicate(true)}
	var context: Dictionary = store.call("make_escape_context","radio",observed.spawn,observed.escape)
	_check(context == expected,"context copies original spawn/escape identities and all event fields")
	store.call("add_path",2,path,15.95,"escape","回波从碟台夹缝漏出","echo",957,5,context)
	var actual: Dictionary = store.records[-1]
	_check(store.call("validated_escape_context",actual,"radio") == expected,"valid context exposes original source")
	context.spawn.tick = 900
	var returned: Dictionary = store.call("validated_escape_context",actual,"radio")
	returned.spawn.tick = 901
	path[0] = Vector2(777,777)
	_check(actual.escape_context == expected and actual.path[0] == Vector2.ZERO,"caller/returned context/path cannot mutate stored source")
	var valid_line: String = store.leak_advice_line(LevelDef.by_id("radio"),"回波")
	_check(valid_line.contains("历史第3波") and valid_line.contains("0.5") and valid_line.contains("15.9") and not valid_line.contains("5.2") and not valid_line.contains("10.8"),"advice states historical actual local times without authored arithmetic")
	var cases := [
		[["schema"],99],[["schema"],"1"],[["level_id"],"yard"],[["attempt_id"],"foreign"],[["wave_id"],0],[["actor_id"],4],
		[["spawn","attempt_id"],"foreign"],[["escape","wave_id"],1],[["escape","actor_id"],4],[["spawn","type"],"fire"],
		[["escape","type"],"kill"],[["spawn","tick"],-1],[["escape","tick"],29],[["escape","timeline_tick"],743],
		[["escape","playback_tick"],746],[["escape","seq"],43],[["spawn","event_id"],"foreign:2:43"],
		[["escape","payload","route"],"main"],[["spawn","payload","route"],"unknown"],[["spawn"],{}],[["escape","payload"],"corrupt"],
	]
	for item in cases:
		var malformed := actual.duplicate(true)
		malformed.escape_context = _mutated(expected,item[0],item[1])
		store.records = [malformed]
		var before := var_to_bytes(store.records)
		var line: String = store.leak_advice_line(LevelDef.by_id("radio"),"回波")
		_check(store.call("validated_escape_context",malformed,"radio").is_empty() and line.contains("未确认") and not line.contains("历史第3波") and not line.contains("5.2") and not line.contains("10.8"),"bad context uses neutral fallback " + str(item[0]))
		_check(var_to_bytes(store.records) == before,"bad context display preserves old bytes " + str(item[0]))
	for context_value in [null,"corrupt",{},[]]:
		var sparse := {"reason":"escape","route":"echo","leaker_id":5,"escape_context":context_value}
		_check(store.call("validated_escape_context",sparse,"radio").is_empty(),"missing/nonDictionary context is neutral " + str(context_value))
	store.records = [actual]
	_check(store.call("validated_escape_context",actual,"yard").is_empty() and store.leak_advice_line(LevelDef.by_id("yard"),"回波").contains("未确认"),"foreign level cannot borrow current level/wave/time")
	store.clear()
	for i in 6: store.add_path(i,path,float(i),"abort")
	store.add_path(99,PackedVector2Array([Vector2.ZERO]),0.0,"escape")
	_check(store.records.size()==5 and store.records[0].loop==1 and store.records[-1].loop==5,"legacy max5/reject short path contract retained")
	intel_rows.append({"scope":"explicit formatter legacy/context validation fixtures, not battles","legacy":legacy,"valid":valid_line,"bad_context_cases":cases.size()+4})

func _actual_facts() -> void:
	var observed: Dictionary = context_rows.filter(func(row: Dictionary) -> bool: return row.has("spawn"))[-1]
	var rec: Dictionary = main.intel.records[-1]
	var context: Variant = rec.get("escape_context",{})
	_check(context is Dictionary and context.get("schema",-1)==1 and context.get("attempt_id","")==observed.spawn.attempt_id and context.get("attempt_id","")!=main.battle_log.attempt_id and context.get("wave_id",-1)==2,"original retry retains saved old attempt/wave identity")
	_check(context is Dictionary and context.get("spawn",{})==observed.spawn and context.get("escape",{})==observed.escape,"stored context contains original exact spawn/escape events")
	var body: String = observed.actual_fail_body
	var advice: String = observed.actual_advice
	_check(body.contains("第3波漏网") and body.contains("0.5s出发") and body.contains("15.9s逃逸") and not body.contains("5.2s出发") and not body.contains("晚 5.2"),"actual FAILED uses original third-wave local spawn/escape times")
	_check(observed.actual_hint.contains("回波") and not observed.actual_hint.contains("主路巡卫") and not observed.actual_hint.contains("5.2"),"actual echo hint identifies echo rather than default main runner")
	_check(advice.contains("历史第3波") and advice.contains("0.5") and advice.contains("15.9") and not advice.contains("10.8") and not advice.contains("改一处"),"actual advice records facts without guaranteed win or invented deadline")
	_check(main.leak_advice_text()==advice and main._leak_result_line().contains("第3波") and main._leak_result_line().contains("0.5"),"original new SCOUT reads historical wave/time rather than new attempt")
	var snapshot: Dictionary = main._snapshot_data().duplicate(true)
	var fingerprint: String = main.battle_log.fingerprint()
	var memory := var_to_bytes(main.intel.records)
	main._leak_result_line()
	main._leak_advice_line()
	_check(main._snapshot_data()==snapshot and main.battle_log.fingerprint()==fingerprint and var_to_bytes(main.intel.records)==memory,"fact display preserves state/ammo/HP/new log/stored old memory")
	intel_rows.append({"scope":"original reference late escape/retry; grants/snaps/directticks/vacuum/SWEEP clear, not normal input","source_spawn":observed.spawn,"source_escape":observed.escape,"stored_record":rec.duplicate(true),"fail_body":body,"advice":advice,"retry_body":main._leak_result_line(),"retry_attempt":main.battle_log.attempt_id})
	await _unit_contexts(observed)

func _run() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for id in ["yard","warehouse","pump","railcut","depot","radio"]: settings.mark_tutorial_seen(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	await _radio_reference()
	await _actual_facts()
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/escape-intel-source-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":intel_rows,"reference_rows":context_rows,"captures":captures,"scope":"Original radio3wave late escape/retry reference and explicit legacy/corrupt saved context fixtures. Not normal13/fullrecord3D/legacy2D/FX/A3/audio/device acceptance."},"  "))
	print("ESCAPE_INTEL_SOURCE_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
