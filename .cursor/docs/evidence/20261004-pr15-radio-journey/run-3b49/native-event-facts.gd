extends SceneTree
const Guard := preload("/workspace/ambush-pr15/ambush_loop/scripts/test_storage_guard.gd")
func _init() -> void:
 if not Guard.check(): quit(2)
 else: call_deferred("inspect")
func inspect() -> void:
 var path := OS.get_environment("AMBUSH_NATIVE_RECORD")
 var hash_before := FileAccess.get_sha256(path)
 var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
 var actual := {"scope":"Read-only original native event facts, not simulation or replay rendering.","raw_sha256":hash_before,"attempt":raw.attempt_id,"spawn":raw.events.filter(func(e: Dictionary) -> bool: return e.type == "spawn"),"fire":raw.events.filter(func(e: Dictionary) -> bool: return e.type == "fire"),"kill":raw.events.filter(func(e: Dictionary) -> bool: return e.type == "kill"),"mine":raw.events.filter(func(e: Dictionary) -> bool: return e.type == "mine"),"trip":raw.events.filter(func(e: Dictionary) -> bool: return e.type == "trip")}
 var unchanged := FileAccess.get_sha256(path) == hash_before
 actual["source_bytes_unchanged"] = unchanged
 var file := FileAccess.open(OS.get_environment("AMBUSH_RECORD_FACTS_REPORT"),FileAccess.WRITE)
 file.store_string(JSON.stringify(actual,"  "))
 file.close()
 print("ORIGINAL_NATIVE_EVENT_FACTS unchanged=",unchanged)
 quit(0 if unchanged else 1)
