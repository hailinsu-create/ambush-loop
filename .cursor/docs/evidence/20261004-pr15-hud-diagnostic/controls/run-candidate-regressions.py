import subprocess,json,os,sys
from pathlib import Path
b=Path('/tmp/pr15-hud-diagnostic')
rows=[('candidate-history-H','presentation_contract_test.gd','godot-dummy','--headless'),('candidate-clock-H','command_pose_clock_test.gd','godot-dummy','--headless'),('candidate-equipment-H','equipment_freeze_test.gd','godot-dummy','--headless'),('candidate-old-record-H','visual_snapshot_test.gd','godot-hud-old-record','--headless'),('candidate-lifecycle-R','presentation_lifecycle_test.gd','godot-dummy','--render')]
for label,entry,shim,mode in rows:
 env=os.environ.copy();env.update({'AMBUSH_DIAG_ENGINE':shim,'AMBUSH_DIAG_MODE':mode,'DISPLAY':':127','LIBGL_ALWAYS_SOFTWARE':'1'})
 r=subprocess.run(['python3',str(b/'run-functional.py'),label,entry,'/workspace/ambush-pr15'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 print(r.stdout,flush=True)
 p=b/(label+'.json')
 if r.returncode or not p.exists():sys.exit(r.returncode or 1)
 m=json.loads(p.read_text())
 if m['actual_wrapper_exit'] or m['timed_out'] or m['ERROR'] or m['SCRIPT_ERROR']:sys.exit(1)
print('REGRESSION_DRIVER_COMPLETE all actual0 E0S0',flush=True)
