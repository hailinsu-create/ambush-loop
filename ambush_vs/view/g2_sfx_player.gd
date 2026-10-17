extends Node
class_name G2SfxPlayer

## Thin one-shot SFX helper for greybox. Does not own gameplay logic.

var assets = null ## G2Assets
var _players: Array = [] ## AudioStreamPlayer pool
var enabled: bool = true


func configure(g2_assets) -> void:
	assets = g2_assets
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play(cue: String, gain_db: float = 0.0) -> void:
	if not enabled or assets == null:
		return
	var stream: AudioStream = assets.sfx_streams.get(cue, null)
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
		"area_alert":
			play("alert_area", -2.0)
		"global_alert":
			play("alert_global", 0.0)
		_:
			pass


func play_weapon(weapon_id: String) -> void:
	match weapon_id:
		"kar98k":
			play("weapon_kar98k", -3.0)
		"mp40":
			play("weapon_mp40", -3.0)
		"mg42":
			play("weapon_mg42", -2.0)
		"grenade":
			play("weapon_grenade_detonate", -1.0)
		"mine":
			play("weapon_mine_detonate", 0.0)
		_:
			pass
