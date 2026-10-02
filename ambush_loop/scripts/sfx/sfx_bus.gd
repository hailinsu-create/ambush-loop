class_name SfxBus
extends Node

## Immutable recorded WAV cues, bounded short voices on the SFX bus.

const MIX_RATE := 22050
const Assets := preload("res://scripts/sfx/audio_assets.gd")
const VOICE_LIMITS := {"gun": 4, "foley": 2, "signal": 1, "ui": 1}
const CUES := [
	"alarm", "alarm_stinger", "fire", "fire_mg", "fire_scout", "fire_smg", "fire_bolt", "fire_garand", "fire_mg42", "fire_pistol", "fire_shotgun", "fire_ping", "return_fire", "empty", "loot", "op_death", "escape", "fail", "win",
	"win_stinger", "door", "trip", "barrel", "kill", "hit", "ui",
	"spawn", "echo_ping",
	"handoff", "leak", "night_enter", "tension",
	"ambient_yard", "ambient_warehouse", "ambient_pump", "ambient_railcut", "ambient_depot", "ambient_radio",
	"foot", "whistle", "knife", "crate_lid", "body_drop", "select", "stealth_bed"
]

var muted: bool = false
var last_cue: String = ""
var _players: Dictionary = {}
var _stream_pool: Dictionary = {}
var _voice_serial := 0
var _voice_order: Dictionary = {}
var _play_calls: Dictionary = {}


func _ready() -> void:
	_build_players()


func _exit_tree() -> void:
	# Drop WAV refs so headless ObjectDB stays quiet on quit.
	for k in _players:
		var p: AudioStreamPlayer = _players[k]
		if p != null and is_instance_valid(p):
			p.stop()
			p.stream = null
	_players.clear()
	_stream_pool.clear()


func _build_players() -> void:
	var bus := _sfx_bus_name()
	for cue in CUES:
		if bool(Assets.record(cue).get("loop", false)):
			continue # Seven loops belong only to AudioDirector's two owners.
		if _players.has(cue) and _players[cue] != null and is_instance_valid(_players[cue]):
			continue
		var p := AudioStreamPlayer.new()
		p.name = "Cue_%s" % cue
		p.stream = _pooled_stream(cue)
		p.volume_db = _gain(cue)
		p.bus = bus
		add_child(p)
		_players[cue] = p


func play(cue: String) -> void:
	last_cue = cue
	if muted:
		return
	# Dummy/headless play() leaves AudioStreamPlaybackWAV in ObjectDB.
	if DisplayServer.get_name() == "headless":
		return
	var bus_index := AudioServer.get_bus_index(_sfx_bus_name())
	if bus_index >= 0 and (AudioServer.is_bus_mute(bus_index) or AudioServer.get_bus_volume_db(bus_index) <= -70.0):
		return
	var p: AudioStreamPlayer = _players.get(cue) as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	var category := str(Assets.record(cue).voice_class)
	var active := []
	for id in _players:
		if _players[id].playing and str(Assets.record(id).voice_class) == category and str(id) != cue:
			active.append(str(id))
	if category == "signal" and not active.is_empty() and _signal_rank(active[0]) > _signal_rank(cue):
		return
	active.sort_custom(func(a: String, b: String) -> bool: return int(_voice_order.get(a, 0)) < int(_voice_order.get(b, 0)))
	while active.size() >= int(VOICE_LIMITS.get(category, 1)):
		_players[active.pop_front()].stop()
	if p.playing:
		p.stop()
	p.play()
	_voice_serial += 1
	_voice_order[cue] = _voice_serial
	_play_calls[cue] = int(_play_calls.get(cue, 0)) + 1


func set_muted(on: bool) -> void:
	muted = on
	if muted:
		for k in _players:
			var p: AudioStreamPlayer = _players[k]
			if p != null and p.playing:
				p.stop()


func toggle_muted() -> bool:
	set_muted(not muted)
	return muted


func has_cue(cue: String) -> bool:
	return not Assets.record(cue).is_empty()


func cue_peak(cue: String) -> float:
	## Peak absolute sample in the pooled WAV. Headless-safe; does not play().
	var st := _pooled_stream(cue)
	if st == null or st.data.is_empty():
		return 0.0
	var peak := 0
	var data: PackedByteArray = st.data
	var i := 0
	while i + 1 < data.size():
		var v := absi(int(data.decode_s16(i)))
		if v > peak:
			peak = v
		i += 2
	return float(peak) / 32767.0


func cue_duration_sec(cue: String) -> float:
	var st := _pooled_stream(cue)
	if st == null or st.data.is_empty():
		return 0.0
	return float(st.data.size() / 2) / float(MIX_RATE)


func ambient_cue_id(level_id: String) -> String:
	match str(level_id):
		"warehouse", "pump", "railcut", "depot", "radio":
			return "ambient_%s" % level_id
		_:
			return "ambient_yard"


func has_mission_ambient(level_id: String) -> bool:
	return has_cue(ambient_cue_id(level_id))


func play_mission_ambient(level_id: String) -> void:
	play(ambient_cue_id(level_id))


func _sfx_bus_name() -> String:
	return "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"


func _pooled_stream(cue: String) -> AudioStreamWAV:
	if bool(Assets.record(cue).get("loop", false)):
		return Assets.stream(cue)
	if _stream_pool.has(cue) and _stream_pool[cue] != null:
		return _stream_pool[cue]
	var st := _build_stream(cue)
	_stream_pool[cue] = st
	return st


func _gain(cue: String) -> float:
	return float(Assets.record(cue).get("recommended_player_gain_db", -80.0))


func _signal_rank(cue: String) -> int:
	return int({"win_stinger": 101, "win": 100, "fail": 100, "escape": 100, "op_death": 95, "alarm_stinger": 91, "alarm": 90, "barrel": 85, "echo_ping": 75, "tension": 60}.get(cue, 40))


func voice_snapshot() -> Array:
	var result := []
	for cue in _players:
		var p: AudioStreamPlayer = _players[cue]
		if p.playing:
			result.append({"cue": str(cue), "class": str(Assets.record(cue).voice_class), "gain_db": p.volume_db, "serial": int(_voice_order.get(cue, 0))})
	return result


func play_calls(cue: String) -> int:
	return int(_play_calls.get(cue, 0))


func _build_stream(cue: String) -> AudioStreamWAV:
	return Assets.stream(cue)
