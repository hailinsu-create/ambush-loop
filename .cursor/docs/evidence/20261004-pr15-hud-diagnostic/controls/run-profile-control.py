import subprocess,json,datetime,sys
from pathlib import Path
b=Path('/tmp/pr15-hud-diagnostic')
assert not (b/'profile-formal.start').exists()
(b/'profile-formal.start').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat()+'\n')
for i,mode in enumerate(['0','1','1','0'],1):
 label='profile-formal-%02d-%s' % (i,'ON' if mode=='1' else 'OFF')
 r=subprocess.run(['python3',str(b/'run-profile.py'),mode,label,'/workspace/ambush-pr15',str(b/'f275-proof.json')],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 print(r.stdout,flush=True)
 (b/(label+'-runner.log')).write_text(r.stdout)
 if r.returncode!=0:sys.exit(r.returncode)
 with (b/(label+'-strict.log')).open('wb') as log:
  v=subprocess.run(['python3',str(b/'analyze_profile_control.py'),'--run',('ON' if mode=='1' else 'OFF')+':'+label,'--output',str(b/(label+'-strict.json'))],stdout=log,stderr=subprocess.STDOUT)
 (b/(label+'-strict.exit')).write_text(str(v.returncode)+'\n')
 if v.returncode!=0:print((b/(label+'-strict.log')).read_text(),flush=True);sys.exit(v.returncode)
 print('STRICT actual0 '+label,flush=True)
(b/'profile-formal.end').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat()+'\n')
(b/'profile-formal.exit').write_text('0\n')
