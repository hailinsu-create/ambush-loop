extends Node
class_name G2SfxPlayer

## Thin one-shot SFX helper for greybox. Does not own gameplay logic.
## Extra combat cues load from assets/audio_v2. These are byte-copies of the
## art/audio_v2 sources kept under assets/ because the Web preset excludes
## `art/*` from the pck (T1 web audio export fix); art/audio_v2 remains the
## licensed source of record.

const EXTRA_CUES := [
	["hit", "res://assets/audio_v2/hit.wav"],
	["body_drop", "res://assets/audio_v2/body_drop.wav"],
	["alert_shout", "res://assets/audio_v2/alarm.wav"],
	["kill", "res://assets/audio_v2/kill.wav"],
	["tension", "res://assets/audio_v2/tension.wav"],
	["ambient_yard", "res://assets/audio_v2/ambient_yard.wav"],
]

var assets = null ## G2Assets
var _players: Array = [] ## AudioStreamPlayer pool
var _extra: Dictionary = {} ## cue → AudioStream (assets/audio_v2)
var enabled: bool = true
var _mg42_gate_s: float = 0.0
var _foot_gate_s: float = 0.0
var _tension_gate_s: float = 0.0
var _ambient_player: AudioStreamPlayer = null
var _ambient_cue: String = ""


func configure(g2_assets) -> void:
	assets = g2_assets
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	add_child(_ambient_player)
	_extra.clear()
	for pair in EXTRA_CUES:
		var stream := load(str(pair[1])) as AudioStream
		if stream:
			_extra[str(pair[0])] = stream


func play(cue: String, gain_db: float = 0.0) -> void:
	if not enabled:
		return
	var stream: AudioStream = null
	if assets != null:
		stream = assets.sfx_streams.get(cue, null)
	if stream == null:
		stream = _extra.get(cue, null)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = stream
	player.volume_db = gain_db
	player.play()


func play_alert(alert: String) -> void:
	match alert:
		"quiet":
			play("alert_quiet", -6.0)
		"suspicious":
			play("alert_suspicious", -4.0)
			play("alert_shout", -8.0)
		"area_alert":
			play("alert_area", -2.0)
			play("alert_shout", -4.0)
		"global_alert":
			play("alert_global", 0.0)
			play("alert_shout", -2.0)
		_:
			pass


func play_weapon(weapon_id: String) -> void:
	match weapon_id:
		"kar98k":
			play("weapon_kar98k", -3.0)
		"mp40":
			play("weapon_mp40", -3.0)
		"mg42":
			# Gate slightly so bursts read as cyclic fire without filling the pool.
			if _mg42_gate_s > 0.0:
				return
			_mg42_gate_s = 0.05
			play("weapon_mg42", -2.0)
		"grenade":
			play("weapon_grenade_detonate", -1.0)
		"mine":
			play("weapon_mine_detonate", 0.0)
		_:
			pass


func play_hit() -> void:
	play("hit", -6.0)


func play_body_drop() -> void:
	play("body_drop", -4.0)


func play_grenade_throw() -> void:
	play("weapon_grenade_throw", -4.0)


func play_foot(surface: String, gain_db: float) -> void:
	## Distance-attenuated march footsteps (PLAY-4).
	if _foot_gate_s > 0.0:
		return
	_foot_gate_s = 0.28
	var cue := "foot_dirt"
	match surface:
		"mud":
			cue = "foot_mud"
		"cobble":
			cue = "foot_cobble"
		"grass":
			cue = "foot_grass"
		_:
			cue = "foot_dirt"
	play(cue, gain_db)


func play_tension() -> void:
	## Heartbeat / tension sting when an enemy enters a friendly cone.
	if _tension_gate_s > 0.0:
		return
	_tension_gate_s = 2.4
	play("tension", -4.0)


func start_ambient(cue: String = "ambient_yard", gain_db: float = -14.0) -> void:
	if not enabled or _ambient_player == null:
		return
	var stream: AudioStream = _extra.get(cue, null)
	if stream == null and assets != null:
		stream = assets.sfx_streams.get(cue, null)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambient_player.stream = stream
	_ambient_player.volume_db = gain_db
	_ambient_cue = cue
	if not _ambient_player.playing:
		_ambient_player.play()


func stop_ambient() -> void:
	if _ambient_player != null and _ambient_player.playing:
		_ambient_player.stop()
	_ambient_cue = ""


func tick_gates(delta: float) -> void:
	if _mg42_gate_s > 0.0:
		_mg42_gate_s = maxf(0.0, _mg42_gate_s - delta)
	if _foot_gate_s > 0.0:
		_foot_gate_s = maxf(0.0, _foot_gate_s - delta)
	if _tension_gate_s > 0.0:
		_tension_gate_s = maxf(0.0, _tension_gate_s - delta)
