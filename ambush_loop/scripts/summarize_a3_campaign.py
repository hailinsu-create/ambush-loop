#!/usr/bin/env python3
"""Read only sealed original A3 workload evidence; no engine and no rewriting raw."""
import argparse,csv,hashlib,json,math,pathlib,statistics

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def require(ok,msg):
 if not ok:raise ValueError(msg)
def loc(raw,root):
 require(raw.startswith('res://'),'nonproject evidence path');p=root/'ambush_loop'/raw[6:];require(p.is_file(),f'missing {p}');return p

def percentile(v,q):
 v=sorted(v);a=(len(v)-1)*q;i=int(a);return v[i]+(v[min(i+1,len(v)-1)]-v[i])*(a-i)
def stats(v):return {'count':len(v),'median':statistics.median(v),'p95':percentile(v,.95),'max':max(v)}

def analyze(report,root,proof):
 j=json.loads(report.read_text());receipt=json.loads(proof.read_text());receipt_sha=sha(proof)
 require(j['receipt_sha256']==receipt_sha,'report receipt mismatch')
 for key in ['source_proof_before','source_proof_after']:
  p=j[key];require(p.get('window_control_verified') and p['receipt_sha256']==receipt_sha and p['consumer_commit']==receipt['consumer_commit'] and p['consumer_game_tree']==receipt['consumer_game_tree'],'fixed whole source proof '+key)
 require(j['complete'] and j['failures']==0 and not j['stopped'],'workload incomplete/failed/stopped')
 require(j['source_sha']==receipt['consumer_commit'],'source SHA')
 segments=j['segments'];matrix=[s for s in segments if 'selected_source' in s['receipt']]
 levels=[o['level_id'] for o in j['outcomes']]
 require(len(levels)>0 and len(set(levels))==len(levels),'level identities')
 require(len(matrix)==len(levels)*96,'declared96 source views/level')
 if not j['level_scope']:require(len(levels)==6 and sum(o['waves'] for o in j['outcomes'])==13,'all six13')
 else:require(levels==[j['level_scope']],'requested single level scope')
 require(len(j['chunks'])==len(levels),'one collector chunk per outcome')
 by_label={s['label']:s for s in segments};require(len(by_label)==len(segments),'unique declared segment labels')
 kinds={'SCOUT-saved-move':(0,'dust'),'ALERT-confirmed-shot':(1,'shot'),'SWEEP-saved-move':(5,'dust'),'WON-original-source':(3,'none'),'confirmed-tool-source':(0,'tool'),'FAILED-abort-source':(2,'none')}
 coverage=set();source_bindings={}
 for m in matrix:
  spec=m['receipt'];cfg=spec['configuration'];level=spec['level_id'];src=spec['selected_source'];yaw=cfg['yaw_deg'];policy=spec['policy'];kind=None
  for name,signature in kinds.items():
   if m['label']==f'{level}-{name}-{policy}-yaw{int(yaw)}':kind=name;break
  require(kind is not None and (src['recorded_phase'],src['feature'])==kinds[kind],'declared historical source kind')
  key=(level,kind,policy,yaw);require(key not in coverage,'duplicate matrix view');coverage.add(key)
  require(yaw in range(0,360,45) and cfg['pitch_deg']==(35 if int(yaw/45)%2==0 else 65) and cfg['view_size']==(12 if int(yaw/45)%4<2 else 36),'representative pose mapping')
  binding=json.dumps([src,spec['source_archive']],sort_keys=True);binding_key=(level,kind)
  require(binding_key not in source_bindings or source_bindings[binding_key]==binding,'same exact source for all policy/poses');source_bindings[binding_key]=binding
 expected_coverage={(level,kind,policy,yaw) for level in levels for kind in kinds for policy in ['standard','power_saving'] for yaw in range(0,360,45)}
 require(coverage==expected_coverage,'unique6-source/2-policy/8-yaw coverage per level')
 archives={r['sha256']:r for r in j['records']}
 for a in archives.values():require(sha(loc(a['path'],root))==a['sha256'],'original archive bytes')
 for c in j['captures']:require(sha(loc(c['path'],root))==c['sha256'],'PNG bytes')
 summaries=[];last_time=-1;seen_paths=set();collector_ids=set();chunk_levels=set();analyzed_labels=set();raw_total=accepted_total=0
 expected=['frame','ticks_usec','interval_usec','segment','measured','exclusion','level_id','attempt_id','wave_id','phase','recorded_phase','frame_seq','local_tick','playback_tick','replay','replay_speed','sim_paused','yaw_deg','pitch_deg','view_size','policy','shot_active','shot_cache','shot_reject_geometry','shot_reject_socket','tool_active','tool_reject_geometry','dust_active','dust_reject_geometry','render_setup_ms','collector_usec','presenter_valid','main_auto_process','tree_paused','render_counters_ready','collector_storage_bytes','window_width','window_height','content_scale','max_fps','vsync','TIME_PROCESS','TIME_PHYSICS_PROCESS','RENDER_TOTAL_DRAW_CALLS_IN_FRAME','RENDER_TOTAL_PRIMITIVES_IN_FRAME','RENDER_TOTAL_OBJECTS_IN_FRAME','RENDER_TEXTURE_MEM_USED','RENDER_BUFFER_MEM_USED','RENDER_VIDEO_MEM_USED','MEMORY_STATIC','OBJECT_COUNT','OBJECT_NODE_COUNT','OBJECT_RESOURCE_COUNT','OBJECT_ORPHAN_NODE_COUNT','PIPELINE_COMPILATIONS_CANVAS','PIPELINE_COMPILATIONS_MESH','PIPELINE_COMPILATIONS_SURFACE','PIPELINE_COMPILATIONS_DRAW','PIPELINE_COMPILATIONS_SPECIALIZATION']
 for c in j['chunks']:
  folder=root/'ambush_loop'/c['path'][6:];require(str(folder) not in seen_paths,'duplicate chunk');seen_paths.add(str(folder));require(c['collector_instance_id'] not in collector_ids,'collector reused across level');collector_ids.add(c['collector_instance_id'])
  m=json.loads((folder/'metadata.json').read_text());require(c['valid'] and c['save_error']==0 and m['chunk_source_and_buffer_valid'] and m['complete_buffer'] and m['receipt_stable'] and m['warm_import_proof_complete'] and not m['run_incomplete'] and m['run_overflow_rows']==0 and m['symbol_overflow']==0,'invalid chunk lifecycle')
  require(sha(folder/'raw.csv')==m['raw_sha256']==c['raw_sha256'],'original CSV SHA');require(m['metadata']['source_proof_before']['receipt_sha256']==receipt_sha==m['source_proof_after']['receipt_sha256'],'chunk fixed receipt')
  with (folder/'raw.csv').open(newline='') as stream:
   reader=csv.DictReader(stream);require(reader.fieldnames==expected,'exact59 raw header');rows=list(reader)
  require(len(rows)==m['rows']==c['rows'] and len(rows)>0,'raw count')
  chunk_level=rows[-1]['level_id'];require(chunk_level in levels and chunk_level not in chunk_levels,'one chunk per declared level');chunk_levels.add(chunk_level)
  previous_frame=previous_usec=-1;group={}
  for row in rows:
   require(None not in row and all(v is not None for v in row.values()),'exact row width')
   for k in expected:
    if k not in ['segment','exclusion','level_id','attempt_id','policy']:
     row[k]=float(row[k]);require(math.isfinite(row[k]),'nonfinite '+k)
   require(row['frame']>previous_frame and row['ticks_usec']>previous_usec and row['ticks_usec']>last_time,'monotonic composite frame/time');previous_frame=row['frame'];previous_usec=row['ticks_usec']
   if row['measured']==1:
    require(row['presenter_valid']==row['render_counters_ready']==row['main_auto_process']==1 and row['interval_usec']>0 and row['exclusion']=='' and row['collector_usec']>=0,'invalid measured row')
    group.setdefault(row['segment'],[]).append(row)
  last_time=rows[-1]['ticks_usec'];raw_total+=len(rows)
  require(c['accepted']==sum(map(len,group.values())),'accepted raw count');accepted_total+=c['accepted']
  for declared in m['extra']['segments']:
   label=declared['label']
   if not label.startswith(rows[-1]['level_id']+'-'):continue
   require(label in by_label and declared==by_label[label] and label not in analyzed_labels,'exact report/metadata declared segment binding');analyzed_labels.add(label)
   spec=declared['receipt'];required=spec.get('required_original_command_seconds',0);require(declared.get('original_command_seconds',0)>=required,'original automatic command duration '+label);rr=group.get(label,[]);phase=[r for r in rr if r['phase']==spec['phase']] if 'phase' in spec else rr
   require(len(phase)>=3,'phase sample count '+label)
   if 'minimum_measured_phase_rows' in spec:
    require(spec['minimum_measured_phase_rows']==3 and len(phase)==declared['measured_phase_rows_at_boundary'] and declared['actual_seconds']>=declared['requested_seconds'],'bounded postdraw wall/sample receipt '+label)
   require(all(r['level_id']==spec['level_id'] and r['attempt_id']==spec['attempt_id'] and (r['phase']==4 or r['wave_id']==spec['wave']) for r in rr),'live source identity '+label)
   if spec.get('phase')==4 and 'speed' in spec:require(all(r['replay']==1 and r['replay_speed']==spec['speed'] for r in phase),'replay transport '+label)
   if 'selected_source' in spec:
    s=spec['selected_source'];cfg=spec['configuration'];require(spec['source_archive']['sha256'] in archives,'unsealed matrix source')
    require(all(r['phase']==4 and r['replay']==1 and r['recorded_phase']==s['recorded_phase'] and r['attempt_id']==s['attempt_id'] and r['wave_id']==s['wave'] and r['frame_seq']==s['frame_seq'] and r['playback_tick']==s['tick'] and r['policy']==spec['policy'] and r['yaw_deg']==cfg['yaw_deg'] and r['pitch_deg']==cfg['pitch_deg'] and r['view_size']==cfg['view_size'] for r in rr),'exact selected matrix frame/config '+label)
    feature={'shot':'shot_active','tool':'tool_active','dust':'dust_active'}.get(s['feature'])
    if feature:require(max(r[feature] for r in rr)>0,'selected original pool absent '+label)
   budgets=['interval_usec','collector_usec','TIME_PROCESS','TIME_PHYSICS_PROCESS','RENDER_TOTAL_DRAW_CALLS_IN_FRAME','RENDER_TOTAL_PRIMITIVES_IN_FRAME','RENDER_TOTAL_OBJECTS_IN_FRAME','MEMORY_STATIC','OBJECT_NODE_COUNT','OBJECT_RESOURCE_COUNT','shot_active','tool_active','dust_active']
   summaries.append({'label':label,'actual_seconds':declared['actual_seconds'],'phase_rows':len(phase),'accepted_rows':len(rr),'transition_rows_retained':len(rr)-len(phase),'receipt':spec,'counters':{k:stats([r[k] for r in phase]) for k in budgets}})
 require(len(summaries)==len(segments) and analyzed_labels==set(by_label) and chunk_levels==set(levels),'all exact declared segments and level chunks analyzed')
 require(len(j['command_receipts'])==len(levels)*2 and all(c['accepted'] for c in j['command_receipts']),'original legal move receipts')
 return {'format':1,'status':'valid_original_cloud_workload','source_sha':j['source_sha'],'game_tree':receipt['consumer_game_tree'],'receipt_sha256':receipt_sha,'checks':j['checks'],'failures':j['failures'],'levels':levels,'waves':sum(o['waves'] for o in j['outcomes']),'raw_rows':raw_total,'accepted_rows':accepted_total,'segments':len(segments),'matrix_views':len(matrix),'captures':len(j['captures']),'records':j['records'],'environment':j['environment'],'summaries':summaries,'limitations':'actual controlled API/reference and recorded representative views; warm imports; variable update latency; observed postdraw pools may miss betweenframes; driver/archives/segments/sampler memory resident; llvmpipe, GPUtime unavailable, pipeline unknown; not whole/native-normal/all-art/device performance acceptance'}
p=argparse.ArgumentParser();p.add_argument('--report',type=pathlib.Path,required=True);p.add_argument('--root',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[2]);p.add_argument('--proof',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args();j=analyze(a.report,a.root,a.proof);a.output.write_text(json.dumps(j,indent=2)+'\n');print(json.dumps({k:j[k] for k in ['status','source_sha','levels','waves','raw_rows','accepted_rows','segments','matrix_views','captures']}))
