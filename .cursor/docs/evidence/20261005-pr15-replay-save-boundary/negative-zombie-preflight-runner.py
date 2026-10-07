from pathlib import Path
import os,subprocess,uuid,json,datetime,hashlib,re,socket
ROOT=Path('/tmp/pr15-web-controls/replay-save-classification-20261005')
STAGE=Path('/workspace/pr15-web-stage-event-log-20261005')
RECORD=Path('/tmp/pr15-web-controls/railcut-native-8532-20261005/run-v2/railcut-record.bin')
assert hashlib.sha256(RECORD.read_bytes()).hexdigest()=='b50e1f115538933e2e1bdc86402817f1988e6bdbd77525308615c3a96e2bbd3f'
for n in ['main.gd','game_settings.gd']:
 assert (STAGE/'scripts'/n).read_bytes()==(Path('/workspace/ambush-pr15/ambush_loop/scripts')/n).read_bytes()
for port in [12815,12816]:
 s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
active=[x for x in subprocess.check_output(['ps','-eo','pid,comm,args'],text=True).splitlines()[1:] if any(k in x.split(maxsplit=2)[1].lower() for k in ['godot','chromium'])]
assert not active,active
rid=uuid.uuid4().hex;run=ROOT/'ambush_test_runs'/rid;data=run/'data';data.mkdir(parents=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache'),'AMBUSH_TEST_DATA_ROOT':str(data),'AMBUSH_TEST_RUN_ID':rid,'AMBUSH_TEST_SOURCE_SHA':'8532c4c3084d1a5672bbe28dc96e1c02522a8f05','CLASSIFY_RECORD':str(RECORD),'CLASSIFY_RESULT':str(ROOT/'classification-result.json')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--headless','--audio-driver','Dummy','--path',str(STAGE),'-s',str(ROOT/'classify.gd')]
receipt={'argv':argv,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'rid':rid,'loaded_script_sha256':hashlib.sha256((ROOT/'classify.gd').read_bytes()).hexdigest(),'record_sha256':hashlib.sha256(RECORD.read_bytes()).hexdigest(),'scope':'unique private user://, actual StorageGuard; cold/injected handler classification only, no activity in original browser profile'}
with (ROOT/'classification-request.json').open('x') as f:f.write(json.dumps(receipt,indent=2)+'\n')
with (ROOT/'classification.log').open('xb') as f:r=subprocess.run(argv,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=45)
log=(ROOT/'classification.log').read_text();receipt.update({'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':r.returncode,'ERROR':len(re.findall('^ERROR:',log,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',log,re.M)),'guard':'TEST_STORAGE_ISOLATED user_dir=' in log})
blob=(json.dumps(receipt,indent=2)+'\n').encode()
for n in ['classification-receipt.json','classification-receipt-vault.json']:
 with (ROOT/n).open('xb') as f:f.write(blob)
print(json.dumps(receipt));print(log[-2600:])
assert r.returncode==0 and receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and receipt['guard']
