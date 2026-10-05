#!/usr/bin/env python3
"""Strict offline original CSV comparison; never runs an engine or rewrites raw."""
import argparse, ast, csv, datetime, hashlib, json, math, pathlib, re, statistics

CONTROL = pathlib.Path('/tmp/pr15-hud-diagnostic')
VERSIONS = {'A': ('f275178c0f60a7579685f9823894cafc3386f6da', 'fae983e61e032abd93fbd99f9491c4a90ec57b17', 'baseline-f275'), 'B': ('541d06440a97dd77f8c484a8de2a0ce364a8d91e', '53ffc88566b1ce7bd40daa1ce847c838f04fbd85', 'candidate-541d')}
LABELS = ['yard-static-confirmed-shot', 'yard-advancing-original-replay']
TOKENS = ['shot_fx_source_token', 'tool_fx_source_token', 'movement_fx_source_token']
ARCHIVE = '426cf659c9fd10a47e53cd6ef28363e9e38ced0a6cb30c65cc844885104c4598'
ATTEMPT = 'ebb3b40c430e9939e054455f03a54e6f'
FIXTURE = '876e53dcc4fd2ce90c6bed20c8010d9996eeebae0d50fbe241c6ffe6f9fbc204'
IMPORTS = '513aba6cd0bd41c141fd5c53603fd0d541ea63bf4032634848c21d3b867f552d'
COUNTERS = ['interval_usec','collector_usec','render_setup_ms','TIME_PROCESS','TIME_PHYSICS_PROCESS',
 'RENDER_TOTAL_DRAW_CALLS_IN_FRAME','RENDER_TOTAL_PRIMITIVES_IN_FRAME','RENDER_TOTAL_OBJECTS_IN_FRAME',
 'MEMORY_STATIC','OBJECT_COUNT','OBJECT_NODE_COUNT','OBJECT_RESOURCE_COUNT','OBJECT_ORPHAN_NODE_COUNT',
 'RENDER_TEXTURE_MEM_USED','RENDER_BUFFER_MEM_USED','RENDER_VIDEO_MEM_USED',
 'shot_active','shot_cache','tool_active','dust_active','shot_reject_geometry','shot_reject_socket',
 'tool_reject_geometry','dust_reject_geometry','frame_seq','playback_tick','local_tick']

def require(value, message):
    if not value: raise ValueError(message)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p): return json.loads(p.read_text())
def date(p): return datetime.datetime.fromisoformat(p.read_text().strip().replace('Z','+00:00'))
def distribution(values):
    v=sorted(values); require(bool(v),'empty distribution')
    def percentile(q):
        rank=(len(v)-1)*q; low=int(rank); return v[low]+(v[min(low+1,len(v)-1)]-v[low])*(rank-low)
    return {'n':len(v),'min':v[0],'median':statistics.median(v),'p95':percentile(.95),'p99':percentile(.99),'max':v[-1]}
def columns():
    path=pathlib.Path('/workspace/ambush-pr15/ambush_loop/scripts/summarize_a3_window_controls.py')
    values={}
    for node in ast.parse(path.read_text()).body:
        if isinstance(node,ast.Assign) and isinstance(node.targets[0],ast.Name) and node.targets[0].id in ['COLLECTOR_COLUMNS','COLLECTOR_TEXT']:
            values[node.targets[0].id]=ast.literal_eval(node.value)
    return values['COLLECTOR_COLUMNS'], values['COLLECTOR_TEXT']

