extends SceneTree
func _init() -> void:
 var path := "/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/native-player-depot-record.bin"
 var r: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
 var event: Dictionary = r.events[38]
 print("SOURCE_SHA256=",FileAccess.get_sha256(path))
 print("ACTUAL_EVENT=",event)
 var ticks := []
 for snapshot in r.playback_snapshots:
  if int(snapshot.get("wave_id",0)) != 1:continue
  if abs(int(snapshot.get("playback_tick",0))-int(event.playback_tick)) > 6:continue
  for op in snapshot.data.get("ops",[]):
   if int(op.id)==1: print("NEARBY_FRAME playback=",snapshot.playback_tick," local=",snapshot.tick," op=",op)
 quit(0)
