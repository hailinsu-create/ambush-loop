from pathlib import Path
import shutil,json,hashlib,difflib
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
OLD=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
BASE=Path('/workspace/pr15-hud-segment-stage-1ec-20261005')
STAGE=Path('/workspace/pr15-hud-subsegment-stage-1ec-20261005')
assert not STAGE.exists();shutil.copytree(BASE,STAGE)
def save_script(name,text): (R/name).write_text(text)
def rewrite(text):return text.replace('hud-segments-1ec-20261005','hud-subsegments-1ec-20261005').replace('pr15-hud-segment-stage-1ec-20261005','pr15-hud-subsegment-stage-1ec-20261005').replace('hud-segment-qa-20261005','hud-subsegment-qa-20261005')
for name in ['driver_core.py','measurement_core.py','select_window.gd','run_native_export.py','end_proof.py','run1-OFF.py','run2-ON.py','run3-ON.py','run4-OFF.py']:
 save_script(name,rewrite((OLD/name).read_text()))
observer=(OLD/'event_log_observer.gd').read_text()
observer=observer.replace('const WIDTH := 20','const WIDTH := 30')
observer=observer.replace('"list_visible","sampler_us"]','"list_visible","sampler_us","capture_calls","capture_us","touch_calls","touch_us","style_calls","style_us","hud_capture_calls","hud_capture_us","touch_capture_calls","touch_capture_us"]')
observer=observer.replace('var active := false','var sub_values := PackedInt64Array([0,0,0,0,0,0,0,0,0,0])\nvar hud_depth := 0\nvar touch_depth := 0\nvar active := false')
observer=observer.replace('\t\t\tsamples[k+19] = Time.get_ticks_usec()-start','\t\t\tfor i in 10: samples[k+20+i] = sub_values[i]\n\t\t\tsamples[k+19] = Time.get_ticks_usec()-start')
observer=observer.replace('\troot_values.fill(0)','\troot_values.fill(0)\n\tsub_values.fill(0)')
observer=observer.replace('"schema":1,"label":meter_label','"schema":2,"label":meter_label')
save_script('event_log_observer.gd',observer);(STAGE/'qa/event_log_observer.gd').write_text(observer)
p=STAGE/'scripts/main.gd';main=p.read_text()
main=main.replace('func replay_hud_frame() -> Dictionary:\n\treturn ViewStateScript.capture(self) if phase == Phase.REPLAY else {}','''func replay_hud_frame() -> Dictionary:
	var qa = get_node("/root/EventLogObserver")
	var measured: bool = qa.active and qa.measure_enabled
	if qa.active:
		qa.sub_values[0] += 1
		if qa.hud_depth > 0: qa.sub_values[6] += 1
		if qa.touch_depth > 0: qa.sub_values[8] += 1
	var started: int = Time.get_ticks_usec() if measured else 0
	var result: Dictionary = ViewStateScript.capture(self) if phase == Phase.REPLAY else {}
	if measured:
		var elapsed: int = Time.get_ticks_usec()-started
		qa.sub_values[1] += elapsed
		if qa.hud_depth > 0: qa.sub_values[7] += elapsed
		if qa.touch_depth > 0: qa.sub_values[9] += elapsed
	return result''')
start=main.index('func _update_hud() -> void:');end=main.index('\n\nfunc _pending_unspawned()',start)
fn=main[start:end].replace('func _update_hud() -> void:\n','func _update_hud() -> void:\n\tvar qa = get_node("/root/EventLogObserver")\n\tqa.hud_depth += 1\n')
fn+='\n\tqa.hud_depth -= 1\n';main=main[:start]+fn+main[end:]
start=main.index('func _refresh_touch_hud() -> void:');end=main.index('\n\nfunc _toggle_event_log()',start)
fn=main[start:end];anchor='\tif touch_hud == null or not touch_hud.has_method("refresh_phase"):\n\t\treturn\n';assert anchor in fn
fn=fn.replace(anchor,anchor+'\tvar qa = get_node("/root/EventLogObserver")\n\tvar measured: bool = qa.active and qa.measure_enabled\n\tif qa.active: qa.sub_values[2] += 1\n\tqa.touch_depth += 1\n\tvar started: int = Time.get_ticks_usec() if measured else 0\n')
fn+='\n\tif measured: qa.sub_values[3] += Time.get_ticks_usec()-started\n\tqa.touch_depth -= 1\n';main=main[:start]+fn+main[end:];p.write_text(main)
p=STAGE/'scripts/touch_hud.gd';touch=p.read_text();start=touch.index('func _apply_btn_style(');end=touch.index('\n\nfunc _kick_btn(',start)
fn=touch[start:end];sig=fn.index('\n')+1
fn=fn[:sig]+'\tvar qa = get_node("/root/EventLogObserver")\n\tvar measured: bool = qa.active and qa.measure_enabled\n\tif qa.active: qa.sub_values[4] += 1\n\tvar started: int = Time.get_ticks_usec() if measured else 0\n'+fn[sig:]
fn+='\n\tif measured: qa.sub_values[5] += Time.get_ticks_usec()-started\n';touch=touch[:start]+fn+touch[end:];p.write_text(touch)
patch=''
for name in ['scripts/main.gd','scripts/touch_hud.gd','qa/event_log_observer.gd']:
 patch+=''.join(difflib.unified_diff((BASE/name).read_text().splitlines(True),(STAGE/name).read_text().splitlines(True),fromfile='HUD-QA/'+name,tofile='HUD-sub-QA/'+name))
save_script('sub-instrumentation.diff',patch)
ctl=rewrite((OLD/'browser_controller.py').read_text())
ctl=ctl.replace('for line in sys.stdin:',"for line in (CONTROL_ROOT/'batch-requests.jsonl').read_text().splitlines():")
ctl=ctl.replace("request_receipt['actual_exit']=1", "request_receipt['actual_exit']=1")
ctl=ctl.replace("persist_receipt(request_label,request_receipt)\n", "persist_receipt(request_label,request_receipt)\n    if request_receipt['actual_exit'] != 0:\n     failed = True\n     break\n")
ctl=ctl.replace('close_request=None;clean_end=False','close_request=None;clean_end=False;failed=False')
ctl=ctl.replace("if __name__=='__main__':main()", " if failed:raise SystemExit(1)\nif __name__=='__main__':main()")
save_script('browser_controller.py',ctl)
proof={'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','game_tree':'1e8af45ee23098f763acc139b56f8f7e0f41665a','basis':str(BASE),'stage':str(STAGE),'sub_patch_sha256':hashlib.sha256(patch.encode()).hexdigest(),'new_tags':['capture/getter','insideHUD capture','touch refresh','style','insideTouch capture'],'OFF_common':'all lookups, branches, counters, two scope depths and packed row sampler shared; ON stamps elapsed; no production optimization'}
save_script('stage-proof.json',json.dumps(proof,indent=2)+'\n')
requests=[{'label':'sub-P0','script':str(R/'p0.py')}]+[{'label':'hud-'+x,'script':str(R/(x+'.py'))} for x in ['run1-OFF','run2-ON','run3-ON','run4-OFF']]+[{'label':'sub-final-proof','script':str(R/'end_proof.py')},{'label':'sub-window-END','close':True}]
save_script('batch-requests.jsonl','\n'.join(json.dumps(x) for x in requests)+'\n')
print(json.dumps(proof))
