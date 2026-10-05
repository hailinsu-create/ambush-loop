from pathlib import Path
import json
R=Path('/tmp/pr15-natural-tool-render-v3-20261005')
out=[]
for label in ['warehouse-mine','railcut-repack']:
 b=json.loads((R/label/'before.json').read_text());a=json.loads((R/label/'after.json').read_text());summary=json.loads((R/label/'summary.json').read_text())
 diff=[{'key':k,'before':b['domain'][k],'after':a['domain'].get(k)} for k in b['domain'] if b['domain'][k]!=a['domain'].get(k)]
 assert diff==[{'key':'phase','before':4,'after':3}],diff
 assert b['cfg']==a['cfg'] and b['checkpoint']==a['checkpoint'] and a['record_unchanged']
 rows=[]
 for p in sorted((R/label).glob('*.json')):
  if p.name in ['before.json','after.json','summary.json']:continue
  j=json.loads(p.read_text());assert j['domain']==b['domain'] and j['cfg']==b['cfg'] and j['checkpoint']==b['checkpoint']
  assert not j['tool_pool_active']
  rows.append({'label':p.stem,'tick':j['tick'],'event_identity':j['target_event']['event_id'],'op1':next(x for x in j['actors'] if x['group']=='ops' and x['id']==1)})
 result={'label':label,'checks':summary['checks'],'failures':summary['failures'],'samples':len(rows),'within_REPLAY_full_domain_cfg_checkpoint_equal':True,'exit_cfg_checkpoint_equal':True,'exit_domain_differences':diff,'record_unchanged':True,'rows':rows}
 if label=='warehouse-mine':
  pre=json.loads((R/label/'before-event.json').read_text());post=json.loads((R/label/'after-event.json').read_text())
  before=next(x for x in pre['frame']['enemies'] if x['id']==2);after=next(x for x in post['frame']['enemies'] if x['id']==2)
  result['historical_victim']={'id':2,'before_hp':before['hp'],'after_hp':after['hp'],'before_alive':before['alive'],'after_alive':after['alive'],'damage':before['hp']-after['hp'],'source_frame_ticks':[pre['tick'],post['tick']]}
  assert result['historical_victim']['damage']==120 and before['alive'] and not after['alive']
 else:
  names=['event','reload-contact','after-reload'];seq=[]
  for name in names:
   j=json.loads((R/label/(name+'.json')).read_text());actor=next(x for x in j['actors'] if x['group']=='ops' and x['id']==1)
   seq.append({'sample':name,'tick':j['tick'],'action':actor['action'],'event_id':actor['layers']['event_id'],'weapon':actor['equipped']})
  assert [x['action'] for x in seq]==['fire','reload_contact','fire']
  result['actual_action_sequence']=seq
 out.append(result)
(R/'analysis.json').write_text(json.dumps({'actual_exit':0,'cases':out,'scope':'offline analysis of actual saved full native consumer states; explicit exit phase4->3, all other fields retained; does not create producer/new mine cue/whole/Web/hand-contact or performance acceptance'},ensure_ascii=False,indent=2))
print(json.dumps({'actual_exit':0,'cases':[{'label':x['label'],'checks':x['checks'],'failures':x['failures'],'samples':x['samples'],'exit_domain_differences':x['exit_domain_differences']} for x in out]},ensure_ascii=False))
