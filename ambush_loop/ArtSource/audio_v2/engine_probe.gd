# SPDX-License-Identifier: MIT
extends SceneTree

## Read-only minimal-project probe; no gameplay autoload or player save access.
## PCM data and import flags are checked; Dummy playback is deliberately avoided.

func _initialize() -> void:
	var file := FileAccess.open("res://art/audio_v2/catalog_candidate.json", FileAccess.READ)
	if file == null:
		push_error("AUDIO_V2_GODOT_CATALOG_MISSING")
		quit(2)
		return
	var catalog: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var rows: Array = []
	for record in catalog.cues:
		var stream := load(str(record.resource_path)) as AudioStreamWAV
		if stream == null:
			push_error("AUDIO_V2_GODOT_LOAD " + str(record.cue))
			quit(2)
			return
		var expected_loop := AudioStreamWAV.LOOP_FORWARD if bool(record.loop) else AudioStreamWAV.LOOP_DISABLED
		var okay := stream.mix_rate == 22050 and not stream.stereo and stream.format == AudioStreamWAV.FORMAT_16_BITS
		okay = okay and stream.data.size() == int(record.frames) * 2 and stream.loop_mode == expected_loop
		if bool(record.loop):
			okay = okay and stream.loop_begin == 0 and stream.loop_end == int(record.frames)
		var pcm_sha: String
		var wav := FileAccess.open(str(record.resource_path), FileAccess.READ)
		var bytes := wav.get_buffer(wav.get_length())
		wav.close()
		var offset := 12
		var found_pcm := false
		while offset + 8 <= bytes.size():
			var label := bytes.slice(offset, offset + 4).get_string_from_ascii()
			var count := int(bytes.decode_u32(offset + 4))
			if label == "data":
				found_pcm = true
				okay = okay and bytes.slice(offset + 8, offset + 8 + count) == stream.data
				break
			offset += 8 + count + count % 2
		okay = okay and found_pcm
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(stream.data)
		pcm_sha = ctx.finish().hex_encode()
		# Instantiate a real AudioStreamPlayer and bind/release the imported stream.
		# This verifies assignment only: no acoustic output or timing/performance claim.
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = float(record.recommended_player_gain_db)
		root.add_child(player)
		okay = okay and player.stream == stream
		player.stream = null
		player.free()
		var row := {"cue": str(record.cue), "pass": okay, "mix_rate": stream.mix_rate,
			"stereo": stream.stereo, "format": stream.format, "pcm_bytes": stream.data.size(),
			"pcm_sha256": pcm_sha, "duration_sec": stream.get_length(), "loop_mode": stream.loop_mode,
			"loop_begin": stream.loop_begin, "loop_end_exclusive": stream.loop_end,
			"byte_identical_to_source_pcm": found_pcm and okay, "playback": "NOT_PLAYED_NOT_LISTENED"}
		rows.append(row)
		print("AUDIO_V2_GODOT_CUE ", JSON.stringify(row))
		if not okay:
			push_error("AUDIO_V2_GODOT_CONTRACT " + str(record.cue))
			quit(2)
			return
	var output := FileAccess.open("res://engine_report.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info(), "cue_count": rows.size(), "status": "IMPORT_RESOURCE_BIND_PASS_NOT_LISTENED", "cues": rows}, "  ") + "\n")
	output.close()
	print("AUDIO_V2_GODOT_IMPORT_OK cues=", rows.size(), " loops=7 audio_driver=Dummy listening=NOT_LISTENED")
	quit(0)
