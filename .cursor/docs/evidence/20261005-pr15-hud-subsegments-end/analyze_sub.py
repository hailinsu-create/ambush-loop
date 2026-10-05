from pathlib import Path
import json,statistics,math
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
def dist(a):
 if not a:return {'n':0}
 s=sorted(a);return {'n':len(s),'median_us':statistics.median(s),'p95_us':s[math.ceil(len(s)*.95)-1],'sum_us':sum(s),'min_us':s[0],'max_us':s[-1]}
tags=['capture_calls','capture_us','hud_capture_calls','hud_capture_us','touch_calls','touch_us','style_calls','style_us','touch_capture_calls','touch_capture_us']
out=[]
for n,mode in [(1,'OFF'),(2,'ON'),(3,'ON'),(4,'OFF')]:
 phases={}
 for phase in ['static','advance']:
  raw=json.loads((R/'run'/f'run{n}-{mode}-{phase}-raw.json').read_text());cols=raw['columns'];rows=[dict(zip(cols,x)) for x in raw['rows']]
  assert len(rows)>=12 and not raw['overflow']
  phases[phase]={'samples':len(rows),'tags':{tag:dist([x[tag] for x in rows]) for tag in tags},'counts':{tag:sorted(set(x[tag] for x in rows)) for tag in tags if tag.endswith('_calls')},'scope':'capture in touch overlaps total HUD capture; style is nested in touch, do not sum inclusive rows'}
  if mode=='ON' and phase=='advance':
   hud=sum(x['hud_us'] for x in rows);root=sum(x['root_us'] for x in rows)
   phases[phase]['sum_fraction_of_HUD']={tag:sum(x[tag] for x in rows)/hud for tag in ['hud_capture_us','touch_us','style_us','touch_capture_us']}
   phases[phase]['sum_fraction_of_root']={tag:sum(x[tag] for x in rows)/root for tag in ['hud_capture_us','touch_us','style_us']}
   phases[phase]['HUD_disjoint_partition_us']={'capture_outside_touch':sum(x['hud_capture_us']-x['touch_capture_us'] for x in rows),'touch_inclusive':sum(x['touch_us'] for x in rows),'other_and_measurement':sum(x['hud_us']-x['hud_capture_us']+x['touch_capture_us']-x['touch_us'] for x in rows)}
 out.append({'run':f'run{n}-{mode}','phases':phases})
report={'schema':1,'runs':out,'scope':'fixed consumer/formal two ON repeats; elapsed not pureCPU/GPU; actual callcounts, no causal wholeframe percentage'}
(R/'sub-analysis.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps([x for x in out if 'ON' in x['run']],indent=2))
