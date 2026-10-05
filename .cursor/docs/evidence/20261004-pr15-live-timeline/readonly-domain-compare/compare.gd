extends SceneTree
func _init() -> void:
 var paths := ["/tmp/pr15-live-domain-compare/negative.bin", "/tmp/pr15-live-domain-compare/fixed.bin"]
 var records := []
 var hashes := []
 var normalized := []
 for path in paths:
  hashes.append(FileAccess.get_sha256(path))
  var record: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
  records.append(record)
  var events: Array = record.events.duplicate(true)
  for event in events:
   event.erase("attempt_id")
   event.erase("event_id")
  normalized.append(events)
 var equal: bool = normalized[0] == normalized[1]
 var terminal: bool = records[0].terminal_tick == -1 and records[1].terminal_tick == -1 and records[0].terminal_reason == records[1].terminal_reason
 var immutable: bool = hashes[0] == FileAccess.get_sha256(paths[0]) and hashes[1] == FileAccess.get_sha256(paths[1])
 var result := {"negative_source":"ee151102dd2af5ee7f4dc235a8a3bfde4685eac1","fixed_source":"f0208ebd25481c43e7c7ae5242d7e03c010c1cc5","equal_event_fields_excluding_attempt_id_and_event_id":equal,"both_nonterminal_last_sweep":terminal,"immutable_source_bytes":immutable,"hashes":hashes,"attempts":[records[0].attempt_id,records[1].attempt_id],"events":[records[0].events.size(),records[1].events.size()],"terminal_ticks":[records[0].terminal_tick,records[1].terminal_tick],"scope":"Read-only separate H reference domain recordings. All event fields retained except distinct per-run attempt/event identifiers; local/global/playback time/seq/wave/actors/targets/position/payload equal. Both last SWEEP/nonterminal, no WON or full recording acceptance."}
 var file := FileAccess.open("/tmp/pr15-live-domain-compare/comparison.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "))
 print("READONLY_LIVE_DOMAIN_EQUAL=",equal," NONTERMINAL=",terminal," IMMUTABLE=",immutable)
 quit(0 if equal and terminal and immutable else 1)
