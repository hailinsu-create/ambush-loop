from pathlib import Path
import shutil,json,hashlib,difflib
R=Path('/tmp/pr15-web-controls/replay-touch-abba-95daa-20261005')
OLD=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
BASE=Path('/workspace/pr15-hud-subsegment-stage-1ec-20261005')
A=Path('/workspace/pr15-replay-touch-qa-A-95daa-20261005');B=Path('/workspace/pr15-replay-touch-qa-B-95daa-20261005')
assert not R.exists();R.mkdir()
shutil.copytree(BASE,A);shutil.copytree(BASE,B)
anchor='\t_apply_watch_layers()\n\t_ensure_touch_hud()\n\t_refresh_touch_hud()\n\t_apply_phone_world_ink()'
replacement='\t_apply_watch_layers()\n\t_ensure_touch_hud()\n\t# Ensure already refreshes the touch HUD with this selected replay frame.\n\tif phase != Phase.REPLAY:\n\t\t_refresh_touch_hud()\n\t_apply_phone_world_ink()'
p=B/'scripts/main.gd';s=p.read_text();assert s.count(anchor)==1;p.write_text(s.replace(anchor,replacement))
(R/'runtime-candidate.diff').write_text(''.join(difflib.unified_diff((A/'scripts/main.gd').read_text().splitlines(True),p.read_text().splitlines(True),fromfile='A/scripts/main.gd',tofile='B/scripts/main.gd')))
observer=(OLD/'event_log_observer.gd').read_text()
observer=observer.replace('"tick":m.replay.scrub_tick,"attempt":m.battle_log.attempt_id','"touch_ui":_touch_ui(m.touch_hud),"tick":m.replay.scrub_tick,"attempt":m.battle_log.attempt_id')
observer+='''
func _touch_ui(n: Node) -> Array:
	var out: Array = []
	_collect_touch_ui(n,"touch",out)
	return out

func _style_plain(style: StyleBox) -> Dictionary:
	var out: Dictionary = {"class":style.get_class()}
	for p in style.get_property_list():
		if p.usage & PROPERTY_USAGE_STORAGE and p.name not in ["resource_local_to_scene","resource_name","script"]:
			var value: Variant = style.get(p.name)
			out[str(p.name)] = [value.r,value.g,value.b,value.a] if value is Color else _plain(value)
	return out

func _collect_touch_ui(n: Node, path: String, out: Array) -> void:
	if n is Control:
		var item: Dictionary = {"path":path,"class":n.get_class(),"visible":n.visible,"in_tree":n.is_visible_in_tree(),"rect":_plain(n.get_global_rect()),"modulate":[n.modulate.r,n.modulate.g,n.modulate.b,n.modulate.a]}
		if n is Button:
			item.merge({"text":n.text,"disabled":n.disabled,"pressed":n.button_pressed,"font_size":n.get_theme_font_size("font_size")})
			var styles: Dictionary = {}
			for name: String in ["normal","hover","pressed","disabled","focus"]: styles[name] = _style_plain(n.get_theme_stylebox(name))
			item["styles"] = styles
		elif n is Label: item["text"] = n.text
		elif n is Range: item.merge({"value":n.value,"min":n.min_value,"max":n.max_value})
		out.append(item)
	for i in n.get_child_count(): _collect_touch_ui(n.get_child(i),path+"/"+str(i),out)
'''
for stage in [A,B]:(stage/'qa/event_log_observer.gd').write_text(observer)
(R/'event_log_observer.gd').write_text(observer)
for name in ['driver_core.py','measurement_core.py','selected-window.json']:
 s=(OLD/name).read_text().replace('hud-subsegments-1ec-20261005','replay-touch-abba-95daa-20261005')
 (R/name).write_text(s)
