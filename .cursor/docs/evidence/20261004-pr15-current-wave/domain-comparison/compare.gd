extends SceneTree
func _init() -> void:
 var paths := ["/tmp/pr15-wave-negative-reference.bin", "/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/current-wave-reference-radio-record.bin"]
 var records := []
 var hashes := []
 for path in paths:
  hashes.append(FileAccess.get_sha256(path))
  records.append(bytes_to_var(FileAccess.get_file_as_bytes(path)))
 var normalized := []
 for record in records:
  var events: Array = record.events.duplicate(true)
  for event in events:
   event.erase("attempt_id")
   event.erase("event_id")
  normalized.append(events)
 var equal: bool = normalized[0] == normalized[1]
 var terminal: bool = records[0].terminal_tick == records[1].terminal_tick and records[0].terminal_reason == records[1].terminal_reason
 var immutable: bool = hashes[0] == FileAccess.get_sha256(paths[0]) and hashes[1] == FileAccess.get_sha256(paths[1])
 var result := {"negative_source":"a0910379476ea4fb1ff3d4519451c6c16940ac35","fixed_source":"480c2c4c14c72dc254d6d513f0985ac5505a99a4","equal_event_fields_excluding_attempt_id_and_event_id":equal,"same_terminal_tick_reason":terminal,"immutable_source_bytes":immutable,"hashes":hashes,"attempts":[records[0].attempt_id,records[1].attempt_id],"events":[records[0].events.size(),records[1].events.size()],"terminal_ticks":[records[0].terminal_tick,records[1].terminal_tick],"snapshot_counts":[records[0].snapshots.size(),records[1].snapshots.size()],"scope":"Read-only comparison of two separate reference-domain recordings. Only per-run attempt/event identities excluded from equality; seq/wave/local/global/playback time, actor/target/position/type/payload all retained. Sources are never rebound, mutated or merged. Not a normal-input or rendered playback check."}
 var file := FileAccess.open("/tmp/pr15-wave-domain-comparison.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "))
 print("READONLY_WAVE_DOMAIN_EQUAL=",equal," TERMINAL=",terminal," IMMUTABLE=",immutable)
 if not equal:
  for i in mini(normalized[0].size(),normalized[1].size()):
   if normalized[0][i] != normalized[1][i]:print("FIRST_DIFFERENCE ",i," ",normalized[0][i]," ",normalized[1][i]);break
 quit(0 if equal and terminal and immutable else 1)
