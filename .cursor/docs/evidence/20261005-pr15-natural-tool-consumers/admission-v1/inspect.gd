extends SceneTree
const Guard=preload("res://scripts/test_storage_guard.gd")
var result:Array=[]
func _init()->void:
	if not Guard.check():quit(91);return
	call_deferred("_run")
func plain(v:Variant)->Variant:
	if v is Vector2:return [v.x,v.y]
	if v is Dictionary:
		var out:Dictionary={}
		for k in v:out[str(k)]=plain(v[k])
		return out
	if v is Array or v is PackedStringArray or v is PackedInt32Array:
		var out:Array=[]
		for item in v:out.append(plain(item))
		return out
	return v
func _run()->void:
	for spec in [["warehouse-mine","mine",39],["railcut-repack","repack",28]]:
		var path:String="/tmp/pr15-natural-tool-originals-20261005/"+spec[0]+".bin"
		var raw:Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var selected:Array=[]
		for ev in raw.events:
			if ev.type==spec[1] and ev.seq==spec[2]:selected.append(ev)
		assert(selected.size()==1)
		var event:Dictionary=selected.front()
		var tick:int=event.playback_tick
		var before:Dictionary={};var after:Dictionary={};var rows:Array=[]
		for snap in raw.playback_snapshots:
			if snap.playback_tick<tick:before=snap
			elif after.is_empty():after=snap
			if abs(snap.playback_tick-tick)<=120:
				rows.append({"playback_tick":snap.playback_tick,"local_tick":snap.tick,"wave":snap.wave_id,"frame_seq":snap.frame_seq,"phase":snap.data.phase,"pose_clock_s":snap.data.get("pose_clock_s"),"event_pose_clock_s":snap.data.get("event_pose_clock_s"),"tool_fx":snap.data.get("tool_fx",[]),"ops":snap.data.ops,"enemies":snap.data.enemies})
		var events:Array=[]
		for ev in raw.events:
			if abs(ev.seq-int(event.seq))<=3:events.append(ev)
		result.append({"label":spec[0],"bytes":FileAccess.get_file_as_bytes(path).size(),"sha256":FileAccess.get_sha256(path),"attempt":raw.attempt_id,"playback_schema":raw.playback_schema,"terminal":raw.playback_terminal_tick,"target_event":event,"adjacent_events":events,"nearest_before":before,"nearest_after":after,"near_frames":rows})
	var file:=FileAccess.open("/tmp/pr15-natural-tool-originals-20261005/admission.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(plain(result)));file.close()
	for item in result:print("NATURAL_TOOL_ADMISSION label=",item.label," event=",item.target_event.event_id," playback_tick=",item.target_event.playback_tick," near_frames=",item.near_frames.size())
	quit(0)
