from pathlib import Path
R=Path('/tmp/pr15-web-controls/hud-segments-1ec-20261005')
old=Path('/tmp/pr15-web-controls/yard-consumer-1ec-20261005')
s=(old/'browser_controller.py').read_text().replace('yard-consumer-1ec-20261005','hud-segments-1ec-20261005').replace('web-yard-consumer-1ec-20261005','web-hud-segments-1ec-20261005').replace('yard-consumer-qa-20261005','hud-segment-qa-20261005').replace('YARD_WINDOW','HUD_WINDOW').replace('YARD_ENGINE','HUD_ENGINE')
s=s.replace('import json,sys,datetime,threading,traceback,os,time,hashlib','import json,sys,datetime,threading,traceback,os,time,hashlib,signal')
s=s.replace(' OUT.mkdir(exist_ok=False);console_rows=[];', ''' budget=json.loads((CONTROL_ROOT/'budget-start.json').read_text())
 remaining=600-(time.monotonic()-budget['monotonic'])
 assert remaining>0
 def alarm(signum,frame):raise TimeoutError('HUD overall cap600 reached')
 signal.signal(signal.SIGALRM,alarm);signal.setitimer(signal.ITIMER_REAL,remaining)
 OUT.mkdir(exist_ok=False);console_rows=[];''')
s=s.replace("'engine_end':now(),'clean_context_end':clean_end", "'engine_end':now(),'clean_context_end':clean_end,'total_budget_wall_s':time.monotonic()-budget['monotonic']")
s=s.replace("  if close_request:\n", "  signal.setitimer(signal.ITIMER_REAL,0)\n  if close_request:\n")
(R/'browser_controller.py').write_text(s)
(R/'driver_core.py').write_bytes((old/'driver_core.py').read_bytes())
# Pure control preparation; no runtime or profile opened.
