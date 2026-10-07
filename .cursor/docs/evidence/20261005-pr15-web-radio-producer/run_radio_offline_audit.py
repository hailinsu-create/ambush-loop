from pathlib import Path
import subprocess,os,json,datetime,uuid,re,hashlib,socket
BASE=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005')
STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005')
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,value):
    blob=(json.dumps(value,indent=2)+'\n').encode()
    with (BASE/name).open('xb') as f:f.write(blob)
    return hashlib.sha256(blob).hexdigest()
assert json.loads((BASE/'browser-end-tool-receipt.json').read_text())['exit_code']==0
assert json.loads((BASE/'run/engine-window-lifecycle.json').read_text())['clean_context_end']
for port in [12815,12816,12817]:
    s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
live=[r for r in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not r.split()[0].startswith('Z') and any(k in r.split()[1].lower() for k in ['godot','chromium'])]
assert not live,live
rid=uuid.uuid4().hex;run=BASE/'ambush_test_runs'/rid;data=run/'data';data.mkdir(parents=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache'),'AMBUSH_TEST_DATA_ROOT':str(data),'AMBUSH_TEST_RUN_ID':rid,'RADIO_AUDIT_RECORD':str(BASE/'run/radio-record.bin'),'RADIO_AUDIT_OUTPUT':str(BASE/'radio-offline-audit-result.json'),'RADIO_AUDIT_META':str(BASE/'run/radio-producer.json')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--headless','--audio-driver','Dummy','--path',str(STAGE),'-s',str(BASE/'radio_record_readonly_audit.gd')]
receipt={'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','argv':argv,'start':now(),'run_id':rid,'data_root':str(data),'loaded_audit_sha256':hashlib.sha256((BASE/'radio_record_readonly_audit.gd').read_bytes()).hexdigest(),'scope':'non-destructive original artifact/pure ViewState reader; unique private user:// actual Guard, no cleanup/mutation/producer; sole engine after browser actual END'}
save('radio-offline-audit-request.json',receipt)
with (BASE/'radio-offline-audit.log').open('xb') as log:
    child=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT);receipt['engine_pid']=child.pid
    try:child.wait(timeout=45);receipt['timed_out']=False
    except subprocess.TimeoutExpired:child.kill();child.wait();receipt['timed_out']=True
text=(BASE/'radio-offline-audit.log').read_text(errors='replace')
receipt.update({'end':now(),'actual_exit':child.returncode,'ERROR':len(re.findall('^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',text,re.M)),'test_storage_guard_passed':'TEST_STORAGE_ISOLATED user_dir=' in text})
h=save('radio-offline-audit-receipt.json',receipt);save('radio-offline-audit-receipt-vault.json',receipt);save('radio-offline-audit-receipt-seal.json',{'sha256':h})
print(json.dumps(receipt),flush=True)
assert receipt['actual_exit']==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and receipt['test_storage_guard_passed']
result=json.loads((BASE/'radio-offline-audit-result.json').read_text());assert not result['failures'];print(json.dumps(result),flush=True)
