extends RefCounted

## Test-only hashes. Call outside every timed segment, never from _sample().
static func verify(path: String, expected_consumer: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"verified":false,"reason":"missing_receipt"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("format",0)) != 1:
		return {"verified":false,"reason":"unsupported_receipt"}
	var receipt: Dictionary = parsed
	if expected_consumer.length()!=40 or not expected_consumer.is_valid_hex_number() or receipt.get("consumer_commit") != expected_consumer:
		return {"verified":false,"reason":"consumer_commit_mismatch"}
	if receipt.get("tracked_project_clean") != true or receipt.get("source_root") != ProjectSettings.globalize_path("res://").trim_suffix("/"):
		return {"verified":false,"reason":"source_root_or_clean_receipt_mismatch"}
	var engine: Variant = receipt.get("engine")
	if not engine is Dictionary or engine.get("path") != OS.get_executable_path() or not _matches(engine,OS.get_executable_path()):
		return {"verified":false,"reason":"engine_bytes_mismatch"}
	var files: Variant = receipt.get("source_files")
	if not files is Array or files.is_empty() or files.size()>4096:
		return {"verified":false,"reason":"missing_or_unbounded_source_files"}
	var seen := {}
	for item: Variant in files:
		if not item is Dictionary or not item.get("path") is String:
			return {"verified":false,"reason":"bad_source_entry"}
		var relative: String = item.path
		if relative.is_absolute_path() or ":" in relative or "\\" in relative or ".." in relative.split("/") or relative in seen:
			return {"verified":false,"reason":"invalid_or_duplicate_source_path"}
		seen[relative]=true
		if not _matches(item,"res://"+relative):
			return {"verified":false,"reason":"source_bytes_mismatch","path":relative}
	var records: Variant = receipt.get("producer_records")
	if not records is Array or records.size()>16:
		return {"verified":false,"reason":"bad_record_manifest"}
	for record: Variant in records:
		if not record is Dictionary or not record.get("path") is String or not record.get("producer_commit") is String or record.producer_commit.length()!=40 or not _matches(record,record.path):
			return {"verified":false,"reason":"record_bytes_or_attribution_mismatch"}
	return {"verified":true,"receipt_sha256":FileAccess.get_sha256(path),"consumer_commit":expected_consumer,
		"consumer_game_tree":receipt.get("consumer_game_tree",""),"source_files_verified":files.size(),
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
