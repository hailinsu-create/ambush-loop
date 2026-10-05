from pathlib import Path
import subprocess,os,json,datetime,uuid,re,hashlib,socket
BASE=Path('/tmp/pr15-web-controls/railcut-native-8532-20261005')
STAGE=Path('/workspace/pr15-web-stage-event-log-20261005')
assert not any('browser' in r and 'railcut' in r for r in subprocess.check_output(['ps','-eo','stat,args'],text=True).splitlines() if not r.split()[0].startswith('Z') and 'python3 /tmp/pr15-web-controls/railcut-native-8532-20261005/run_railcut_offline_audit.py' not in r)
for port in [12815,12816]:
 s=socket.socket();closed=s.connect_ex(('127.0.0.1',port))!=0;s.close();assert closed
rid=uuid.uuid4().hex;run_dir=BASE/'ambush_test_runs'/rid;data=run_dir/'data';data.mkdir(parents=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run_dir/'config'),'XDG_CACHE_HOME':str(run_dir/'cache'),'AMBUSH_TEST_DATA_ROOT':str(data),'AMBUSH_TEST_RUN_ID':rid,'RAILCUT_AUDIT_RECORD':str(BASE/'run-v2/railcut-record.bin'),'RAILCUT_AUDIT_OUTPUT':str(BASE/'railcut-offline-audit-result.json'),'RAILCUT_AUDIT_META':str(BASE/'run-v2/railcut-producer.json')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--headless','--audio-driver','Dummy','--path',str(STAGE),'-s',str(BASE/'railcut_record_readonly_audit.gd')]
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (BASE/'railcut-offline-audit.log').open('wb') as log:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=45)
text=(BASE/'railcut-offline-audit.log').read_text(errors='replace')
receipt={'argv':argv,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':r.returncode,'ERROR':len(re.findall('^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',text,re.M)),'test_storage_guard_passed':'TEST_STORAGE_ISOLATED user_dir=' in text,'data_root':str(data),'loaded_audit_sha256':hashlib.sha256((BASE/'railcut_record_readonly_audit.gd').read_bytes()).hexdigest(),'scope':'non-destructive pure original artifact reader audit; no deleting config or fixture producer; unique private user:// storage guard; sole engine after all producer/consumer browser END'}
(BASE/'railcut-offline-audit-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt),flush=True)
assert receipt['actual_exit']==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and receipt['test_storage_guard_passed']
result=json.loads((BASE/'railcut-offline-audit-result.json').read_text());assert not result['failures'];print(json.dumps(result),flush=True)
