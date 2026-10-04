import subprocess,json,datetime,sys
from pathlib import Path
b=Path('/tmp/pr15-hud-diagnostic');assert not (b/'batch-formal.start').exists()
(b/'batch-formal.start').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat()+'\n')
entries=[]
for i,variant in enumerate('ABBABAAB',1):
 label='batch-formal-%02d-%s' % (i,variant)
 root='/workspace/pr15-hud-baseline-f275' if variant=='A' else '/workspace/ambush-pr15'
 proof=b/('baseline-f275-proof.json' if variant=='A' else 'candidate-541d-proof.json')
 r=subprocess.run(['python3',str(b/'run-batch-pair.py'),variant,label,root,str(proof)],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (b/(label+'-runner.log')).write_text(r.stdout);print(r.stdout,flush=True)
 if r.returncode:sys.exit(r.returncode)
 with (b/(label+'-strict.log')).open('wb') as log:
  v=subprocess.run(['python3',str(b/'analyze_batch_pair.py'),'--run',variant+':'+label,'--output',str(b/(label+'-strict.json'))],stdout=log,stderr=subprocess.STDOUT)
 (b/(label+'-strict.exit')).write_text(str(v.returncode)+'\n')
 if v.returncode:print((b/(label+'-strict.log')).read_text(),flush=True);sys.exit(v.returncode)
 entries+=['--run',variant+':'+label];print('STRICT actual0 '+label,flush=True)
with (b/'batch-formal-strict.log').open('wb') as log:
 v=subprocess.run(['python3',str(b/'analyze_batch_pair.py'),'--formal',*entries,'--output',str(b/'batch-formal-strict.json')],stdout=log,stderr=subprocess.STDOUT)
(b/'batch-formal-strict.exit').write_text(str(v.returncode)+'\n')
(b/'batch-formal.end').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat()+'\n');(b/'batch-formal.exit').write_text(str(v.returncode)+'\n')
print('FORMAL complete actual '+str(v.returncode),flush=True);sys.exit(v.returncode)
