from pathlib import Path
import subprocess,os,json,hashlib,shutil,datetime,re,struct
ROOT=Path('/workspace/ambush-pr15'); BASE=Path('/tmp/pr15-web-controls/event-log-ui-20261005')
SOURCE=subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip()
PROD=Path('/workspace/pr15-web-stage-event-log-20261005')
STAGE=Path('/workspace/pr15-event-log-qa-stage-20261005');assert not STAGE.exists();shutil.copytree(PROD,STAGE)
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'event-log-cold-qa-20261005';OUT.mkdir()
(STAGE/'qa').mkdir();shutil.copy2(BASE/'event_log_observer.gd',STAGE/'qa/event_log_observer.gd')
raw=ROOT/'.cursor/docs/evidence/20261005-pr15-web-warehouse-single-producer/run/warehouse-record.bin'
assert hashlib.sha256(raw.read_bytes()).hexdigest()=='28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266'
shutil.copy2(raw,STAGE/'qa/warehouse-record.bin')
p=STAGE/'project.godot';p.write_text(p.read_text().replace('[autoload]','[autoload]\n\nEventLogObserver="*res://qa/event_log_observer.gd"',1))
p=STAGE/'export_presets.cfg';p.write_text(p.read_text().replace('include_filter="','include_filter="qa/*.bin,',))
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(BASE/'exports/isolated-data'),'XDG_CONFIG_HOME':str(BASE/'exports/isolated-config'),'XDG_CACHE_HOME':str(BASE/'exports/isolated-cache')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
meta={'source':SOURCE,'stage':str(STAGE),'output':str(OUT),'argv':argv,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'declared one-time cold historical consumer setup plus read-only observer; no runtime mutation API; QA is not production bundle','bridge_sha256':hashlib.sha256((BASE/'event_log_observer.gd').read_bytes()).hexdigest(),'record_sha256':hashlib.sha256(raw.read_bytes()).hexdigest()}
with (BASE/'qa-export.log').open('wb') as log:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=60)
t=(BASE/'qa-export.log').read_text(errors='replace');meta.update({'actual_exit':r.returncode,'ERROR':len(re.findall('^ERROR:',t,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',t,re.M)),'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':[{'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in OUT.iterdir() if p.is_file()]})
(BASE/'qa-export.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta),flush=True)
assert meta['actual_exit']==meta['ERROR']==meta['SCRIPT_ERROR']==0
# Parse all payloads independently; no bytes are reserialized into the archive.
def entries(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 file_base=struct.unpack_from('<Q',b,24)[0];directory=struct.unpack_from('<Q',b,32)[0]
 count=struct.unpack_from('<I',b,directory)[0];p=directory+4;out={}
 for _ in range(count):
  size=struct.unpack_from('<I',b,p)[0];p+=4
  name=b[p:p+size].rstrip(b'\0').decode();p+=size
  offset,nbytes=struct.unpack_from('<QQ',b,p);p+=16
  md5=b[p:p+16];p+=16;flags=struct.unpack_from('<I',b,p)[0];p+=4
  assert flags==0,(name,flags)
  payload=b[file_base+offset:file_base+offset+nbytes]
  assert len(payload)==nbytes and hashlib.md5(payload).digest()==md5,(name,offset,nbytes)
  assert name not in out
  out[name]={'bytes':nbytes,'sha256':hashlib.sha256(payload).hexdigest()}
 return out
old=entries(Path('/workspace/pr15-web-artifacts')/SOURCE/'debug/index.pck');new=entries(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in set(old)&set(new) if old[k]!=new[k])
audit={'source':SOURCE,'added':added,'removed':removed,'changed':changed,'all_payload_md5_verified':True,'old':old,'new':new,'unexpected_added':[k for k in added if k not in ['qa/event_log_observer.gd.remap','qa/event_log_observer.gdc','qa/warehouse-record.bin']],'unexpected_changed':[k for k in changed if k not in ['project.binary','.godot/uid_cache.bin']]}
(BASE/'qa-payload-audit.json').write_text(json.dumps(audit,indent=2)+'\n');print(json.dumps({k:v for k,v in audit.items() if k not in ['old','new']}),flush=True)
assert not removed and not audit['unexpected_added'] and not audit['unexpected_changed']
