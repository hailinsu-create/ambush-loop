from pathlib import Path
import json,math,statistics,hashlib
from PIL import Image
R=Path('/tmp/pr15-web-controls/replay-touch-abba-95daa-20261005');OUT=R/'run'
def dist(values):
 s=sorted(values);return {'n':len(s),'median_us':statistics.median(s),'p95_us':s[math.ceil(.95*len(s))-1],'min_us':s[0],'max_us':s[-1],'sum_us':sum(s),'over_33333':sum(x>33333 for x in s),'over_16667':sum(x>16667 for x in s)}
results=[];canon=None
for n,side in [(1,'A'),(2,'B'),(3,'B'),(4,'A')]:
 label=f'run{n}-{side}';base=OUT/label;rec=json.loads((OUT/'receipts'/(label+'.json')).read_text());assert rec['actual_exit']==0
 end=json.loads((base/(label+'-end.json')).read_text());assert end['actual_exit']==0 and end['wall_s']<=90
 before=json.loads((base/(label+'-before-full.json')).read_text());after=json.loads((base/(label+'-after-full.json')).read_text());won=json.loads((base/'post-WON-full-fingerprint.json').read_text())
 for key in ['record_sha256','domain','settings','public_checkpoint']:assert before[key]==after[key]==won[key],key
 static=json.loads((base/(label+'-static-canonical-before.json')).read_text());assert static==json.loads((base/(label+'-static-canonical-after.json')).read_text())
 if canon is None:canon=static
 else:assert canon==static,'whole static frame/actors/touch UI canonical'
 inputproof=json.loads((base/'final-input-proof.json').read_text());assert inputproof['DOM_all_isTrusted'] and not inputproof['console_errors'] and not inputproof['page_errors']
 entry={'label':label,'side':side,'receipt':{k:rec[k] for k in ['start','end','actual_exit','loaded_script_sha256','profile','clean_context_end']},'end':end,'input_counts':{'DOM':len(inputproof['DOM_inputs']),'engine':len(inputproof['engine_inputs'])},'phases':{}}
 for phase in ['static','advance']:
  raw=json.loads((base/(label+'-'+phase+'-raw.json')).read_text());rows=[dict(zip(raw['columns'],x)) for x in raw['rows']]
  assert raw['done'] and not raw['overflow'] and raw['enabled']==False and len(rows)>=12
  assert all(x['view_tick']==x['tick'] for x in rows)
  assert all(x['root_us']==x['capture_us']==x['touch_us']==x['style_us']==x['presenter_us']==0 for x in rows)
  counts={k:sorted(set(x[k] for x in rows)) for k in ['capture_calls','hud_capture_calls','touch_calls','style_calls','touch_capture_calls']}
  expected=[8,8,2,50,2] if side=='A' else [7,7,1,25,1]
  if phase=='advance':assert [v for v in counts.values()]==[[x] for x in expected]
  else:assert all(v==[0] for v in counts.values())
  entry['phases'][phase]={'samples':len(rows),'postdraw_interval':dist([x[2] for x in raw['posts'] if x[2]>0]),'delta_us':dist([x['delta_us'] for x in rows]),'tick_range':[rows[0]['tick'],rows[-1]['tick']],'counts':counts,'root_calls':sum(x['root_calls'] for x in rows),'presenter_calls':sum(x['presenter_calls'] for x in rows),'list_rows':sorted(set(x['list_rows'] for x in rows)),'list_visible':sorted(set(x['list_visible'] for x in rows)),'OFF_time_fields_zero_by_design':True}
 results.append(entry)
pixels=[];a=Image.open(OUT/'run1-A/run1-A-static.png').convert('RGBA');ad=a.tobytes()
for n,side in [(2,'B'),(3,'B'),(4,'A')]:
 b=Image.open(OUT/f'run{n}-{side}'/f'run{n}-{side}-static.png').convert('RGBA');bd=b.tobytes();assert a.size==b.size
 changed=sum(ad[i:i+4]!=bd[i:i+4] for i in range(0,len(ad),4));pixels.append({'A':'run1-A','B':f'run{n}-{side}','pixels':a.width*a.height,'changed_pixels':changed,'pixel_exact':changed==0,'A_rgba_sha256':hashlib.sha256(ad).hexdigest(),'B_rgba_sha256':hashlib.sha256(bd).hexdigest()});assert changed==0
pairs=[]
for phase in ['static','advance']:
 med=[r['phases'][phase]['postdraw_interval']['median_us'] for r in results];p95=[r['phases'][phase]['postdraw_interval']['p95_us'] for r in results]
 pairs.append({'phase':phase,'postdraw_medians_us':med,'postdraw_p95_us':p95,'pair1_B2_vs_A1_pct':(med[1]/med[0]-1)*100,'pair2_B3_vs_A4_pct':(med[2]/med[3]-1)*100,'A_repeat_drift_pct':(med[3]/med[0]-1)*100,'B_repeat_drift_pct':(med[2]/med[1]-1)*100,'scope':'common OFF overhead remains; paired direction/tail/drift only, not CPU/GPU attribution or device/30FPS acceptance'})
report={'schema':1,'A_source':'1ec3198e9c0db367af96fc264604c5a286003b5e','B_source':'95daa05d0ccfc4e6bd357060b1f34c2a863c2041','runs':results,'pixels':pixels,'pairs':pairs,'whole_static_canonical_equal':True,'record_domain_complete_cfg_checkpoint_each_run_exact':True,'scope':'original yard e850 consumer/6339/wave0 SCOUT empty event list; fresh ABBA common OFF; no new producer/whole/APK/device/A3; all first P0 and mixed OFF/ON failures retained'}
(R/'analysis.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'counts':[{r['label']:r['phases']['advance']['counts']} for r in results],'pairs':pairs,'pixel_exact':all(x['pixel_exact'] for x in pixels)},indent=2))
