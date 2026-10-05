from pathlib import Path
import json,hashlib
R=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005')
a=json.loads((R/'v6-A-final-ui.json').read_text());b=json.loads((R/'v6-B-final-ui.json').read_text())
assert a['checks']==b['checks']==226 and a['failures']==b['failures']==0
hidden=[];accepted=[];allowed_paths={'main/1/7/0/6','main/1/7/1/6','main/1/7/2/6','main/1/7/12/4'}
for ra,rb in zip(a['rows'],b['rows']):
 assert ra.keys()==rb.keys() and ra['label']==rb['label'] and ra['tick']==rb['tick'] and ra['frame']==rb['frame'] and ra['actors']==rb['actors']
 assert len(ra['ui'])==len(rb['ui'])
 for ua,ub in zip(ra['ui'],rb['ui']):
  if ua==ub:continue
  assert ua['path']==ub['path'] and ua['path'] in allowed_paths and ua['class']==ub['class']=='Label'
  assert ua['in_tree']==ub['in_tree']==False
  assert ua.keys()==ub.keys()
  assert all(ua[k]==ub[k] for k in ua if k!='rect')
  assert ua['rect'][0]==ub['rect'][0] and ua['rect'][2:]==ub['rect'][2:]
  hidden.append({'case':ra['label'],'path':ua['path'],'text':ua['text'],'A_rect':ua['rect'],'B_rect':ub['rect'],'in_tree':False})
 accepted.append({'case':ra['label'],'HUD_properties_frame_actors_equal':True})
assert a['cfg']==b['cfg'] and len(hidden)==120 and len(accepted)==30
report={'actual_exit':0,'strict_all_scene_UI_equal':False,'cases':len(accepted),'checks_each':226,'HUD_properties_frame_bones_socket_equal':True,'explicitly_excluded_hidden_live_2D_tag_y_positions':hidden,'raw_A_sha256':hashlib.sha256((R/'v6-A-final-ui.json').read_bytes()).hexdigest(),'raw_B_sha256':hashlib.sha256((R/'v6-B-final-ui.json').read_bytes()).hexdigest(),'all_other_UI_fields_equal':True,'original_values_retained':True,'scope':'controlled original-record consumer; fixed animation clock; four hidden live 2D Tag Y positions differ from initial live SCOUT timing, not HUD or historical 3D; three source tokens verified then omitted'}
with (R/'native-ui-pair.json').open('x') as f:json.dump(report,f,ensure_ascii=False,indent=2)
print(json.dumps({k:v for k,v in report.items() if k!='explicitly_excluded_hidden_live_2D_tag_y_positions'}),flush=True)
source=(R/'native.py').read_text();start=source.index("for entry,mode in");driver=source[:source.index('for label,stage,entry in')]+source[start:];driver=driver.replace("label='v6-'+label","label='gates-'+label")
(R/'required_gates.py').write_text(driver)
exec(compile(driver,str(R/'required_gates.py'),'exec'))
