from pathlib import Path
import json,hashlib
from PIL import Image,ImageChops
R=Path('/tmp/pr15-replay-first-draw-20261005')
def changes(a,b,path=''):
 if type(a)!=type(b):return [{'path':path,'A':a,'B':b}]
 if isinstance(a,dict):
  out=[]
  for k in sorted(a.keys()|b.keys()):
   if k not in a or k not in b:out.append({'path':path+'/'+k,'A':a.get(k),'B':b.get(k)})
   else:out.extend(changes(a[k],b[k],path+'/'+k))
  return out
 if isinstance(a,list):
  if len(a)!=len(b):return [{'path':path+'/length','A':len(a),'B':len(b)}]
  return [d for i,(aa,bb) in enumerate(zip(a,b)) for d in changes(aa,bb,path+'/'+str(i))]
 return [] if a==b else [{'path':path,'A':a,'B':b}]
rows=[]
for p in sorted((R/'A').glob('*.json')):
 if p.name=='summary.json':continue
 q=R/'B'/p.name;assert q.is_file()
 a=json.loads(p.read_text());b=json.loads(q.read_text());diff=changes(a,b)
 ui=[]
 for ca,cb in zip(a['ui'],b['ui']):
  d=changes(ca,cb)
  if d:ui.append({'node':ca['path'],'class':ca['class'],'A_visible':ca['in_tree'],'B_visible':cb['in_tree'],'diff':d})
 row={'label':a['label'],'ticks':[a['tick'],b['tick']],'full_difference_count':len(diff),'differences':diff,'UI_different_nodes':ui}
 if a['drawn']:
  ia=Image.open(p.with_suffix('.png')).convert('RGBA');ib=Image.open(q.with_suffix('.png')).convert('RGBA');assert ia.size==ib.size
  ab=ia.tobytes();bb=ib.tobytes();n=sum(ab[i:i+4]!=bb[i:i+4] for i in range(0,len(ab),4))
  row['pixels']={'size':ia.size,'changed':n,'A_rgba':hashlib.sha256(ab).hexdigest(),'B_rgba':hashlib.sha256(bb).hexdigest()}
  if n:ImageChops.difference(ia,ib).save(R/(a['label']+'-pixel-diff.png'))
 rows.append(row)
(R/'analysis.json').write_text(json.dumps({'rows':rows,'scope':'all preserved fields compared; no field exclusions; synthetic engine GUI input/native llvmpipe only'},ensure_ascii=False,indent=2))
for row in rows:print(json.dumps({'label':row['label'],'ticks':row['ticks'],'full_diff':row['full_difference_count'],'ui_nodes':[(u['node'],u['class'],u['A_visible'],u['B_visible'],len(u['diff'])) for u in row['UI_different_nodes']],'pixel_changed':row.get('pixels',{}).get('changed')},ensure_ascii=False))
