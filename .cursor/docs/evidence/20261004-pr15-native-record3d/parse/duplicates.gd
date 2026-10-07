extends SceneTree
func _init() -> void:
	var path := OS.get_environment("AMBUSH_NATIVE_RECORD_DIR").path_join("native-player-yard-record.bin")
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var selected := {}
	for record: Dictionary in raw.playback_snapshots:
		var key := str(record.wave_id)+":"+str(record.data.phase)
		if not selected.has(key): selected[key]=record
	for key in selected:
		var first: Dictionary=selected[key]
		var same: Array=raw.playback_snapshots.filter(func(s:Dictionary)->bool:return s.playback_tick==first.playback_tick)
		print(JSON.stringify({"key":key,"requested_frame":first.frame_seq,"playback_tick":first.playback_tick,"same_clock_frames":same.map(func(s:Dictionary)->Dictionary:return {"seq":s.frame_seq,"phase":s.data.phase,"enemy_count":s.data.enemies.size(),"shot_cd":s.data.ops[0].shot_cd})}))
	quit()
