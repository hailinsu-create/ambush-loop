extends SceneTree
var differences := []
var identities := {}
var identity_pattern := RegEx.create_from_string("^[0-9a-f]{32}(?=:|$)")
func diff(a: Variant,b: Variant,path: String) -> void:
	if a == b or differences.size() >= 30: return
	if a is Dictionary and b is Dictionary:
		for key in a:
			if b.has(key): diff(a[key],b[key],path+"/"+str(key))
			else: differences.append({"path":path+"/"+str(key),"missing_after":true})
	elif a is Array and b is Array and a.size()==b.size():
		for i in a.size(): diff(a[i],b[i],path+"/"+str(i))
	else: differences.append({"path":path,"before":str(a),"after":str(b)})
func normalized(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key in value:
			out[key] = normalized(value[key])
		return out
	if value is Array:
		return value.map(normalized)
	if value is String and identity_pattern.search(value) != null:
		var token: String = value.substr(0,32)
		if not identities.has(token): identities[token] = "IDENTITY"+str(identities.size())
		return str(identities[token])+value.substr(32)
	return value
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var before: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(args[0]))
	var after: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(args[1]))
	var normalized_before: Dictionary = normalized(before)
	var before_ids := identities.size()
	identities.clear()
	var normalized_after: Dictionary = normalized(after)
	var result := {"read_only":true,"before_sha256":FileAccess.get_sha256(args[0]),"after_sha256":FileAccess.get_sha256(args[1]),"normalization":"Bijective traversal mapping of independent32hex attempt/utility scope tokens and derived identity prefixes only; identity equality/distinctness/suffix retained. No time/state/payload value normalization.","identity_counts":[before_ids,identities.size()],"comparisons":{},"failures":0}
	for key in ["events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
		var same: bool = normalized_before[key] == normalized_after[key]
		result.comparisons[key] = same
		if not same: result.failures += 1
	result.events = after.events.size()
	diff(normalized_before.snapshots,normalized_after.snapshots,"snapshots")
	diff(normalized_before.playback_snapshots,normalized_after.playback_snapshots,"playback_snapshots")
	result.differences = differences
	print(JSON.stringify(result))
	quit(0 if result.failures == 0 else 1)
