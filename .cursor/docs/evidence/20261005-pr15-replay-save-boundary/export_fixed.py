from pathlib import Path
import subprocess,os,uuid,datetime,json,hashlib,re,shutil,struct
BASE=Path('/tmp/pr15-web-controls/replay-save-classification-20261005');SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e';STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005');OUT=Path('/workspace/pr15-web-artifacts')/SOURCE
assert not OUT.exists();OUT.mkdir()
QA=Path('/workspace/pr15-replay-save-qa-stage-1ec-20261005');assert not QA.exists();shutil.copytree('/workspace/pr15-event-log-qa-stage-v2-20261005',QA)
for name in ['scripts/main.gd','scripts/replay_progress_save_test.gd','scripts/run_isolated_test.sh','scripts/run_isolated_test.ps1']:shutil.copy2(STAGE/name,QA/name)
assert (QA/'qa/warehouse-record.bin').read_bytes()==Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-web-warehouse-single-producer/run/warehouse-record.bin').read_bytes()
rid=uuid.uuid4().hex;run=BASE/'ambush_test_runs'/rid;data=run/'data';(data/'godot').mkdir(parents=True)
(data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache')})
for mode,stage in [('debug',STAGE),('event-log-cold-qa-v2-20261005',QA)]:
 dest=OUT/mode;dest.mkdir()
 argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(stage),'--export-debug','Web Game',str(dest/'index.html')]
 receipt={'source':SOURCE,'mode':mode,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'argv':argv,'isolated_data':str(data),'scope':'official 4.7.2 full Title export from existing cached resources; no asset source generator/atlas/GLB/Blender rebuild'}
 with (BASE/('export-'+mode+'-request.json')).open('x') as f:json.dump(receipt,f,indent=2)
 with (BASE/('export-'+mode+'.log')).open('xb') as f:
  child=subprocess.Popen(argv,env=env,stdout=f,stderr=subprocess.STDOUT);receipt['engine_pid']=child.pid
  try:child.wait(timeout=60);receipt['timed_out']=False
  except subprocess.TimeoutExpired:child.kill();child.wait();receipt['timed_out']=True
 text=(BASE/('export-'+mode+'.log')).read_text();receipt.update({'actual_exit':child.returncode,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'ERROR':len(re.findall('^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',text,re.M)),'files':[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dest.iterdir()) if p.is_file()]})
 for suffix in ['-receipt.json','-receipt-vault.json']:
  with (BASE/('export-'+mode+suffix)).open('x') as f:json.dump(receipt,f,indent=2)
 print(json.dumps({k:v for k,v in receipt.items() if k!='files'}),flush=True)
 assert child.returncode==receipt['ERROR']==receipt['SCRIPT_ERROR']==0

def entries(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 base=struct.unpack_from('<Q',b,24)[0];pos=struct.unpack_from('<Q',b,32)[0];count=struct.unpack_from('<I',b,pos)[0];pos+=4;out={}
 for _ in range(count):
  n=struct.unpack_from('<I',b,pos)[0];pos+=4;name=b[pos:pos+n].rstrip(b'\0').decode();pos+=n
  off,size=struct.unpack_from('<QQ',b,pos);pos+=16;md5=b[pos:pos+16];pos+=16;flags=struct.unpack_from('<I',b,pos)[0];pos+=4;assert flags==0
  data=b[base+off:base+off+size];assert len(data)==size and hashlib.md5(data).digest()==md5
  out[name]={'bytes':size,'sha256':hashlib.sha256(data).hexdigest()}
 return out
old=entries(Path('/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-cold-qa-v2-20261005/index.pck'))
prod=entries(OUT/'debug/index.pck');qa=entries(OUT/'event-log-cold-qa-v2-20261005/index.pck')
report={'source':SOURCE,'all_payload_md5_verified':True,'qa_vs_old':{'added':sorted(set(qa)-set(old)),'removed':sorted(set(old)-set(qa)),'changed':sorted(k for k in set(old)&set(qa) if old[k]!=qa[k])},'qa_vs_production':{'added':sorted(set(qa)-set(prod)),'removed':sorted(set(prod)-set(qa)),'changed':sorted(k for k in set(prod)&set(qa) if prod[k]!=qa[k])},'old':old,'production':prod,'qa':qa}
(BASE/'fixed-payload-audit.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k not in ['old','production','qa']}),flush=True)
