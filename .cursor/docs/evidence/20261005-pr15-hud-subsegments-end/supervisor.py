from pathlib import Path
import subprocess,json,datetime,hashlib,sys
R=Path('/tmp/pr15-web-controls/hud-subsegments-1ec-20261005')
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def run(label,script):
 receipt={'start':utc(),'script':str(script),'script_sha256':hashlib.sha256(script.read_bytes()).hexdigest(),'argv':[sys.executable,str(script)]}
 with (R/(label+'-supervisor-request.json')).open('x') as f:json.dump(receipt,f,indent=2)
 child=subprocess.Popen(receipt['argv']);receipt['pid']=child.pid
 try:child.wait(timeout=610 if label=='browser' else 130);receipt['timeout']=False
 except subprocess.TimeoutExpired:child.terminate();child.wait(timeout=15);receipt['timeout']=True
 receipt.update({'end':utc(),'actual_exit':child.returncode})
 with (R/(label+'-supervisor-receipt.json')).open('x') as f:json.dump(receipt,f,indent=2)
 print(json.dumps({'SUPERVISOR_END':label,**receipt}),flush=True);assert child.returncode==0 and not receipt['timeout']
run('native-export',R/'run_native_export.py')
run('pck-audit',R/'audit_pck.py')
run('browser',R/'browser_controller.py')
