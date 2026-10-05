from pathlib import Path
import shutil, subprocess, hashlib, json, difflib
R=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
S=Path('/workspace/pr15-hud-segment-stage-1ec-20261005')
B=Path('/workspace/pr15-yard-consumer-stage-1ec-20261005')
SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e'
assert not S.exists()
shutil.copytree(B,S)
main=S/'scripts/main.gd'; original=main.read_text()
needle='func _apply_replay_scrub() -> void:\n'
start=original.index(needle); end=original.index('\n\nfunc _update_replay_status()',start)
replacement='''func _apply_replay_scrub() -> void:
	if phase != Phase.REPLAY:
		return
	var qa = get_node("/root/EventLogObserver")
	if qa.active: qa.root_calls += 1
	var measured: bool = qa.active and qa.measure_enabled
	var q0: int = Time.get_ticks_usec() if measured else 0
	var snap: Dictionary = replay.snapshot_at_or_before(replay.scrub_tick)
	if scrub_slider and replay.max_tick() > 0:
		scrub_slider.set_value_no_signal(float(replay.scrub_tick) / float(replay.max_tick()))
	var q1: int = Time.get_ticks_usec() if measured else 0
	_paint_replay_snapshot(snap)
	var q2: int = Time.get_ticks_usec() if measured else 0
	var clock_label := "播放" if replay.continuous_playback else "复盘"
	var qa_events: Array = replay.events_up_to(replay.scrub_tick)
	var qa_title: String = "%s t=%.1fs · 点击定位" % [clock_label, float(replay.scrub_tick) / 60.0]
	var q3: int = Time.get_ticks_usec() if measured else 0
	_fill_event_list(qa_events, 12, qa_title)
	var q4: int = Time.get_ticks_usec() if measured else 0
	_update_replay_status()
	var q5: int = Time.get_ticks_usec() if measured else 0
	_refresh_replay_transport()
	var q6: int = Time.get_ticks_usec() if measured else 0
	_update_hud()
	var q7: int = Time.get_ticks_usec() if measured else 0
	if measured: qa.record_root(q7-q0,q1-q0,q2-q1,q3-q2,q4-q3,q5-q4,q6-q5,q7-q6)
'''
main.write_text(original[:start]+replacement+original[end:])
p=S/'scripts/presentation/presenter_3d.gd'; origp=p.read_text()
start=origp.index('func refresh() -> void:'); end=origp.index('\n\nfunc _layout_camera_controls()',start)
fn=origp[start:end]
anchor='\tif host.level == null:\n\t\treturn\n'
assert fn.count(anchor)==1
fn=fn.replace(anchor,anchor+'\tvar qa = get_node("/root/EventLogObserver")\n\tif qa.active: qa.presenter_calls += 1\n\tvar measured: bool = qa.active and qa.measure_enabled\n\tvar qa_start: int = Time.get_ticks_usec() if measured else 0\n')
fn+='\n\tif measured: qa.presenter_usec += Time.get_ticks_usec()-qa_start\n'
p.write_text(origp[:start]+fn+origp[end:])
obs=(R/'event_log_observer.gd').read_text()
(S/'qa/event_log_observer.gd').write_text(obs)
diff=''
for file in ['scripts/main.gd','scripts/presentation/presenter_3d.gd','qa/event_log_observer.gd']:
 old=(B/file).read_text(); new=(S/file).read_text()
 diff+=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='yard-QA/'+file,tofile='HUD-QA/'+file))
(R/'instrumentation.diff').write_text(diff)
tracked=subprocess.check_output(['git','ls-tree','-rz',SOURCE,'ambush_loop'],cwd='/workspace/ambush-pr15').split(b'\0')
changes=[];exact=0
for entry in tracked:
 if not entry:continue
 meta,path=entry.split(b'\t',1);file=path.decode().removeprefix('ambush_loop/'); blob=meta.split()[2].decode(); target=S/file
 if not target.exists():changes.append({'path':file,'scope':'omitted source-only Blender' if file=='ArtSource/v2/yard_kit.blend' else 'MISSING'});continue
 gitblob=hashlib.sha1(b'blob '+str(target.stat().st_size).encode()+b'\0'+target.read_bytes()).hexdigest()
 if gitblob==blob:exact+=1
 else:changes.append({'path':file,'git_blob':blob,'stage_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'scope':'QA timer' if file in ['scripts/main.gd','scripts/presentation/presenter_3d.gd'] else 'inherited declared QA project/export or cached import sidecar'})
assert all(x['scope']!='MISSING' for x in changes)
proof={'source':SOURCE,'game_tree':'1e8af45ee23098f763acc139b56f8f7e0f41665a','stage':str(S),'basis':str(B),'tracked_exact':exact,'tracked_deltas':changes,'instrumentation_sha256':hashlib.sha256(diff.encode()).hexdigest(),'scope':'external QA only; timer stamps preserve call sequence/args; lookup+branch and fixed row sampler exist in OFF; original observer unbounded per-frame dict rows removed; no rule/assets/manifest/loader edits'}
(R/'stage-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps({'stage':str(S),'tracked_exact':exact,'declared_deltas':len(changes),'patch_sha256':proof['instrumentation_sha256']}))
