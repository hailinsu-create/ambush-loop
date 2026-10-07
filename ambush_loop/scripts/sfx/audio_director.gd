extends "res://scripts/sfx/sfx_bus.gd"

## Exactly one current ambient and one optional bed. No procedural/once-cue
## loop competes with them. Every stop gate discards one-shot backlog.
var _music: AudioStreamPlayer
var _music_stream: AudioStreamWAV
var _want_music := false
var _watch_bed := false
var _background_paused := false
var _simulation_paused := false
var _replay_mode := false
var _mood: AudioStreamPlayer
var _mood_id := ""
var _want_mood := false
var _mood_stream: AudioStreamWAV
var _mood_fade: Tween
var _continuous_calls: Dictionary = {}


func _ready() -> void:
	_ensure_buses()
	super._ready()
	_setup_music()
	var gs = get_node_or_null("/root/GameSettings")
	if gs and not gs.changed.is_connected(_on_settings_changed):
		gs.changed.connect(_on_settings_changed)
	_on_settings_changed()


func _exit_tree() -> void:
	_stop_music_hard()
	super._exit_tree()


func _ensure_buses() -> void:
	for spec in [["Music", -6.0], ["SFX", 0.0]]:
		if AudioServer.get_bus_index(spec[0]) < 0:
			AudioServer.add_bus(-1)
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, spec[0])
			AudioServer.set_bus_send(index, "Master")
			AudioServer.set_bus_volume_db(index, spec[1])


func _setup_music() -> void:
	_music_stream = Assets.stream("stealth_bed")
	_music = AudioStreamPlayer.new()
	_music.name = "MusicBed"
	_music.bus = "Music"
	_music.stream = _music_stream
	add_child(_music)
	_mood = AudioStreamPlayer.new()
	_mood.name = "MoodBed"
	_mood.bus = "Music"
	add_child(_mood)
	_apply_music_gain()


func _can_play_audio() -> bool:
	return DisplayServer.get_name() != "headless"


func _gated() -> bool:
	return muted or _background_paused or _simulation_paused or _replay_mode or not _can_play_audio()


func _bus_enabled(name: String) -> bool:
	var index := AudioServer.get_bus_index(name)
	return index >= 0 and not AudioServer.is_bus_mute(index) and AudioServer.get_bus_volume_db(index) > -70.0


func _stop_active_sfx() -> void:
	for p in _players.values():
		if p != null and is_instance_valid(p):
			p.stop()


func _cancel_fade() -> void:
	if _mood_fade != null:
		_mood_fade.kill()
		_mood_fade = null


func _stop_continuous() -> void:
	_cancel_fade()
	if _music != null:
		_music.stop()
	if _mood != null:
		_mood.stop()


func set_background_muted(on: bool) -> void:
	_background_paused = on
	if on:
		_stop_active_sfx()
		_stop_continuous()
	else:
		_apply_music_mute()
		_apply_mood_mute()


func pause_for_background() -> void:
	set_background_muted(true)


func resume_from_background() -> void:
	set_background_muted(false)


func is_background_paused() -> bool:
	return _background_paused


func set_phase_state(watch: bool, paused: bool, replay: bool) -> void:
	_watch_bed = watch
	_simulation_paused = paused
	_replay_mode = replay
	if _gated():
		_stop_active_sfx()
		_stop_continuous()
	_apply_music_gain()
	_apply_music_mute()
	_apply_mood_params()
	_apply_mood_mute()


func set_watch_bed(on: bool) -> void:
	set_phase_state(on, _simulation_paused, _replay_mode)


func set_muted(on: bool) -> void:
	super.set_muted(on)
	_apply_music_mute()
	_apply_mood_mute()


func _on_settings_changed() -> void:
	var gs = get_node_or_null("/root/GameSettings")
	if gs:
		set_muted(bool(gs.muted))
	if not _bus_enabled("SFX"):
		_stop_active_sfx()
	_apply_music_gain()
	_apply_music_mute()
	_apply_mood_params()
	_apply_mood_mute()


func _mood_off_for_tier() -> bool:
	var gs = get_node_or_null("/root/GameSettings")
	return gs != null and gs.has_method("is_power_saving") and bool(gs.is_power_saving())


func _apply_music_gain() -> void:
	if _music != null:
		_music.volume_db = _gain("stealth_bed") - (5.0 if _watch_bed else 0.0)


