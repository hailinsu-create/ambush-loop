extends RefCounted

## Test-only hashes. Call outside every timed segment, never from _sample().
static func verify(path: String, expected_consumer: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"verified":false,"reason":"missing_receipt"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("format",0)) != 2:
		return {"verified":false,"reason":"unsupported_receipt"}
	var receipt: Dictionary = parsed
	if expected_consumer.length()!=40 or not expected_consumer.is_valid_hex_number() or receipt.get("consumer_commit") != expected_consumer:
		return {"verified":false,"reason":"consumer_commit_mismatch"}
	var expected_tree := OS.get_environment("AMBUSH_A3_GAME_TREE")
	if expected_tree.length()!=40 or not expected_tree.is_valid_hex_number() or receipt.get("consumer_game_tree")!=expected_tree:
		return {"verified":false,"reason":"expected_game_tree_mismatch"}
	if receipt.get("tracked_project_clean") != true or receipt.get("source_root") != ProjectSettings.globalize_path("res://").trim_suffix("/"):
		return {"verified":false,"reason":"source_root_or_clean_receipt_mismatch"}
	var engine: Variant = receipt.get("engine")
	if not engine is Dictionary or engine.get("path") != OS.get_executable_path() or not _matches(engine,OS.get_executable_path()):
		return {"verified":false,"reason":"engine_bytes_mismatch"}
	var files: Variant = receipt.get("source_files")
	if not files is Array or files.is_empty() or files.size()>4096:
		return {"verified":false,"reason":"missing_or_unbounded_source_files"}
	var seen := {}
	var tree := {"files":{},"directories":{}}
	for item: Variant in files:
		if not item is Dictionary or not item.get("path") is String:
			return {"verified":false,"reason":"bad_source_entry"}
		var relative: String = item.path
		if relative.is_absolute_path() or ":" in relative or "\\" in relative or ".." in relative.split("/") or relative in seen:
			return {"verified":false,"reason":"invalid_or_duplicate_source_path"}
		seen[relative]=true
		if not _matches(item,"res://"+relative):
			return {"verified":false,"reason":"source_bytes_mismatch","path":relative}
		if item.get("mode") not in ["100644","100755"] or not _tree_insert(tree,relative,item.mode,_git_blob_sha1("res://"+relative)):
			return {"verified":false,"reason":"invalid_source_tree_entry"}
	if _git_tree_sha1(tree)!=expected_tree:
		return {"verified":false,"reason":"source_tree_mismatch"}
	var imported: Variant = receipt.get("imported_cache")
	if not imported is Array or imported.size()>4096:
		return {"verified":false,"reason":"bad_imported_cache_manifest"}
	var actual_imported := PackedStringArray()
	if not imported.is_empty():
		_list_imported(ProjectSettings.globalize_path("res://.godot/imported"),actual_imported)
		var declared_imported := {}
		for entry: Variant in imported:
			if not entry is Dictionary or not entry.get("path") is String or not entry.path in actual_imported or entry.path in declared_imported or not _matches(entry,entry.path):
				return {"verified":false,"reason":"imported_cache_bytes_mismatch"}
			declared_imported[entry.path]=true
		if declared_imported.size()!=actual_imported.size():
			return {"verified":false,"reason":"imported_cache_inventory_incomplete"}
	var records: Variant = receipt.get("producer_records")
	if not records is Array or records.size()>16:
		return {"verified":false,"reason":"bad_record_manifest"}
	for record: Variant in records:
		if not record is Dictionary or not record.get("path") is String or not record.get("producer_commit") is String or record.producer_commit.length()!=40 or not _matches(record,record.path):
			return {"verified":false,"reason":"record_bytes_or_attribution_mismatch"}
	return {"verified":true,"receipt_sha256":FileAccess.get_sha256(path),"consumer_commit":expected_consumer,
		"consumer_game_tree":receipt.get("consumer_game_tree",""),"source_files_verified":files.size(),
		"complete_source_tree_verified":true,"imported_cache_files_verified":imported.size(),
		"loaded_resource_scope":"complete existing warm imported inventory" if not imported.is_empty() else "imported resources excluded; formal loaded-resource proof incomplete",
		"engine":engine,"producer_records":records,
		"cache_scope":receipt.get("cache_scope",""),"record_attribution_scope":receipt.get("record_attribution_scope","")}


static func _matches(entry: Dictionary, path: String) -> bool:
	var expected: Variant = entry.get("sha256")
	if not expected is String or expected.length()!=64 or not expected.is_valid_hex_number() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return false
	var size := file.get_length()
	file.close()
	return size == int(entry.get("bytes",-1)) and FileAccess.get_sha256(path)==expected


static func _git_blob_sha1(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA1)
	context.update(_nul_terminated("blob "+str(file.get_length())))
	while file.get_position()<file.get_length():
		context.update(file.get_buffer(mini(65536,file.get_length()-file.get_position())))
	file.close()
	return context.finish().hex_encode()


static func _tree_insert(tree: Dictionary, path: String, mode: String, blob: String) -> bool:
	var parts := path.split("/")
	var node: Dictionary = tree
	for i: int in parts.size()-1:
		var part: String=parts[i]
		if part in node.files:return false
		if not part in node.directories:node.directories[part]={"files":{},"directories":{}}
		node=node.directories[part]
	var leaf: String=parts[-1]
	if leaf in node.files or leaf in node.directories:return false
	node.files[leaf]={"mode":mode,"blob":blob}
	return true


static func _git_tree_sha1(tree: Dictionary) -> String:
	var names: Array=[]
	for name: String in tree.files:names.append(name)
	for name: String in tree.directories:names.append(name+"/")
	names.sort()
	var body := PackedByteArray()
	for name: String in names:
		if name.ends_with("/"):
			var plain := name.trim_suffix("/")
			body.append_array(_nul_terminated("40000 "+plain))
			body.append_array(_git_tree_sha1(tree.directories[plain]).hex_decode())
		else:
			body.append_array(_nul_terminated(str(tree.files[name].mode)+" "+name))
			body.append_array(str(tree.files[name].blob).hex_decode())
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA1)
	context.update(_nul_terminated("tree "+str(body.size())))
	context.update(body)
	return context.finish().hex_encode()


static func _nul_terminated(text: String) -> PackedByteArray:
	var bytes := text.to_utf8_buffer()
	bytes.append(0) # Git tree/blob separator is a byte, not a NUL-containing Godot String.
	return bytes


static func _list_imported(path: String, result: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory==null:return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if directory.current_is_dir():_list_imported(path+"/"+name,result)
		else:result.append(path+"/"+name)
		name=directory.get_next()
	directory.list_dir_end()
