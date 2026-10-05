extends SceneTree
const Guard := preload("/workspace/ambush-pr15/ambush_loop/scripts/test_storage_guard.gd")
var checks := 0
var failures := 0
func _init() -> void:
	if not Guard.check(): quit(2)
	else: call_deferred("inspect")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("RECORD_INSPECT_FAIL ",text)
func inspect() -> void:
	var path := OS.get_environment("AMBUSH_NATIVE_RECORD")
	var hash_before := FileAccess.get_sha256(path)
	var record: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var counts := {}
	var offsets := {}
	var ids := {}
	var waves := {}
	var previous_tick := -1
	var previous_playback := -1
	var mines := []
	for index in record.events.size():
		var event: Dictionary = record.events[index]
		check(event.attempt_id == record.attempt_id,"event attempt")
		check(event.seq == index,"event sequence")
		check(not ids.has(event.event_id),"unique event identity")
		check(event.event_id == "%s:%d:%d" % [record.attempt_id,event.wave_id,index],"original stored identity")
		check(event.timeline_tick >= previous_tick,"event global time monotonic")
		check(event.playback_tick >= previous_playback,"event playback time monotonic")
		ids[event.event_id] = true
		previous_tick = event.timeline_tick
		previous_playback = event.playback_tick
		var wave: String = str(event.wave_id)
		var offset: int = event.timeline_tick-event.tick
		if offsets.has(wave): check(offsets[wave] == offset,"stable wave global offset")
		else: offsets[wave] = offset
		waves[wave] = int(waves.get(wave,0))+1
		counts[event.type] = int(counts.get(event.type,0))+1
		if event.type == "mine": mines.append(event)
	var phases := []
	previous_playback = -1
	for index in record.playback_snapshots.size():
		var frame: Dictionary = record.playback_snapshots[index]
		check(frame.attempt_id == record.attempt_id,"frame stored attempt")
		check(frame.frame_seq == index,"frame original ordinal")
		check(frame.playback_schema == 2,"frame schema2")
		check(frame.playback_tick >= previous_playback,"frame clock monotonic")
		previous_playback = frame.playback_tick
		if phases.is_empty() or phases.back() != frame.data.phase: phases.append(frame.data.phase)
	check(phases == [0,1,5,1,5,1,5,3],"actual SCOUT and three ALERT SWEEP pairs then WON")
	check(offsets == {"0":0,"1":int(OS.get_environment("AMBUSH_EXPECT_WAVE_BOUNDARY")),"2":int(OS.get_environment("AMBUSH_EXPECT_WAVE_BOUNDARY_2"))},"actual player wave boundary")
	check(record.playback_schema == 2,"original schema2 metadata")
	check(record.terminal_reason == "win" and record.terminal_tick == int(OS.get_environment("AMBUSH_EXPECT_NATIVE_TERMINAL")),"actual native player terminal")
	check(record.playback_terminal_tick == record.playback_snapshots.back().playback_tick,"final frame exact playback terminal")
	check(FileAccess.get_sha256(path) == hash_before,"native source bytes unchanged")
	var result := {"scope":"Read-only original native serialized record metadata; no gameplay scene, simulation, replay rendering or fixture mutation.","checks":checks,"failures":failures,"raw_sha256":hash_before,"attempt":record.attempt_id,"events":record.events.size(),"event_counts":counts,"wave_event_counts":waves,"global_wave_offsets":offsets,"phase_sequence":phases,"mine_events":mines,"frames":record.playback_snapshots.size(),"terminal_tick":record.terminal_tick,"playback_terminal_tick":record.playback_terminal_tick}
	var output := FileAccess.open(OS.get_environment("AMBUSH_RECORD_INSPECT_REPORT"),FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  "))
	output.close()
	print("NATIVE_RECORD_INSPECT checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