func _apply_music_mute() -> void:
	if _music == null:
		return
	if _gated() or not _want_music or not _bus_enabled("Music") or _mood_off_for_tier():
		_music.stop()
		return
	if _music.stream == null:
		_music_stream = Assets.stream("stealth_bed")
		_music.stream = _music_stream
	if not _music.playing:
		_music.play()
		_continuous_calls["stealth_bed"] = int(_continuous_calls.get("stealth_bed", 0)) + 1


func _apply_mood_params() -> void:
	if _mood != null and _mood_fade == null:
		_mood.volume_db = _gain(ambient_cue_id(_mood_id)) - (5.0 if _watch_bed else 0.0)
		_mood.pitch_scale = 1.0


func _apply_mood_mute() -> void:
	if _mood == null:
		return
	if _gated() or not _want_mood or not _bus_enabled("Music"):
		_cancel_fade()
		_mood.stop()
		return
	if not _mood.playing and _mood.stream != null:
		_mood.play()
		var cue := ambient_cue_id(_mood_id)
		_continuous_calls[cue] = int(_continuous_calls.get(cue, 0)) + 1


func play(cue: String) -> void:
	last_cue = cue
	if _gated():
		return
	var row := Assets.record(cue)
	if bool(row.get("loop", false)):
		if cue == "stealth_bed":
			_want_music = true
			_apply_music_mute()
		else:
			play_mission_mood(cue.trim_prefix("ambient_"))
		return
	if _bus_enabled("SFX"):
		super.play(cue)


func play_mission_ambient(level_id: String) -> void:
	# Existing main calls both ambient and mood. Both route to the same owner.
	play_mission_mood(level_id)


func play_mission_mood(level_id: String) -> void:
	if not has_mission_mood(level_id):
		return
	if _mood_id == level_id and _want_mood:
		_apply_music_mute()
		_apply_mood_mute()
		return
	_stop_active_sfx()
	_cancel_fade()
	_mood.stop() # No old-level stream or second ambient overlaps the new one.
	_mood.stream = null
	_mood_stream = null
	_mood_id = level_id
	_want_mood = true
	_want_music = true
	_mood_stream = Assets.stream(ambient_cue_id(level_id))
	_mood.stream = _mood_stream
	_apply_music_gain()
	_apply_music_mute()
	_apply_mood_params()
	_apply_mood_mute()
	if _mood.playing:
		var target := _mood.volume_db
		_mood.volume_db = -80.0
		_mood_fade = create_tween()
		_mood_fade.tween_property(_mood, "volume_db", target, 0.08)
		_mood_fade.tween_callback(func() -> void:
			_mood_fade = null
			_apply_mood_params()
		)


func stop_mission_audio() -> void:
	_stop_active_sfx()
	_stop_continuous()
	_want_mood = false
	_want_music = false
	_mood_id = ""
	_simulation_paused = false
	_replay_mode = false
	if _mood != null:
		_mood.stream = null
	_mood_stream = null


func _stop_music_hard() -> void:
	stop_mission_audio()
	if _music != null:
		_music.stream = null
	_music_stream = null


func has_music_bed() -> bool:
	return _music != null and _music.stream != null


func has_layered_mood() -> bool:
	return _mood != null and _mood.stream != null


func music_bus_ok() -> bool:
	return AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0


func music_player_playing() -> bool:
	return _music != null and _music.playing


func music_is_running() -> bool:
	return not _gated() and music_player_playing()


func has_mission_mood(level_id: String) -> bool:
	return level_id in ["yard", "warehouse", "pump", "railcut", "depot", "radio"] and has_cue(ambient_cue_id(level_id))


func mission_mood_pitch(level_id: String) -> float:
	return float({"yard": 0.92, "warehouse": 0.78, "pump": 0.64, "railcut": 1.14, "depot": 0.55, "radio": 1.28}.get(level_id, 0.0))


func mission_mood_filter_hz(level_id: String) -> float:
	return float({"yard": 1400, "warehouse": 720, "pump": 380, "railcut": 2100, "depot": 260, "radio": 2800}.get(level_id, 0.0))


func voice_snapshot() -> Array:
	var rows := super.voice_snapshot()
	if _music != null and _music.playing:
		rows.append({"cue": "stealth_bed", "class": "bed", "gain_db": _music.volume_db})
	if _mood != null and _mood.playing:
		rows.append({"cue": ambient_cue_id(_mood_id), "class": "ambient", "gain_db": _mood.volume_db})
	return rows


func play_calls(cue: String) -> int:
	return int(_continuous_calls.get(cue, 0)) if bool(Assets.record(cue).get("loop", false)) else super.play_calls(cue)
