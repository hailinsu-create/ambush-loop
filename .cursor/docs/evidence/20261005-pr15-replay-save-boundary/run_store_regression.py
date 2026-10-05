from pathlib import Path
import subprocess,os,datetime,json,re
BASE=Path('/tmp/pr15-web-controls/replay-save-classification-20261005');STAGE=Path('/workspace/pr15-replay-save-stage-1ec-20261005')
argv=['bash',str(STAGE/'scripts/run_isolated_test.sh'),'/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','web_config_store_test.gd','--headless']
env=os.environ.copy();env['AMBUSH_TEST_SOURCE_SHA']='1ec3198e9c0db367af96fc264604c5a286003b5e'
receipt={'argv':argv,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':env['AMBUSH_TEST_SOURCE_SHA']}
with (BASE/'store-regression-request.json').open('x') as f:json.dump(receipt,f,indent=2)
with (BASE/'store-regression.log').open('xb') as f:
 child=subprocess.Popen(argv,env=env,stdout=f,stderr=subprocess.STDOUT)
 try:child.wait(timeout=45);receipt['timed_out']=False
 except subprocess.TimeoutExpired:child.kill();child.wait();receipt['timed_out']=True
log=(BASE/'store-regression.log').read_text();receipt.update({'actual_exit':child.returncode,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'ERROR':len(re.findall('^ERROR:',log,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',log,re.M)),'guard':'TEST_STORAGE_ISOLATED user_dir=' in log})
for n in ['store-regression-receipt.json','store-regression-receipt-vault.json']:
 with (BASE/n).open('x') as f:json.dump(receipt,f,indent=2)
print(json.dumps(receipt));print(log)
assert child.returncode==receipt['ERROR']==receipt['SCRIPT_ERROR']==0 and receipt['guard']
