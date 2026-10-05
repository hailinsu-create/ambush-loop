from pathlib import Path
R=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
base=Path('/tmp/pr15-web-controls/yard-consumer-1ec-20261005/event_log_observer.gd').read_text()
base=base.replace('var replay_rows: Array = []','var replay_rows: Array = [] # deliberately empty: no unbounded per-frame dict sampler')
base=base.replace('\tRenderingServer.frame_post_draw.connect(_presented)','\tsamples.resize(2048*WIDTH)\n\tposts.resize(2048*3)\n\tRenderingServer.frame_post_draw.connect(_presented)')
base=base.replace('func _presented() -> void:\n\tpresents += 1','''func _presented() -> void:
	presents += 1
	var now: int = Time.get_ticks_usec()
	if active and now >= collect_start and now < collect_end:
		if post_count >= 2048: overflow = true; active = false; done = true; return
		var k: int = post_count*3
		posts[k] = Engine.get_process_frames()
		posts[k+1] = now
		posts[k+2] = now-last_post if last_post > 0 else 0
		post_count += 1
	last_post = now''')
start=base.index('func _process(delta: float) -> void:')
base=base[:start]+'''func _process(delta: float) -> void:
	var start: int = Time.get_ticks_usec()
	var m = get_tree().current_scene
	if active and start >= collect_end: active = false; done = true
	if active and start >= collect_start and m != null and "phase" in m:
		if row_count >= 2048: overflow = true; active = false; done = true
		else:
			var k: int = row_count*WIDTH
			samples[k] = Engine.get_process_frames()
			samples[k+1] = start
			samples[k+2] = m.replay.scrub_tick
			samples[k+3] = int(m.presentation_3d.frame.get("playback_tick",-1))
			samples[k+4] = 1 if m.replay.playing else 0
			samples[k+5] = int(delta*1000000)
			samples[k+6] = root_calls
			samples[k+7] = presenter_calls
			for i in 8: samples[k+8+i] = root_values[i]
			samples[k+16] = presenter_usec
			samples[k+17] = m._event_list_items.size()
			samples[k+18] = 1 if m.event_log != null and m.event_log.is_visible_in_tree() else 0
			samples[k+19] = Time.get_ticks_usec()-start
			row_count += 1
	root_calls = 0
	presenter_calls = 0
	presenter_usec = 0
	root_values.fill(0)
'''
base=base.replace('\t\t"state": value = _state()','\t\t"meter_begin": value = _meter_begin(r)\n\t\t"meter_status": value = {"done":done,"active":active,"rows":row_count,"overflow":overflow}\n\t\t"meter_result": value = _meter_result()\n\t\t"canonical": value = _canonical()\n\t\t"state": value = _state()')
base+='''
const WIDTH := 20
const COLS = ["engine_frame","observer_us","tick","view_tick","playing","delta_us","root_calls","presenter_calls","root_us","select_slider_us","paint_us","event_select_title_us","list_us","status_us","transport_us","hud_us","presenter_us","list_rows","list_visible","sampler_us"]
var active := false
var measure_enabled := false
var done := false
var overflow := false
var collect_start: int = 0
var collect_end: int = 0
var last_post: int = 0
var row_count := 0
var post_count := 0
var root_calls := 0
var presenter_calls := 0
var presenter_usec := 0
var root_values := PackedInt64Array([0,0,0,0,0,0,0,0])
var samples := PackedInt64Array()
var posts := PackedInt64Array()
var meter_label := ""

func record_root(a: int,b: int,c: int,d: int,e: int,f: int,g: int,h: int) -> void:
	root_values[0] += a
	root_values[1] += b
	root_values[2] += c
	root_values[3] += d
	root_values[4] += e
	root_values[5] += f
	root_values[6] += g
	root_values[7] += h

func _meter_begin(r: Dictionary) -> Dictionary:
	if active: return {"error":"measurement already active"}
	var m = get_tree().current_scene
	if m == null or m.phase != m.Phase.REPLAY: return {"error":"REPLAY required"}
	var collect_s: float = float(r.get("seconds",20.0))
	var warm_s: float = float(r.get("warm",2.0))
	if collect_s <= 0 or collect_s > 20 or warm_s < 0 or warm_s > 2: return {"error":"bounded interval rejected"}
	measure_enabled = bool(r.get("enabled",false))
	meter_label = str(r.get("label",""))
	row_count = 0; post_count = 0; root_calls = 0; presenter_calls = 0; presenter_usec = 0
	root_values.fill(0); samples.fill(0); posts.fill(0)
	last_post = 0; done = false; overflow = false
	collect_start = Time.get_ticks_usec()+int(warm_s*1000000)
	collect_end = collect_start+int(collect_s*1000000)
	active = true
	return {"label":meter_label,"enabled":measure_enabled,"collect_start_us":collect_start,"collect_end_us":collect_end,"warm_s":warm_s,"collect_s":collect_s,"capacity":2048}

func _meter_result() -> Dictionary:
	if active: return {"error":"cannot flush active measurement"}
	var out: Array = []
	for i in row_count:
		var row: Array = []
		for j in WIDTH: row.append(samples[i*WIDTH+j])
		out.append(row)
	var draw: Array = []
	for i in post_count: draw.append([posts[i*3],posts[i*3+1],posts[i*3+2]])
	return {"schema":1,"label":meter_label,"enabled":measure_enabled,"done":done,"overflow":overflow,"columns":COLS,"rows":out,"post_columns":["engine_frame","postdraw_us","interval_us"],"posts":draw,"collect_start_us":collect_start,"collect_end_us":collect_end,"capacity":2048,"scope":"fixed rows, no per-frame output/RPC; elapsed inclusive, software WebGL; OFF retains branches/lookup/counters/sampler; nested tags cannot be added"}

func _canonical() -> Dictionary:
	var m = get_tree().current_scene
	if m == null or m.phase != m.Phase.REPLAY: return {"error":"canonical requires REPLAY"}
	var v = m.presentation_3d
	var snap: Dictionary = m.replay.snapshot_at_or_before(m.replay.scrub_tick)
	var actors: Array = []
	for group: String in ["ops","enemies","sentries"]:
		for item: Dictionary in v.frame.get(group,[]):
			var proxy = v.actors.get(group+":"+str(item.id))
			var body = proxy.get_node_or_null("Body")
			var bones: Array = []
			for i in body.skeleton.get_bone_count(): bones.append(body.skeleton.get_bone_pose(i))
			actors.append({"group":group,"id":item.id,"weapon":item.weapon,"root":_plain(proxy.position),"bone_count":bones.size(),"bone_sha256":_hash(var_to_bytes(bones)),"hand_socket":_plain(body.bone_socket("weapon_hand"))})
	return {"tick":m.replay.scrub_tick,"attempt":m.battle_log.attempt_id,"wave_id":snap.wave_id,"frame_seq":snap.frame_seq,"recorded_phase":snap.data.phase,"snapshot_sha256":_hash(var_to_bytes(snap)),"actors":actors,"checks":_frame_checks(m),"view_size":v.rig.view_size,"yaw_deg":v.rig.yaw_deg,"pitch_deg":v.rig.pitch_deg,"event_count":m.replay.events_up_to(m.replay.scrub_tick).size(),"list_rows":m._event_list_items.size(),"list_visible":m.event_log.is_visible_in_tree()}
'''
(R/'event_log_observer.gd').write_text(base)
