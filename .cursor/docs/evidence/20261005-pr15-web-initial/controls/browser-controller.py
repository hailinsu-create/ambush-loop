from pathlib import Path
import subprocess,os,sys,json,datetime
base=Path('/tmp/pr15-web-controls');exe='/workspace/.ambush-loop-env/web-browser/node_modules/.bin/agent-browser'
env=os.environ.copy();env.update({'AGENT_BROWSER_SOCKET_DIR':'/tmp/pr15-web-browser-held','XDG_CONFIG_HOME':'/workspace/.ambush-loop-env/web-browser-config','XDG_CACHE_HOME':'/workspace/.ambush-loop-env/web-browser-cache'})
common=[exe,'--namespace','ambush-pr15-web-held','--session','pr15game543d','--executable-path','/usr/bin/chromium','--profile','/workspace/.ambush-loop-env/web-browser-state-held','--args','--no-sandbox,--disable-dev-shm-usage,--disable-breakpad']
print('READY_BROWSER_CONTROLLER commands JSON {label,args}; owned isolated profile; no shared session',flush=True)
for line in sys.stdin:
 try:
  request=json.loads(line);label=request['label'];args=request['args'];assert '/' not in label and all(isinstance(x,str) for x in args)
  argv=common+args;start=datetime.datetime.now(datetime.timezone.utc).isoformat()
  r=subprocess.run(argv,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=60)
  (base/(label+'.browser.log')).write_text(r.stdout)
  (base/(label+'.browser.json')).write_text(json.dumps({'argv':argv,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':r.returncode},indent=2)+'\n')
  print(json.dumps({'label':label,'actual_exit':r.returncode,'output':r.stdout}),flush=True)
  if args==['close']:break
 except Exception as e:print(json.dumps({'controller_error':type(e).__name__,'detail':str(e)}),flush=True)
