class_name ReplayPlayer
extends RefCounted

## Read-only scrubber over BattleLog snapshots (blueprint §4.1).
## Does not re-simulate combat — interpolates recorded presentation frames.

var log: BattleLog = null
var scrub_tick: int = 0
var playing: bool = false
var legacy_ambiguous: bool = false
var continuous_playback: bool = false
var playback_unsupported: bool = false


func bind(p_log: BattleLog) -> void:
	log = p_log
	scrub_tick = 0
	playing = false
	legacy_ambiguous = false
	continuous_playback = log != null and log.playback_schema == 1 and not log.playback_snapshots.is_empty()
	playback_unsupported = log != null and log.playback_schema not in [0, 1]
	if continuous_playback:
		for stream_index in 2:
			var stream: Array = log.playback_snapshots if stream_index == 0 else log.events
			var previous := -1
			var index := 0
			for record in stream:
				var raw: Variant = record.get("playback_tick")
				if int(record.get("playback_schema", 0)) != 1 or not raw is int or int(raw) < previous or int(raw) < 0 or str(record.get("attempt_id", "")) != log.attempt_id:
					continuous_playback = false
					playback_unsupported = true
					break
				if stream_index == 0 and int(record.get("frame_seq", -1)) != index:
					continuous_playback = false
					playback_unsupported = true
					break
				previous = int(raw)
				index += 1
	# An unversioned recording with a reset clock has no trustworthy mapping
	# between its snapshot segments and events. Keep the source, refuse mixed scrub.
	if log != null:
		# Either stream can reveal a missing wave boundary. A sparse snapshot
		# stream does not make a regressing event stream safe to mix.
		for records in [log.snapshots, log.events]:
			var previous := -1
			for record in records:
				var t := BattleLog.record_tick(record)
				if not record.has("timeline_tick") and t < previous:
					legacy_ambiguous = true
				previous = t
	if log != null and not legacy_ambiguous and log.terminal_tick >= 0:
		scrub_tick = max_tick()


func playback_time(record: Dictionary) -> int:
	return int(record.playback_tick) if continuous_playback else BattleLog.record_tick(record)


func _snapshots() -> Array:
	return log.playback_snapshots if continuous_playback else log.snapshots


func max_tick() -> int:
	if log == null or legacy_ambiguous:
		return 0
	if continuous_playback:
		return log.playback_terminal_tick if log.playback_terminal_tick >= 0 else playback_time(_snapshots().back())
	if log.terminal_tick >= 0:
		return log.terminal_tick
	if not log.snapshots.is_empty():
		return BattleLog.record_tick(log.snapshots[log.snapshots.size() - 1])
	return 0


func set_tick(t: int) -> void:
	scrub_tick = clampi(t, 0, max_tick())


func seek_ratio(r: float) -> void:
	set_tick(int(round(clampf(r, 0.0, 1.0) * float(max_tick()))))


func snapshot_at_or_before(tick: int) -> Dictionary:
	if log == null or legacy_ambiguous or _snapshots().is_empty():
		return {}
	var best: Dictionary = _snapshots()[0]
	for s in _snapshots():
		if playback_time(s) <= tick:
			best = s
		else:
			break
	return best


func events_up_to(tick: int) -> Array:
	var out: Array = []
	if log == null or legacy_ambiguous:
		return out
	for ev in log.events:
		if playback_time(ev) <= tick:
			out.append(ev)
	return out


func summary_at_scrub(max_count: int = 10) -> PackedStringArray:
	if log == null:
		return PackedStringArray()
	var lines := PackedStringArray()
	var evs := events_up_to(scrub_tick)
	var start := maxi(evs.size() - max_count, 0)
	for i in range(start, evs.size()):
		lines.append(log.format_event(evs[i]))
	return lines