for number,side in [(1,'A'),(2,'B'),(3,'B'),(4,'A')]:
 label=f'run{number}-{side}'
 script=f'''from pathlib import Path
CONTROL_ROOT=Path('{R}')
for helper_name in ['driver_core.py','measurement_core.py']:
 helper=(CONTROL_ROOT/helper_name).read_bytes()
 with (BASE/'loaded-controls'/helper_name).open('xb') as f:f.write(helper)
exec(compile((CONTROL_ROOT/'measurement_core.py').read_bytes(),str(CONTROL_ROOT/'measurement_core.py'),'exec'),globals())
page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('typeof window.pr15Observer==="function"',timeout=60000)
s=d.wait(lambda x:x.get('fixture_ready') and x.get('phase')==3,'paired yard WON ready',60)
assert len(context.pages)==1 and s['attempt']==selection['attempt']
d.click('replay');position()
'''
 if number==1:
  script+='''before=fingerprint();save('p0-before-full.json',before);canonical=d.rpc('canonical')
static,rows=phase('p0-OFF-static',False,seconds=2,warm=0)
assert all(x['root_calls']==x['capture_calls']==0 and x['presenter_calls']>0 for x in rows)
d.key('p');advance,rows=phase('p0-OFF-advance',False,seconds=3,warm=0)
assert all(x['capture_calls']==x['hud_capture_calls']==8 and x['touch_calls']==2 and x['style_calls']==50 and x['touch_capture_calls']==2 for x in rows)
save('p0-positive-counts.json',{'rows':len(rows),'capture_counts':sorted(set(x['capture_calls'] for x in rows)),'touch_counts':sorted(set(x['touch_calls'] for x in rows)),'style_counts':sorted(set(x['style_calls'] for x in rows)),'timers_common_OFF':True})
d.key('p');position();after=fingerprint();same(before,after);assert d.rpc('canonical')==canonical
elapsed=time.monotonic()-json.loads((CONTROL_ROOT/'budget-start.json').read_text())['monotonic'];assert elapsed<=120,elapsed
gl=page.evaluate("""()=>{const g=document.createElement('canvas').getContext('webgl2');const e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER),version:g.getParameter(g.VERSION)}}""")
save('p0-end.json',{'actual_exit':0,'wall_s':elapsed,'renderer':gl,'common_OFF_counter_positive_static_negative_and_fingerprint_neutral':True,'original_timeout_and_mixed_overhead_retained':True})
print(json.dumps({'ABBA_P0':'PASS','wall_s':elapsed,'renderer':gl}),flush=True)
'''
 script+=f'''run('{label}',False)
d.key('Space');assert d.state()['phase']==3
fp=fingerprint();same(json.loads((BASE/'{label}-before-full.json').read_text()),fp);save('post-WON-full-fingerprint.json',fp)
inputs=d.rpc('fingerprints')['inputs'];trusted=page.evaluate('window.pr15TrustedInputs')
save('final-input-proof.json',{{'engine_inputs':inputs,'DOM_inputs':trusted,'DOM_all_isTrusted':all(x['isTrusted'] for x in trusted),'single_page':len(context.pages)==1,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors}})
assert all(x['isTrusted'] for x in trusted) and not errors and not [x for x in console if x['type']=='error']
print(json.dumps({{'ABBA_FINAL_PROOF':'{label}','engine_inputs':len(inputs),'DOM_inputs':len(trusted)}}),flush=True)
'''
 (R/(label+'.py')).write_text(script)
proof={'A_source':'1ec3198e9c0db367af96fc264604c5a286003b5e','B_source':'95daa05d0ccfc4e6bd357060b1f34c2a863c2041','A_stage':str(A),'B_stage':str(B),'QA_common':'same sealed subsegment instrumentation, common OFF only plus read-only final touch UI canonical; no source or asset generator','production_diff':'main only: omit second adjacent refresh in REPLAY','changes_vs_sealed_QA_A':['qa/event_log_observer.gd'],'changes_vs_A_B':['scripts/main.gd'],'files':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [A/'scripts/main.gd',B/'scripts/main.gd',A/'qa/event_log_observer.gd']}}
(R/'stage-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps(proof))
