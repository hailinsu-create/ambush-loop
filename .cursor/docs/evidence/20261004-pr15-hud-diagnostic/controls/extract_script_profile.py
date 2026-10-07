import re,json,sys,math
from pathlib import Path
LABELS=['yard-static-confirmed-shot','yard-advancing-original-replay']
SELECT=[('res://scripts/main.gd','_process'),('res://scripts/main.gd','_apply_replay_scrub'),('res://scripts/main.gd','_update_hud'),('res://scripts/main.gd','_ensure_touch_hud'),('res://scripts/main.gd','_refresh_touch_hud'),('res://scripts/main.gd','_paint_replay_snapshot'),('res://scripts/presentation/presenter_3d.gd','refresh'),('res://scripts/touch_hud.gd','refresh_phase'),('res://scripts/touch_hud.gd','_apply_btn_style'),('res://scripts/touch_hud.gd','_paint_lock_states'),('res://scripts/touch_hud.gd','_apply_safe_area'),('res://scripts/operator.gd','_ensure_tag_plate')]
ENTRY=re.compile(r'^(\d+):([^\n]+)\n\ttotal: ([0-9.eE+-]+)/[^\n]*?\tself: ([0-9.eE+-]+)/[^\n]*?tcalls: (\d+)',re.M)
def parse_block(part):
 total=float(part.split('\n',1)[0].split()[0]);rows=[]
 for m in ENTRY.finditer(part):
  row={'rank':int(m[1]),'signature':m[2],'inclusive_seconds':float(m[3]),'self_seconds':float(m[4]),'calls':int(m[5])}
  assert all(math.isfinite(row[k]) and row[k]>=0 for k in ['inclusive_seconds','self_seconds'])
  rows.append(row)
 assert rows and [r['rank'] for r in rows]==list(range(len(rows))) and len(rows)<32768
 assert len({r['signature'] for r in rows})==len(rows)
 # Preserve the function list and validate the profiler's own disjoint sum,
 # rather than trusting printed integer percentages or summing inclusives.
 disjoint=sum(r['self_seconds'] for r in rows)
 assert abs(disjoint-total)<.003,(disjoint,total)
 select={}
 for path,func in SELECT:
  hits=[r for r in rows if r['signature'].split('::')[0]==path and r['signature'].split('::')[-1].split('.')[-1]==func]
  assert len(hits)==1,(path,func,len(hits))
  select[path+'::'+func]=hits[0]
 return {'profiler_disjoint_self_sum_seconds':total,'signature_count':len(rows),'selected':select,'all_nonzero_functions':[r for r in rows if r['calls'] or r['self_seconds'] or r['inclusive_seconds']]}
def run(path):
 s=Path(path).read_text();assert not re.search(r'^(ERROR:|SCRIPT ERROR:)',s,re.M)
 output={'log':str(path),'segments':[]}
 for label in LABELS:
  start='HUD_PROFILE_BEGIN label='+label+' mode=1';end='HUD_PROFILE_END label='+label+' mode=1'
  assert s.count(start)==s.count(end)==1
  section=s.split(start,1)[1].split(end,1)[0]
  assert section.count('BEGIN PROFILING')==section.count('ACCUMULATED: total:')==1
  accum=parse_block(section.split('ACCUMULATED: total:',1)[1])
  frames=[]
  for part in section.split('FRAME: total:')[1:]:
   # FRAME headers also carry script timing; keep latest-frame data separate.
   header=part.split('\n',1)[0];frames.append({'header':header,'entries':len(ENTRY.findall(part.split('ACCUMULATED:',1)[0]))})
  assert frames
  accum['label']=label;accum['latest_frame_samples']=frames
  root=accum['selected'];scrub=root['res://scripts/main.gd::_apply_replay_scrub'];refresh=root['res://scripts/presentation/presenter_3d.gd::refresh'];hud=root['res://scripts/main.gd::_update_hud'];style=root['res://scripts/touch_hud.gd::_apply_btn_style']
  if label==LABELS[0]:assert scrub['calls']==0 and hud['calls']==0
  else:
   assert scrub['calls']>=25 and hud['calls']==scrub['calls'] and style['calls']==50*hud['calls']
   assert style['inclusive_seconds']<=hud['inclusive_seconds']<=scrub['inclusive_seconds']
   accum['H1_scrub_share_of_two_nonnested_roots']=scrub['inclusive_seconds']/(scrub['inclusive_seconds']+refresh['inclusive_seconds'])
   accum['style_self_share_of_hud_inclusive']=style['self_seconds']/hud['inclusive_seconds']
  output['segments'].append(accum)
 return output
if __name__=='__main__':
 result=run(sys.argv[1]);Path(sys.argv[2]).write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({'segments':[{'label':s['label'],'signature_count':s['signature_count'],'H1':s.get('H1_scrub_share_of_two_nonnested_roots'),'style/HUD':s.get('style_self_share_of_hud_inclusive'),'selected':s['selected']} for s in result['segments']]},indent=2))