def analyze_run(variant,label):
    source,tree,stage=VERSIONS[variant]; stem=CONTROL/label
    log=stem.with_suffix('.log').read_text()
    require(int(stem.with_suffix('.exit').read_text())==0 and not re.search(r'^(?:ERROR:|SCRIPT ERROR:)',log,re.M),'actual exit/E/S '+label)
    marker=re.search(r'HUD_BATCH_PAIR_TEST checks=(\d+) failures=0 windows=2 output=res://([^\n]+)',log)
    require(marker is not None,'complete actual suite marker '+label)
    uid=re.search(r'^TEST_RUN_ID=([0-9a-f]+)$',log,re.M).group(1)
    project=pathlib.Path('/workspace/pr15-hud-baseline-f275' if variant=='A' else '/workspace/ambush-pr15')/'ambush_loop'
    root=project/marker.group(2); require(root.name=='hud-batch-pair-'+uid,'exact original UUID directory')
    j=load(root/'report.json'); proof_path=CONTROL/(stage+'-proof.json'); proof=load(proof_path)
    require(j['checks']==int(marker.group(1)) and j['failures']==0 and len(j['segments'])==len(j['pair_rows'])==len(j['captures'])==2 and len(j['chunks'])==1,'two complete windows/captures/chunk')
    require(j['source_sha']==source and j['source_game_tree']==tree and j['receipt_sha256']==sha(proof_path),'fixed source/tree/receipt')
    require(j['external_fixture_sha256']==FIXTURE and j['import_metadata_sha256']==IMPORTS,'frozen common fixture/loader metadata')
    require(proof['consumer_commit']==source and proof['consumer_game_tree']==tree,'proof identity')
    for p in [j['source_proof_before'],j['source_proof_after']]:
        require(p['window_control_verified'] and p['complete_source_tree_verified'] and p['source_files_verified']==988 and p['imported_cache_files_verified']==986 and p['consumer_commit']==source and p['consumer_game_tree']==tree and p['receipt_sha256']==sha(proof_path),'complete source/cache proof')
    chunk=j['chunks'][0]; directory=project/chunk['path'][6:]; require(directory.parent==root,'bound original chunk')
    m=load(directory/'metadata.json')
    require(chunk['valid'] and chunk['save_error']==0 and m['chunk_source_and_buffer_valid'] and m['complete_buffer'] and m['receipt_stable'] and m['warm_import_proof_complete'] and not m['run_incomplete'] and m['run_overflow_rows']==m['overflow_rows']==m['symbol_overflow']==0,'complete buffer lifecycle')
    require(sha(directory/'raw.csv')==m['raw_sha256']==chunk['raw_sha256'],'original raw hash')
    require(m['metadata']['source_proof_before']['receipt_sha256']==m['source_proof_after']['receipt_sha256']==sha(proof_path),'chunk fixed provenance')
    require(m['metadata']['source_sha']==source and m['metadata']['run_id']==uid and m['metadata']['buffer']['columns']==59 and m['metadata']['buffer']['payload_bytes']==15466496,'collector identity/storage')
    require(m['extra']['segments']==j['segments'],'exact metadata/report segments')
    header,text=columns()
    with (directory/'raw.csv').open(newline='') as stream:
        reader=csv.DictReader(stream); require(reader.fieldnames==header and len(header)==59,'exact59 raw schema'); rows=list(reader)
    require(len(rows)==m['rows']==chunk['rows'] and len(rows)>0,'original raw count')
    prev_frame=prev_usec=-1; groups={}; excluded={}
    for row in rows:
        require(None not in row and all(v is not None for v in row.values()),'row width')
        for k in header:
            if k not in text: row[k]=float(row[k]); require(math.isfinite(row[k]),'finite '+k)
        require(row['frame']>prev_frame and row['ticks_usec']>prev_usec,'monotonic frame/time'); prev_frame=row['frame'];prev_usec=row['ticks_usec']
        require(row['measured'] in [0,1],'measured scalar')
        if row['measured']==1:
            require(row['exclusion']=='' and row['interval_usec']>0 and row['collector_usec']>=0 and row['presenter_valid']==row['render_counters_ready']==row['main_auto_process']==1 and row['tree_paused']==0,'valid accepted raw')
            groups.setdefault(row['segment'],[]).append(row)
        else: excluded.setdefault(row['segment'],[]).append(row)
    require(set(groups)==set(LABELS) and sum(map(len,groups.values()))==chunk['accepted'],'all declared accepted rows')
    result=[]; paired=[]
    for index,label_name in enumerate(LABELS):
        s=j['segments'][index];p=j['pair_rows'][index];receipt=s['receipt'];cfg=receipt['configuration'];rr=groups[label_name]
        require(s['label']==p['label']==label_name and s['actual_measured_phase_rows']==len(rr) and 5<=s['actual_seconds']<=30,'sample count and original wall cap')
        minimum=60 if index==0 else 24
        require(receipt['minimum_measured_phase_rows']==minimum and len(rr)>=minimum and receipt['warmup_seconds']==receipt['requested_seconds']==s['requested_seconds']==5 and receipt['wall_limit_seconds']==30,'declared original minima/warmup')
        require(receipt['process_token_normalization']==p['process_token_normalization']==TOKENS,'only three opaque tokens normalized')
        require(p['initial_tick']==253 and p['source_unchanged'] and p['source_sha256']==receipt['source_archive_sha256']==ARCHIVE,'exact original source')
        require(p['restored_frame_sha256']==p['initial_frame_sha256']==cfg['presenter_frame_sha256']==receipt['initial_frame_sha256'],'raw frame restoration in process')
        require(p['restored_signature_sha256']==p['initial_signature_sha256']==receipt['initial_signature_sha256'],'actual rig restoration')
        require(p['restored_canonical_frame_sha256']==p['canonical_frame_sha256']==receipt['canonical_frame_sha256'],'canonical original frame restoration')
        require(p['initial_backend_sha256']==cfg['backend_sha256'],'initial exact backend')
        require(set(p['process_token_values'])==set(TOKENS) and type(p['bound_source_instance']) is int and p['bound_source_instance']!=0 and -(2**63)<=p['bound_source_instance']<2**63 and all(type(v) is int and v==p['bound_source_instance'] for v in p['process_token_values'].values()),'original token type/binding')
        for kind,key in [('canonical-frame','canonical_frame_sha256'),('raw-frame','initial_frame_sha256'),('actual-rig-signature','initial_signature_sha256')]:
            require(sha(root/(label_name+'-'+kind+'.bin'))==p[key],'saved original frame/rig bytes '+kind)
        require(cfg['main_auto_process'] and cfg['presenter_auto_process'] and not cfg['tree_paused'] and cfg['phase']==4 and cfg['policy']=='standard' and cfg['window_width']==1280 and cfg['window_height']==720 and cfg['content_scale']==1 and cfg['max_fps']==cfg['vsync']==cfg['yaw_deg']==0 and cfg['pitch_deg']==35 and cfg['view_size']==12 and cfg['focus']=='(-6.5, 0.0, -0.155217)','common configuration')
        require(all(r['phase']==4 and r['replay']==1 and r['level_id']=='yard' and r['attempt_id']==ATTEMPT and r['policy']=='standard' and r['yaw_deg']==0 and r['pitch_deg']==35 and r['view_size']==12 and r['window_width']==1280 and r['window_height']==720 and r['content_scale']==1 and r['max_fps']==r['vsync']==0 and r['collector_storage_bytes']==15466496 for r in rr),'actual measured source/config')
        first=excluded.get(label_name,[]); require(len(first)==1 and first[0]['exclusion']=='first_frame_after_segment_transition','retained first-frame exclusion')
        warm=excluded.get(label_name+'-warmup',[]); require(len(warm)>1 and warm[-1]['ticks_usec']-warm[0]['ticks_usec']>4_000_000,'retained wall warmup raw')
        if index==0:
            require(not p['advancing'] and p['end_tick']==253 and all(r['frame_seq']==43 and r['wave_id']==0 and r['recorded_phase']==1 and r['playback_tick']==253 and r['local_tick']==204 and r['shot_active']==2 and r['shot_cache']==2 for r in rr),'static exact saved frame and pool')
        else:
            require(p['advancing'] and 253<p['end_tick']<1397 and receipt['speed']==1 and all(r['replay_speed']==1 and 253<=r['playback_tick']<1397 for r in rr),'bounded advancing actual clock')
        normalized=dict(cfg);normalized['presenter_frame_sha256']=p['canonical_frame_sha256']
        paired.append({'configuration':normalized,'source_sha256':p['source_sha256'],'canonical_frame_sha256':p['canonical_frame_sha256'],'rig_signature_sha256':p['initial_signature_sha256'],'backend_sha256':p['initial_backend_sha256']})
        counters={k:distribution([r[k] for r in rr]) for k in COUNTERS}
        result.append({'label':label_name,'accepted':len(rr),'actual_seconds':s['actual_seconds'],'end_tick':p['end_tick'],'counters':counters,'over_33_333ms_fraction':sum(r['interval_usec']>1000000/30 for r in rr)/len(rr),'over_16_667ms_fraction':sum(r['interval_usec']>1000000/60 for r in rr)/len(rr),'rss_mark_bytes':next(x['rss_bytes'] for x in m['segments'] if x['label']==label_name and x['timed'])})
    for capture in j['captures']:
        f=project/capture['path'][6:];require(f.parent==root and sha(f)==capture['sha256'],'actual PNG bytes')
    require(paired[0]==paired[1],'same paused starting input in both windows')
    return {'variant':variant,'label':label,'uuid':uid,'source_sha':source,'tree':tree,'checks':j['checks'],'start':stem.with_suffix('.start').read_text().strip(),'end':stem.with_suffix('.end').read_text().strip(),'raw_rows':len(rows),'accepted':chunk['accepted'],'pair_input':paired[0],'windows':result,'rss_ready_bytes':m['metadata']['rss_ready_bytes'],'rss_save_bytes':m['rss_save_bytes'],'environment':j['environment'],'monitor_support':m['metadata']['monitor_support']},groups

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',action='append',required=True,help='VARIANT:unique-control-label');parser.add_argument('--formal',action='store_true');parser.add_argument('--output',type=pathlib.Path,required=True);args=parser.parse_args()
    runs=[]; groups=[]
    for entry in args.run:
        variant,label=entry.split(':',1);r,g=analyze_run(variant,label);runs.append(r);groups.append(g)
    require(all(r['pair_input']==runs[0]['pair_input'] for r in runs),'all cross-process archive/frame/backend/actual rig/config inputs strictly equal')
    env_keys=['adapter','api_version','audio_driver','cpu','cpu_count','debug_build','display','driver','engine','method','os','os_version','vendor','visible_cpu_effective','visible_cpu_max','visible_memory_max']
    require(all({k:r['environment'][k] for k in env_keys}=={k:runs[0]['environment'][k] for k in env_keys} for r in runs),'common host/engine/backend')
    require(all(date(CONTROL/(runs[i]['label']+'.end'))<=date(CONTROL/(runs[i+1]['label']+'.start')) for i in range(len(runs)-1)),'serial nonoverlapping windows')
    aggregates={};pairs=[];drift=[]
    if args.formal:
        require([r['variant'] for r in runs]==list('ABBABAAB'),'complete declared ABBA/BAAB order')
        for name in LABELS:
            aggregates[name]={}
            for variant in ['A','B']:
                rr=[row for i,r in enumerate(runs) if r['variant']==variant for row in groups[i][name]]
                aggregates[name][variant]={'accepted':len(rr),'counters':{k:distribution([row[k] for row in rr]) for k in COUNTERS},'over_33_333ms_fraction':sum(x['interval_usec']>1000000/30 for x in rr)/len(rr),'over_16_667ms_fraction':sum(x['interval_usec']>1000000/60 for x in rr)/len(rr)}
            for start in [0,2,4,6]:
                pair=runs[start:start+2];a=next(r for r in pair if r['variant']=='A');b=next(r for r in pair if r['variant']=='B');a_window=next(w for w in a['windows'] if w['label']==name);b_window=next(w for w in b['windows'] if w['label']==name)
                pairs.append({'window':name,'order':[r['variant'] for r in pair],'labels':[r['label'] for r in pair],'median_change_percent':100*(b_window['counters']['interval_usec']['median']/a_window['counters']['interval_usec']['median']-1),'a_median_usec':a_window['counters']['interval_usec']['median'],'b_median_usec':b_window['counters']['interval_usec']['median']})
            for variant in ['A','B']:
                ww=[next(w for w in r['windows'] if w['label']==name) for r in runs if r['variant']==variant];v=[w['counters']['interval_usec']['median'] for w in ww]
                drift.append({'window':name,'variant':variant,'run_median_usec':v,'last_vs_first_percent':100*(v[-1]/v[0]-1),'max_vs_min_percent':100*(max(v)/min(v)-1)})
    outcome={'format':1,'status':'valid_formal_repeated_cloud_comparison' if args.formal else 'valid_common_preflight','order':[r['variant'] for r in runs],'fixture_sha256':FIXTURE,'import_metadata_sha256':IMPORTS,'runs':runs,'aggregates':aggregates,'adjacent_pairs':pairs,'drift':drift,'limitations':'59 scalar collector unchanged; frame interval wall postdraw includes all work and instrumentation; monitors may lag; pipeline support unknown/GPU time unavailable; llvmpipe not mobile. Static exact archived input; advancing host-dependent trajectory is separately bounded, not frame-paired/whole replay. Descriptive tails and 4 pairs per variant, no significance/causal/subtractive attribution.'}
    args.output.write_text(json.dumps(outcome,indent=2)+'\n');print(json.dumps({'status':outcome['status'],'order':outcome['order'],'raw':sum(r['raw_rows'] for r in runs),'accepted':sum(r['accepted'] for r in runs),'pairs':pairs,'drift':drift}))
if __name__=='__main__':main()
