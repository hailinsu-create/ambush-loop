from pathlib import Path
import sys,termios,json,subprocess,os,hashlib,datetime,urllib.parse,tarfile
site=Path('/workspace/sites/ambush-loop-html-game');out=Path('/tmp/pr15-web-controls/site-update-dab8705');out.mkdir(exist_ok=False)
fd=sys.stdin.fileno();attrs=termios.tcgetattr(fd);hidden=attrs.copy();hidden[3]&=~termios.ECHO;termios.tcsetattr(fd,termios.TCSANOW,hidden)
print('READY_SITE_UPDATE_CREDENTIAL_STDIN_HIDDEN',flush=True)
try:
 request=json.loads(sys.stdin.readline());credential=request['credential'];project_id=request['project_id']
 assert json.loads((site/'.openai/hosting.json').read_text())['project_id']==project_id
 assert credential['auth_mode']=='http_extra_header' and credential['branch']=='main' and not credential.get('publish_on_push_accepted',False)
 url=urllib.parse.urlparse(credential['remote_url']);assert url.scheme=='https' and url.username is None and url.password is None
 env=os.environ.copy();env.update(GIT_TERMINAL_PROMPT='0',GIT_CONFIG_COUNT='1',GIT_CONFIG_KEY_0='http.extraHeader',GIT_CONFIG_VALUE_0='Authorization: Bearer '+credential['token'])
 rows=[]
 def run(args,auth=False):
  start=datetime.datetime.now(datetime.timezone.utc).isoformat();r=subprocess.run(args,cwd=site,env=env if auth else os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
  rows.append({'argv':args,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':r.returncode})
  if r.returncode:raise RuntimeError('Site source command failed; actual_exit='+str(r.returncode))
  return r.stdout.strip()
 assert run(['git','rev-parse','HEAD'])=='63642faff970fc8b01e4d54e624fa6ec129c929f'
 assert run(['git','remote','get-url','origin'])==credential['remote_url']
 assert run(['git','ls-remote','origin','refs/heads/main'],True).split()[0]=='63642faff970fc8b01e4d54e624fa6ec129c929f'
 run(['git','add','--','dist','BUNDLE-IDENTITY.json']);run(['git','commit','-m','Publish browser save and WebGL repairs from dab8705'])
 sha=run(['git','rev-parse','HEAD']);run(['git','push','origin','HEAD:refs/heads/main'],True)
 remote=run(['git','ls-remote','origin','refs/heads/main'],True).split()[0];assert remote==sha
 archive=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/ambush-loop-site.tar')
 run(['git','archive','--format=tar','-o',str(archive),sha,'.openai/hosting.json','dist'])
 payload=[]
 with tarfile.open(archive) as t:
  for member in t:
   if member.isfile():
    data=t.extractfile(member).read();assert data==subprocess.check_output(['git','show',sha+':'+member.name],cwd=site)
    payload.append({'path':member.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
 assert len(payload)==13 and '.openai/hosting.json' in [x['path'] for x in payload]
 result={'project_id':project_id,'site_commit':sha,'pushed_exact_remote_sha':remote,'archive':str(archive),'archive_bytes':archive.stat().st_size,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'payload':payload,'commands':rows,'publish_on_push_accepted':False,'source':'dab870595175eed37a6d2a012bc69a76062d48b0'}
 (out/'push-archive.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ['commands','payload']}),flush=True)
finally:termios.tcsetattr(fd,termios.TCSANOW,attrs)
