from pathlib import Path
import subprocess,os,json,datetime,uuid,re,hashlib,socket
BASE=Path('/tmp/pr15-final-fresh13-1ec-20261005')
STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005')
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,value):
    blob=(json.dumps(value,indent=2)+'\n').encode()
    with (BASE/name).open('xb') as f:f.write(blob)
    return hashlib.sha256(blob).hexdigest()
assert json.loads((BASE/'yard-browser-end-tool-receipt.json').read_text())['exit_code']==0
assert json.loads((BASE/'run/engine-window-lifecycle.json').read_text())['clean_context_end']
for port in [12815,12816,12817,12915]:
    s=socket.socket();assert s.connect_ex(('127.0.0.1',port))!=0;s.close()
live=[r for r in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not r.split()[0].startswith('Z') and any(k in r.split()[1].lower() for k in ['godot','chromium'])]
assert not live,live
rid=uuid.uuid4().hex;run=BASE/'ambush_test_runs'/rid;data=run/'data';data.mkdir(parents=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache'),'AMBUSH_TEST_DATA_ROOT':str(data),'AMBUSH_TEST_RUN_ID':rid,'FINAL_AUDIT_RECORD':str(BASE/'run/yard-record.bin'),'FINAL_AUDIT_OUTPUT':str(BASE/'yard-offline-audit-result.json'),'FINAL_AUDIT_META':str(BASE/'run/yard-producer.json')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--headless','--audio-driver','Dummy','--path',str(STAGE),'-s',str(BASE/'record_audit.gd')]
receipt={'source':'b74f1fc2f190f574cd0c31aba04e495829337214','argv':argv,'start':now(),'run_id':rid,'data_root':str(data),'loaded_audit_sha256':hashlib.sha256((BASE/'record_audit.gd').read_bytes()).hexdigest(),'scope':'non-destructive original artifact/pure ViewState reader; unique private user:// actual Guard, no cleanup/mutation/producer; sole engine after browser actual END'}
save('yard-offline-audit-request.json',receipt)
with (BASE/'yard-offline-audit.log').open('xb') as log:
    child=subprocess.Popen(argv,env=env,stdout=log,stderr=subprocess.STDOUT);receipt['engine_pid']=child.pid
    try:child.wait(timeout=45);receipt['timed_out']=False
    except subprocess.TimeoutExpired:child.kill();child.wait();receipt['timed_out']=True
text=(BASE/'yard-offline-audit.log').read_text(errors='replace')
receipt.update({'end':now(),'actual_exit':child.returncode,'ERROR':len(re.findall('^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',text,re.M)),'test_storage_guard_passed':'TEST_STORAGE_ISOLATED user_dir=' in text})
h=save('yard-offline-audit-receipt.json',receipt);save('yard-offline-audit-receipt-vault.json',receipt);save('yard-offline-audit-receipt-seal.json',{'sha256':h})
print(json.dumps(receipt),flush=True)
assert receipt['actual_exit']==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and receipt['test_storage_guard_passed']
result=json.loads((BASE/'yard-offline-audit-result.json').read_text());assert not result['failures'];print(json.dumps({k:v for k,v in result.items() if k not in ['original_events','accepted_tools','raw_tool_descriptors']}),flush=True)
