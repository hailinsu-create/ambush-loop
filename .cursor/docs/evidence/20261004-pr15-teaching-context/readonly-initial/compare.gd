extends SceneTree
func normalized(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key in value:
			if key == "attempt_id": out[key] = "BOUND_ATTEMPT"
			elif key == "event_id": out[key] = "BOUND_ATTEMPT:" + str(value[key]).split(":",true,1)[1]
			else: out[key] = normalized(value[key])
		return out
	if value is Array:
		return value.map(normalized)
	return value
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var before: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(args[0]))
	var after: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(args[1]))
	var result := {"read_only":true,"before_sha256":FileAccess.get_sha256(args[0]),"after_sha256":FileAccess.get_sha256(args[1]),"normalization":"Only independent attempt_id and its event_id prefix; no time/state/payload normalization","comparisons":{},"failures":0}
	for key in ["events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
		var same: bool = normalized(before[key]) == normalized(after[key])
		result.comparisons[key] = same
		if not same: result.failures += 1
	result.events = after.events.size()
	print(JSON.stringify(result))
	quit(0 if result.failures == 0 else 1)
