from pathlib import Path
import subprocess,os,json,datetime,uuid,re,time,socket,hashlib,sys,struct
R=Path('/tmp/pr15-web-controls/replay-touch-abba-95daa-20261005')
G='/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64'
ART=Path('/workspace/pr15-web-artifacts/95daa05d0ccfc4e6bd357060b1f34c2a863c2041/touch-abba-qa-20261005')
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,obj):
 with (R/name).open('x') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
for port in [12815,12816,12817]:
 with socket.socket() as s:assert s.connect_ex(('127.0.0.1',port))!=0
live=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(z in x.split()[1].lower() for z in ['godot','chromium'])];assert not live,live
save('budget-start.json',{'utc':utc(),'monotonic':time.monotonic(),'cap_s':600,'scope':'two cached QA exports + fresh A P0 <=120 + ABBA four isolated fresh serial contexts/common OFF/static and advance + owned END, no reset or extension'})
def child(label,argv,env,cap):
 packet={'label':label,'start':utc(),'argv':argv,'cap_s':cap};save(label+'-request.json',packet)
 with (R/(label+'.log')).open('xb') as log:
  p=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT);packet['pid']=p.pid
  try:p.wait(timeout=cap);packet['timeout']=False
  except subprocess.TimeoutExpired:p.terminate();p.wait(timeout=15);packet['timeout']=True
 text=(R/(label+'.log')).read_text();packet.update(end=utc(),actual_exit=p.returncode,ERROR=len(re.findall('^ERROR:',text,re.M)),SCRIPT_ERROR=len(re.findall('^SCRIPT ERROR:',text,re.M)))
 save(label+'-receipt.json',packet);print(json.dumps(packet),flush=True)
 assert packet['actual_exit']==packet['ERROR']==packet['SCRIPT_ERROR']==0 and not packet['timeout']
for side in ['A','B']:
 rid=uuid.uuid4().hex;runroot=R/'ambush_test_runs'/rid;data=runroot/'data';(data/'godot').mkdir(parents=True)
 (data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
 env=os.environ.copy();env.update(XDG_DATA_HOME=str(data),XDG_CONFIG_HOME=str(runroot/'config'),XDG_CACHE_HOME=str(runroot/'cache'),AMBUSH_TEST_RUN_ID=rid,AMBUSH_TEST_DATA_ROOT=str(data))
 export=ART/side;export.mkdir(parents=True,exist_ok=False)
 child('export-'+side,[G,'--headless','--audio-driver','Dummy','--path','/workspace/pr15-replay-touch-qa-'+side+'-95daa-20261005','--export-debug','Web Game',str(export/'index.html')],env,60)
 save('export-'+side+'-payloads.json',[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(export.iterdir()) if p.is_file()])
def read(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 base=struct.unpack_from('<Q',b,24)[0];d=struct.unpack_from('<Q',b,32)[0];n=struct.unpack_from('<I',b,d)[0];p=d+4;out={}
 for i in range(n):
  length=struct.unpack_from('<I',b,p)[0];p+=4;name=b[p:p+length].rstrip(b'\0').decode();p+=length
  offset,size=struct.unpack_from('<QQ',b,p);p+=16;md5=b[p:p+16];p+=16;p+=4
  payload=b[base+offset:base+offset+size];assert len(payload)==size and hashlib.md5(payload).digest()==md5
  out[name]={'bytes':size,'sha256':hashlib.sha256(payload).hexdigest()}
 return out
a=read(ART/'A/index.pck');b=read(ART/'B/index.pck');old=read(Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/hud-subsegment-qa-20261005/index.pck'))
assert a.keys()==b.keys()==old.keys()
changed=[k for k in a if a[k]!=b[k]];common=[k for k in old if old[k]!=a[k]]
assert set(changed)<=set(['scripts/main.gdc','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'])
assert set(common)<=set(['qa/event_log_observer.gdc','.godot/uid_cache.bin','.godot/global_script_class_cache.cfg'])
save('pck-payload-audit.json',{'actual_exit':0,'payload_count':len(a),'A_B_changed':changed,'sealed_QA_to_A_changed':common,'all_payload_md5_verified':True,'all_other_payloads_and_assets_byte_exact':True})
child('browser',[sys.executable,str(R/'browser.py')],os.environ.copy(),610)
