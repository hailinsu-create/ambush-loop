extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/sfx/audio_assets.gd")
var checks := 0
var failures := 0
var measured: Array = []
var capture: AudioEffectCapture


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("AUDIO_RUNTIME: " + message)


func _count(audio: Node, category: String) -> int:
	return audio.voice_snapshot().filter(func(row: Dictionary) -> bool: return str(row["class"]) == category).size()


func _peak(buffer: PackedVector2Array) -> float:
	var peak := 0.0
	var finite := true
	for sample in buffer:
		finite = finite and sample.is_finite()
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	_check(finite, "all actual mixer samples are finite")
	return peak


func _mix() -> PackedVector2Array:
	return capture.get_buffer(capture.get_frames_available())


func _run() -> void:
	var audio = root.get_node("AudioDirector")
	var settings = root.get_node("GameSettings")
	audio.pause_for_background()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.MANIFEST))
	_check(manifest.cues.size() == 45 and audio._players.size() == 38, "45 recorded cues have 38 short players and no duplicate loop players")
	for row in manifest.cues:
		var cue: String = row.cue
		_check(audio.has_cue(cue) and FileAccess.get_sha256(row.resource_path) == row.sha256, "fixed original audio bytes: " + cue)
		var stream := Assets.stream(cue)
		_check(stream != null and stream.mix_rate == 22050 and not stream.stereo and stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.data.size() == int(row.frames) * 2, "actual imported PCM format/frame count: " + cue)
		if stream != null:
			_check(stream.loop_mode == (AudioStreamWAV.LOOP_FORWARD if row.loop else AudioStreamWAV.LOOP_DISABLED), "actual loop mode: " + cue)
			if row.loop:
				_check(stream.loop_begin == 0 and stream.loop_end == 352800 and not audio._players.has(cue), "whole-period exclusive loop belongs only to continuous owner: " + cue)
			else:
				_check(is_equal_approx(audio._players[cue].volume_db, row.recommended_player_gain_db), "candidate gain is applied once: " + cue)
	_check(not audio.has_cue("unknown") and Assets.stream("unknown") == null, "unknown cue refuses")
	if DisplayServer.get_name() == "headless":
		push_error("AUDIO_RUNTIME actual playback/mixing requires rendered driver, no bind-only pass")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	settings.reset_to_defaults()
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	audio.resume_from_background()
	audio.set_muted(false)
	capture = AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), capture)
	# The audio thread installs a new effect asynchronously. Prove that it has
	# supplied frames before measuring the first cue; a zero-frame startup is
	# not evidence that a resource played silently.
	audio.stop_mission_audio()
	for i in 20:
		if capture.get_frames_available() > 0:
			break
		await create_timer(0.03).timeout
	_check(capture.get_frames_available() > 0, "actual mixer capture is installed before first cue")
	# Execute play() for every actual imported resource. Dummy still runs the
	# AudioServer mixer; capture is engineering evidence, never an ear review.
	for row in manifest.cues:
		audio.stop_mission_audio()
		audio.set_phase_state(false, false, false)
		capture.clear_buffer()
		var before: int = audio.play_calls(row.cue)
		audio.play(row.cue)
		_check(audio.play_calls(row.cue) > before, "actual AudioStreamPlayer.play call: " + str(row.cue))
		_check(not audio.voice_snapshot().is_empty(), "actual playing owner: " + str(row.cue))
		await create_timer(0.12).timeout
		var buffer := _mix()
		var peak := _peak(buffer)
		_check(not buffer.is_empty() and peak > 0.00001 and peak < 0.77, "actual mixer has non-silent bounded output: " + str(row.cue))
		measured.append({"cue": row.cue, "frames": buffer.size(), "peak": peak, "actual_play_calls": audio.play_calls(row.cue)})
	audio.stop_mission_audio()
	audio.set_phase_state(false, false, false)
	audio.play_mission_mood("yard")
	await create_timer(0.12).timeout
	_check(_count(audio, "ambient") == 1 and _count(audio, "bed") == 1, "current mission has exactly one ambient and bed")
	var calls: int = audio.play_calls("ambient_yard")
	main._play_mission_ambient()
	main._play_mission_ambient()
	_check(audio.play_calls("ambient_yard") == calls, "legacy ambient+mood duplicate entry does not restart or double-play")
	capture.clear_buffer()
	for cue in ["fire", "fire_mg", "fire_scout", "fire_smg", "fire_bolt", "loot", "hit", "empty", "ui", "select", "alarm", "barrel", "echo_ping"]:
		audio.play(cue)
	_check(_count(audio, "gun") == 4 and _count(audio, "foley") == 2 and _count(audio, "ui") == 1 and _count(audio, "signal") == 1 and audio.voice_snapshot().size() == 10, "actual dense playback enforces all ten voice slots")
	_check(not audio._players.fire.playing and audio._players.fire_bolt.playing and not audio._players.ui.playing and audio._players.select.playing, "newest gun/UI replaces oldest within its own class")
	_check(audio._players.alarm.playing and not audio._players.barrel.playing and not audio._players.echo_ping.playing, "lower urgency cannot displace current alarm signal")
	await create_timer(0.08).timeout
	var stress := _mix()
	var stress_peak := _peak(stress)
	_check(not stress.is_empty() and stress_peak > 0.001 and stress_peak < 0.77, "actual dense mixed output stays finite and below candidate bound")
	var dump := AudioStreamWAV.new()
	dump.mix_rate = int(AudioServer.get_mix_rate())
	dump.format = AudioStreamWAV.FORMAT_16_BITS
	dump.stereo = true
	var pcm := PackedByteArray()
	pcm.resize(stress.size() * 4)
	for i in stress.size():
		pcm.encode_s16(i * 4, int(clampf(stress[i].x, -1, 1) * 32767))
		pcm.encode_s16(i * 4 + 2, int(clampf(stress[i].y, -1, 1) * 32767))
	dump.data = pcm
	var directory := "res://build/asset_review/pr15-runtime"
	DirAccess.make_dir_recursive_absolute(directory)
	_check(dump.save_to_wav(directory.path_join("audio_v2_actual_mix_stress.wav")) == OK, "save actual captured mixer WAV")
	audio.play("win")
	audio.play("win_stinger")
	_check(_count(audio, "signal") == 1 and audio._players.win_stinger.playing and not audio._players.win.playing and not audio._players.alarm.playing, "terminal signal replaces alarm and remains mutually exclusive")
	for level in ["warehouse", "pump", "railcut", "depot", "radio", "yard"]:
		main._load_level(level, false, false)
		await process_frame
		await create_timer(0.12).timeout
		_check(audio._mood_id == level and _count(audio, "ambient") == 1 and _count(audio, "bed") == 1, "actual level switch owns only its current ambient: " + level)
		_check(audio._mood.stream.loop_end == 352800 and not audio._players.win_stinger.playing, "level change preserves loop and stops old terminal cue: " + level)
	settings.set_music_volume(0.0)
	_check(_count(audio, "ambient") == 0 and _count(audio, "bed") == 0 and not audio.muted, "Music zero stops only continuous owners")
	audio.play("alarm")
	_check(audio._players.alarm.playing, "SFX stays audible when Music is zero")
	settings.set_sfx_volume(0.0)
	_check(audio.voice_snapshot().is_empty(), "SFX zero stops existing one-shots")
	settings.set_music_volume(1.0)
	audio.play("alarm")
	_check(_count(audio, "ambient") == 1 and not audio._players.alarm.playing, "Music restores independently without replaying muted SFX")
	settings.set_sfx_volume(1.0)
	settings.set_quality_tier(settings.QUALITY_POWER_SAVING)
	_check(_count(audio, "bed") == 0 and _count(audio, "ambient") == 1, "power saving disables optional bed, keeps environment")
	audio.play("alarm")
	_check(audio._players.alarm.playing, "power saving preserves danger signal")
	settings.set_quality_tier(settings.QUALITY_STANDARD)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.raid_force_alarm()
	for i in 240:
		if main.phase == main.Phase.WATCHING:
			main._sim_tick()
	main._update_hud()
	_check(main.phase == main.Phase.WATCHING and is_equal_approx(audio._music.volume_db, Assets.record("stealth_bed").recommended_player_gain_db - 5.0), "actual ALERT ducks bed by five dB")
	main._on_pause_pressed()
	_check(main.sim.paused and audio.voice_snapshot().is_empty(), "actual simulation pause stops all playback")
	var shot_calls: int = audio.play_calls("fire")
	audio.play("fire")
	_check(audio.play_calls("fire") == shot_calls, "paused late shot is discarded, no backlog")
	main._on_pause_pressed()
	_check(not main.sim.paused and _count(audio, "ambient") == 1 and _count(audio, "bed") == 1 and _count(audio, "gun") == 0, "simulation resume restores only continuous owners")
	main._toggle_pause_menu()
	_check(main.pause_overlay.is_open() and audio.voice_snapshot().is_empty(), "actual menu pause stops audio")
	main.pause_overlay.dismiss()
	_check(_count(audio, "ambient") == 1, "menu close restores current mission layer")
	main.handle_app_focus_out()
	_check(audio.is_background_paused() and audio.voice_snapshot().is_empty(), "actual background stops current loops and shots")
	main.handle_app_focus_in()
	_check(not audio.is_background_paused() and _count(audio, "ambient") == 1 and _count(audio, "gun") == 0, "foreground resumes current layer without backlog")
	main._on_replay_pressed()
	_check(audio.voice_snapshot().is_empty(), "actual replay enters silence instead of replaying old event prefix")
	var before: int = audio.play_calls("fire")
	for tick in [0, main.replay.max_tick(), 0]:
		main.replay.set_tick(tick)
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
	_check(audio.play_calls("fire") == before and audio.voice_snapshot().is_empty(), "backward/forward seek cannot replay past shot prefix")
	main._exit_replay_to_setup()
	_check(_count(audio, "ambient") == 1 and _count(audio, "gun") == 0, "replay exit resets current mission audio without old shots")
	audio.play("fail")
	main._start_setup(false, false)
	_check(not audio._players.fail.playing and _count(audio, "ambient") == 1, "actual retry stops old failure cue")
	settings.set_muted(true)
	_check(audio.voice_snapshot().is_empty(), "global mute stops both buses")
	settings.set_muted(false)
	_check(_count(audio, "ambient") == 1 and _count(audio, "signal") == 0, "unmute restores layers, no previous failure backlog")
	main._return_to_title()
	await process_frame
	await process_frame
	_check(audio.voice_snapshot().is_empty() and not audio._want_mood and not audio._want_music, "actual return to title releases mission ownership")
	var report := {"actual_playback": true, "driver": "AudioServer rendered/Dummy", "auditory_review": "NOT_LISTENED", "measured_cues": measured, "stress_peak": stress_peak, "stress_frames": stress.size(), "mix_rate": AudioServer.get_mix_rate()}
	var file := FileAccess.open(directory.path_join("audio_v2_runtime_mix.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	audio._stop_music_hard()
	await process_frame
	await create_timer(0.15).timeout
	AudioServer.remove_bus_effect(AudioServer.get_bus_index("Master"), AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Master")) - 1)
	capture = null
	print("AUDIO_RUNTIME_OK" if failures == 0 else "AUDIO_RUNTIME_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
