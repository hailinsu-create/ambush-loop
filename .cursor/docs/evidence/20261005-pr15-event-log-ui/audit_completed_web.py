from pathlib import Path
import json,hashlib
B=Path('/tmp/pr15-web-controls/event-log-ui-20261005');SHA='28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266';rows=[]
checks=0
def check(ok):
 global checks
 checks+=1
 assert ok
for folder,cases,exitcode in [('browser-v2',['desktop','scale200'],1),('browser-v3-phone',['phone_landscape'],0)]:
 d=B/folder;result=json.loads((d/'result.json').read_text());check(result['actual_exit']==exitcode);check(not result['page_errors']);check(not [x for x in result['console'] if x['type']=='error' or 'SCRIPT ERROR:' in x['text'] or 'GL_INVALID' in x['text'] or 'INVALID_OPERATION' in x['text']])
 actions=[json.loads(x) for x in (d/'actions.jsonl').read_text().splitlines()]
 for case in cases:
  ended=[x for x in actions if x['label']==case+' END'];check(len(ended)==1)
  before=json.loads((d/(case+'-fingerprints-before.json')).read_text());after=json.loads((d/(case+'-fingerprints-after.json')).read_text());trusted=json.loads((d/(case+'-trusted-inputs.json')).read_text())
  check(before['record_sha256']==after['record_sha256']==SHA);check(before['domain']==after['domain']);check(not after['record_validation']['failures']);check(not after['frame_checks']['failures']);check(bool(trusted) and all(x['isTrusted'] for x in trusted))
  focus=[x for x in actions if x['label']==case+' original glyph focus'];check(len(focus)==(6 if case=='desktop' else 10))
  for row in focus:
   ev=row['event'];a=row['after'];p=row['before'];check(a['replay']['tick']==ev['playback_tick']);check(a['focus_actor']==ev['actor_id']);check(a['event_ring_visible'] and a['focus_type']=='fire' and not a['replay']['playing']);check(a['view']['yaw']==p['view']['yaw'] and a['view']['pitch']==p['view']['pitch']);check(a['view']['wave']==ev['wave_id'] and a['view']['attempt']==ev['attempt_id']);check(a['view']['gesture']['contacts']==0 and a['view']['gesture']['pending_id']==-1)
  for wave in [0,1]:check({x['fraction'] for x in focus if x['event']['wave_id']==wave}=={0,1,2})
  captures=[x for x in actions if x['label'].startswith(case+' capture')];check(len(captures)==2)
  for capture in captures:check(hashlib.sha256((d/capture['path']).read_bytes()).hexdigest()==capture['sha256'])
  warnings=[x for x in result['console'] if x['type']=='warning'];rows.append({'case':case,'raw_driver':folder,'raw_driver_actual_exit':exitcode,'complete_case_end':True,'glyph_focus':len(focus),'browser_trusted':len(trusted),'engine_inputs':len(after['inputs']),'record_domain_unchanged':True,'frame_checks':after['frame_checks'],'console_warning_count_whole_raw_driver':len(warnings),'ReadPixels_whole_raw_driver':sum('ReadPixels' in x['text'] for x in warnings)})
r={'audit_actual_exit':0,'checks':checks,'failures':0,'scope':'offline exact audit of completed desktop/200% cases inside preserved actual1 v2 plus separate actual0 phone v3; does not relabel v2 as overall PASS, no fresh producer or whole/performance/device acceptance','production_source':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','rows':rows}
(B/'completed-web-audit.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
