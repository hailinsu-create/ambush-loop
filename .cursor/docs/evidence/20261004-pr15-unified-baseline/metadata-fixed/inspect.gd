extends SceneTree
var checks := 0
var failures := 0
var rows := []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("NATIVE_METADATA_FAIL " + message)
func _init() -> void:
	var directory := OS.get_environment("AMBUSH_NATIVE_RECORD_DIR")
	for id in ["yard","warehouse","pump","railcut","depot","radio"]:
		var path: String = directory.path_join("native-player-"+id+"-record.bin")
		var hash_before := FileAccess.get_sha256(path)
		var data: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
		var attempt: String = data.attempt_id
		check(data.playback_schema==2 and data.terminal_reason=="win",id+" new complete schema2 WON")
		var wave_set := {}
		var events_by_type := {}
		var previous := -1
		var previous_playback := -1
		for i in data.events.size():
			var event: Dictionary = data.events[i]
			check(event.attempt_id==attempt and event.schema==2 and event.seq==i,id+" stable original attempt/seq")
			check(event.event_id=="%s:%d:%d" % [attempt,event.wave_id,i],id+" stable event identity")
			check(event.timeline_tick>=previous and event.playback_tick>=previous_playback,id+" monotonic global/playback event clock")
			previous=event.timeline_tick
			previous_playback=event.playback_tick
			wave_set[event.wave_id]=true
			events_by_type[event.type]=events_by_type.get(event.type,0)+1
		previous=-1
		var phase_set := {}
		for i in data.playback_snapshots.size():
			var record: Dictionary = data.playback_snapshots[i]
			check(record.attempt_id==attempt and record.frame_seq==i and record.playback_schema==2,id+" stable continuous frame identity")
			check(record.playback_tick>=previous,id+" continuous monotonic snapshot clock")
			check(record.data.level_id==id,id+" recorded level source")
			previous=record.playback_tick
			phase_set[record.data.phase]=true
		check(wave_set.size()==(3 if id=="radio" else 2),id+" complete original wave membership")
		check(data.playback_terminal_tick>=previous and data.playback_terminal_tick>=previous_playback,id+" terminal includes whole saved attempt")
		check(phase_set.has(0) and phase_set.has(1) and phase_set.has(5) and phase_set.has(3),id+" SCOUT ALERT SWEEP WON saved")
		check(FileAccess.get_sha256(path)==hash_before,id+" raw bytes unchanged")
		rows.append({"level":id,"sha256":hash_before,"attempt":attempt,"schema":data.playback_schema,"events":data.events.size(),"battle_snapshots":data.snapshots.size(),"frames":data.playback_snapshots.size(),"terminal_tick":data.terminal_tick,"playback_terminal_tick":data.playback_terminal_tick,"waves":wave_set.keys(),"phases":phase_set.keys(),"events_by_type":events_by_type})
	var file := FileAccess.open(OS.get_environment("AMBUSH_METADATA_OUTPUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"record_source_sha":"a05fa959093ef5b6733466091a04fbb46647f97b","checks":checks,"failures":failures,"rows":rows,"scope":"Pure read-only Godot built-in bytes_to_var metadata. No project autoloads, BattleLog playback, rendered3D, simulation or source upgrades."},"  "))
	file.close()
	print("NATIVE_METADATA_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
