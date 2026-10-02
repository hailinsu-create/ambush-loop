class_name ReplayPlayer
extends RefCounted

## Read-only scrubber over BattleLog snapshots (blueprint §4.1).
## Does not re-simulate combat — interpolates recorded presentation frames.

var log: BattleLog = null
var scrub_tick: int = 0
var playing: bool = false
var legacy_ambiguous: bool = false


func bind(p_log: BattleLog) -> void:
	log = p_log
	scrub_tick = 0
	playing = false
	legacy_ambiguous = false
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
		scrub_tick = log.terminal_tick


func max_tick() -> int:
	if log == null or legacy_ambiguous:
		return 0
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
	if log == null or legacy_ambiguous or log.snapshots.is_empty():
		return {}
	var best: Dictionary = log.snapshots[0]
	for s in log.snapshots:
		if BattleLog.record_tick(s) <= tick:
			best = s
		else:
			break
	return best


func events_up_to(tick: int) -> Array:
	var out: Array = []
	if log == null or legacy_ambiguous:
		return out
	for ev in log.events:
		if BattleLog.record_tick(ev) <= tick:
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
