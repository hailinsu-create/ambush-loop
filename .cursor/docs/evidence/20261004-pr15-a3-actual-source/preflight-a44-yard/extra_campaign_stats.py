#!/usr/bin/env python3
"""Supplement the strict analyzer with p99/budget exceedance and original RSS marks."""
import argparse,csv,hashlib,json,pathlib,statistics

def pct(v,q):
 s=sorted(v);p=(len(s)-1)*q;i=int(p);return s[i]+(s[min(i+1,len(s)-1)]-s[i])*(p-i)
p=argparse.ArgumentParser();p.add_argument('--report',type=pathlib.Path,required=True);p.add_argument('--strict',type=pathlib.Path,required=True);p.add_argument('--root',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args();j=json.loads(a.report.read_text());strict=json.loads(a.strict.read_text());assert strict['status']=='valid_original_cloud_workload' and strict['source_sha']==j['source_sha'];result={'format':1,'source_sha':j['source_sha'],'strict_analysis_sha256':hashlib.sha256(a.strict.read_bytes()).hexdigest(),'segments':[],'chunks':[],'scope':'Same original strict-validated raw; cloud interval thresholds describe this llvmpipe workload, not Android performance. RSS marks include collector/driver/archives/cache and sampling/metadata overhead; no leak or isolated-GPU claim.'}
for c in j['chunks']:
 d=a.root/'ambush_loop'/c['path'][6:];assert hashlib.sha256((d/'raw.csv').read_bytes()).hexdigest()==c['raw_sha256'];m=json.loads((d/'metadata.json').read_text());rows=list(csv.DictReader((d/'raw.csv').open()));accepted=[r for r in rows if float(r['measured'])==1];groups={}
 for r in accepted:groups.setdefault(r['segment'],[]).append(r)
 for s in m['extra']['segments']:
  if s['label'] not in groups:continue
  rs=groups[s['label']];phase=s['receipt'].get('phase');rs=[r for r in rs if phase is None or float(r['phase'])==phase];v=[float(r['interval_usec'])/1000 for r in rs]
  result['segments'].append({'label':s['label'],'samples':len(v),'actual_seconds':s['actual_seconds'],'interval_ms':{'median':statistics.median(v),'p95':pct(v,.95),'p99':pct(v,.99),'max':max(v)},'fraction_over33_333ms':sum(x>1000/30 for x in v)/len(v),'fraction_over16_667ms':sum(x>1000/60 for x in v)/len(v),'median_interval_inverse_fps':1000/statistics.median(v),'scope':'inverse median raw cadence includes instrumentation; no subtraction of collector time or exclusive GPU benchmark'})
 counters=['MEMORY_STATIC','OBJECT_COUNT','OBJECT_NODE_COUNT','OBJECT_RESOURCE_COUNT','OBJECT_ORPHAN_NODE_COUNT','RENDER_TEXTURE_MEM_USED','RENDER_BUFFER_MEM_USED','RENDER_VIDEO_MEM_USED']
 result['chunks'].append({'path':c['path'],'collector_storage_bytes':float(rows[0]['collector_storage_bytes']),'rss_ready_bytes':m['metadata']['rss_ready_bytes'],'rss_save_bytes':m['rss_save_bytes'],'raw_supported_counter_extrema':{k:{'first':float(rows[0][k]),'last':float(rows[-1][k]),'max':max(float(r[k]) for r in rows)} for k in counters},'original_rss_marks':[{k:s[k] for k in ['label','timed','ticks_usec','rss_bytes']} for s in m['segments']]})
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'segments':len(result['segments']),'chunks':len(result['chunks']),'output':str(a.output)}))
