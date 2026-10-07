from pathlib import Path
import json,statistics,math,hashlib
from PIL import Image, ImageChops
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005');B=R/'run'
def dist(values):
 if not values:return {'n':0,'median_us':None,'p95_us':None}
 s=sorted(values);return {'n':len(s),'median_us':statistics.median(s),'p95_us':s[math.ceil(.95*len(s))-1],'min_us':s[0],'max_us':s[-1]}
tags=['root_us','select_slider_us','paint_us','event_select_title_us','list_us','status_us','transport_us','hud_us','presenter_us','sampler_us']
results=[]
for run,mode in [(1,'OFF'),(2,'ON'),(3,'ON'),(4,'OFF')]:
 label=f'run{run}-{mode}';entry={'label':label,'enabled':mode=='ON','phases':{}}
 entry['receipt']=json.loads((B/'receipts'/('hud-'+label+'.json')).read_text())
 assert entry['receipt']['actual_exit']==0
 entry['end']=json.loads((B/(label+'-end.json')).read_text())
 for phase in ['static','advance']:
  raw=json.loads((B/(label+'-'+phase+'-raw.json')).read_text());rows=[dict(zip(raw['columns'],x)) for x in raw['rows']]
  assert raw['done'] and not raw['overflow'] and len(rows)>=12
  assert all(x['view_tick']==x['tick'] for x in rows)
  measure={'samples':len(rows),'postdraw_interval':dist([x[2] for x in raw['posts'] if x[2]>0]),'engine_delta':dist([x['delta_us'] for x in rows]),'tick_range':[rows[0]['tick'],rows[-1]['tick']],'root_calls':sum(x['root_calls'] for x in rows),'presenter_calls':sum(x['presenter_calls'] for x in rows),'list_rows':sorted(set(x['list_rows'] for x in rows)),'list_visible':sorted(set(x['list_visible'] for x in rows)),'tags':{t:dist([x[t] for x in rows if x['root_calls']>0 or t in ['presenter_us','sampler_us']]) for t in tags},'root_remainder':dist([x['root_us']-sum(x[t] for t in tags[1:8]) for x in rows if x['root_calls']>0])}
  if mode=='ON' and phase=='advance':
   measure['root_partition_sum_us']={t:sum(x[t] for x in rows) for t in tags[:8]}
   measure['partition_fraction']={t:sum(x[t] for x in rows)/sum(x['root_us'] for x in rows) for t in tags[1:8]}
  entry['phases'][phase]=measure
 results.append(entry)
images=[('run1-OFF-static.png',f'run{x}-{mode}-static.png') for x,mode in [(2,'ON'),(3,'ON'),(4,'OFF')]]
pixels=[]
for a,b in images:
 im1=Image.open(B/a).convert('RGBA');im2=Image.open(B/b).convert('RGBA');assert im1.size==im2.size
 data1=im1.tobytes();data2=im2.tobytes();changed=sum(data1[i:i+4]!=data2[i:i+4] for i in range(0,len(data1),4))
 pixels.append({'a':a,'b':b,'changed_pixels':changed,'pixels':im1.width*im1.height,'pixel_exact':changed==0,'a_rgba_sha256':hashlib.sha256(data1).hexdigest(),'b_rgba_sha256':hashlib.sha256(data2).hexdigest()})
pairs=[]
for phase in ['static','advance']:
 med=[r['phases'][phase]['postdraw_interval']['median_us'] for r in results]
 p95=[r['phases'][phase]['postdraw_interval']['p95_us'] for r in results]
 pairs.append({'phase':phase,'postdraw_medians_us':med,'postdraw_p95_us':p95,'pair1_ON2_vs_OFF1_pct':(med[1]/med[0]-1)*100,'pair2_ON3_vs_OFF4_pct':(med[2]/med[3]-1)*100,'OFF_repeat_drift_pct':(med[3]/med[0]-1)*100,'ON_repeat_drift_pct':(med[2]/med[1]-1)*100,'scope':'paired direction/drift only; not pure instrumentation CPU/GPU causal attribution'})
safe_receipts=[{k:r['receipt'][k] for k in ['start','end','actual_exit','loaded_script_sha256']} for r in results]
for r in results:r['receipt']={k:r['receipt'][k] for k in ['start','end','actual_exit','loaded_script_sha256']}
report={'schema':1,'results':results,'pixels':pixels,'overhead_pairs':pairs,'scope':'HUD subsegments SCOUT wave0 source frame792 start6339; no fire/throw/mine/repack/dense event list/other levels; Time elapsed inclusive, ANGLE SwiftShader; fixed OFF row sampler/branches/lookups/counters common; root sections telescope to root, cannot add root+children/presenter as frame; static vs advance not causally subtractable'}
(R/'analysis.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'runs':[{'label':r['label'],'wall_s':r['end']['wall_s'],'samples':{p:r['phases'][p]['samples'] for p in ['static','advance']},'advance_median_us':{t:r['phases']['advance']['tags'][t]['median_us'] for t in tags},'partition_fraction':r['phases']['advance'].get('partition_fraction')} for r in results],'pairs':pairs,'pixel_exact':[p['pixel_exact'] for p in pixels]},indent=2))
