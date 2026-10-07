extends RefCounted

const MANIFEST := "res://art/audio_v2/manifest.json"
static var _records: Dictionary = {}
static var _loaded := false


static func record(cue: String) -> Dictionary:
	if not _loaded:
		_loaded = true
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		var rule := RegEx.create_from_string("^res://art/audio_v2/[a-z0-9_]+\\.wav$")
		if not doc is Dictionary or int(doc.get("schema", 0)) != 1:
			push_error("AUDIO_MANIFEST_INVALID")
			return {}
		for row in doc.get("cues", []):
			var id := str(row.get("cue", ""))
			if id.is_empty() or _records.has(id) or rule.search(str(row.get("resource_path", ""))) == null:
				push_error("AUDIO_CUE_INVALID " + id)
				continue
			_records[id] = row.duplicate(true)
	return _records.get(cue, {}).duplicate(true)


static func stream(cue: String) -> AudioStreamWAV:
	var row := record(cue)
	if row.is_empty():
		return null
	# Continuous owners keep only their current ambient. No strong global cache
	# pins all six 16-second PCM streams after changing levels.
	var wav := ResourceLoader.load(str(row.resource_path), "AudioStreamWAV", ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
	if wav == null or wav.mix_rate != 22050 or wav.stereo or wav.format != AudioStreamWAV.FORMAT_16_BITS or wav.data.size() != int(row.frames) * 2:
		push_error("AUDIO_STREAM_INVALID " + cue)
		return null
	if bool(row.loop):
		if wav.loop_mode != AudioStreamWAV.LOOP_FORWARD or wav.loop_begin != int(row.loop_begin_frame) or wav.loop_end != int(row.loop_end_frame_exclusive):
			push_error("AUDIO_LOOP_INVALID " + cue)
			return null
	elif wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		push_error("AUDIO_ONESHOT_LOOPS " + cue)
		return null
	return wav
