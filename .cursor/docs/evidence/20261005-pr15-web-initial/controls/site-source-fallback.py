from pathlib import Path
import sys,termios,json,subprocess,os,hashlib,datetime,urllib.parse
site=Path('/workspace/sites/ambush-loop-html-game');base=Path('/tmp/pr15-web-controls');fd=sys.stdin.fileno();attrs=termios.tcgetattr(fd);hidden=attrs.copy();hidden[3]&=~termios.ECHO;termios.tcsetattr(fd,termios.TCSANOW,hidden)
print('READY_SITE_SOURCE_JSON_STDIN_HIDDEN',flush=True)
try:
 request=json.loads(sys.stdin.readline());credential=request['credential'];project_id=request['project_id'];assert json.loads((site/'.openai/hosting.json').read_text())['project_id']==project_id
 assert credential['auth_mode']=='http_extra_header';url=urllib.parse.urlparse(credential['remote_url']);assert url.scheme=='https' and url.username is None and url.password is None
 env=os.environ.copy();env.update(GIT_TERMINAL_PROMPT='0',GIT_CONFIG_COUNT='1',GIT_CONFIG_KEY_0='http.extraHeader',GIT_CONFIG_VALUE_0='Authorization: Bearer '+credential['token'])
 rows=[]
 def run(args,capture=False,auth=False):
  start=datetime.datetime.now(datetime.timezone.utc).isoformat();r=subprocess.run(args,cwd=site,env=env if auth else os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
  # Never print provider stderr/headers or credentials. Only fixed args and status.
  rows.append({'argv':args,'actual_exit':r.returncode,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat()})
  if r.returncode:raise RuntimeError('Source command failed: '+args[0]+' '+args[1]+'; actual_exit='+str(r.returncode))
  return r.stdout.strip()
 assert not (site/'.git').exists()
 branch=credential['branch'];run(['git','init','-b',branch]);run(['git','config','user.name','Codex']);run(['git','config','user.email','codex@openai.com']);run(['git','remote','add','origin',credential['remote_url']])
 refs=run(['git','ls-remote','origin','refs/heads/'+branch],auth=True)
 if refs:
  run(['git','fetch','--depth=1','origin',branch],auth=True);run(['git','update-ref','refs/heads/'+branch,'FETCH_HEAD'])
  # Preserve the provider's bootstrap files where our new Site has no file.
  paths=subprocess.check_output(['git','ls-tree','-rz','--name-only','HEAD'],cwd=site).split(b'\0')
  for raw in paths:
   if not raw:continue
   rel=raw.decode();p=site/rel
   if p.exists():continue
   assert p.resolve().is_relative_to(site.resolve());p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(subprocess.check_output(['git','show','HEAD:'+rel],cwd=site))
 run(['git','add','--all']);run(['git','commit','-m','Publish Ambush Loop full HTML game 843f55c with transport fa18869'])
 sha=run(['git','rev-parse','HEAD']);run(['git','push','origin','HEAD:refs/heads/'+branch],auth=True)
 remote=run(['git','ls-remote','origin','refs/heads/'+branch],auth=True).split()[0];assert remote==sha
 archive=Path('/workspace/pr15-web-artifacts/843f55c3bc618706d1ddc7aa18d01223927233fc/ambush-loop-site.tar');run(['git','archive','--format=tar','-o',str(archive),sha,'.openai/hosting.json','dist'])
 result={'project_id':project_id,'commit_sha':sha,'archive':str(archive),'archive_bytes':archive.stat().st_size,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'pushed_exact_remote_sha':remote,'provider':credential['provider'],'branch':branch,'commands':rows,'helper_limit':'Installed skill site-workflow.mjs unavailable; equivalent explicit Git preparation/push/commit archive, credentials stdin/memory only'}
 (base/'site-source-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
except Exception as e:
 (base/'site-source-failure.json').write_text(json.dumps({'type':type(e).__name__,'reason':str(e),'commands':locals().get('rows',[])},indent=2)+'\n');print(json.dumps({'actual_failure':type(e).__name__,'reason':str(e),'credential_not_logged':True}),flush=True);sys.exit(1)
finally:
 termios.tcsetattr(fd,termios.TCSANOW,attrs)
