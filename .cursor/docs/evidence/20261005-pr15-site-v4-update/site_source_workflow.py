from pathlib import Path
import sys,termios,json,subprocess,os,hashlib,datetime,urllib.parse,tarfile
BASE=Path('/tmp/pr15-web-controls/site-update-1ec-20261005')
site=Path('/workspace/sites/ambush-loop-html-game')
fd=sys.stdin.fileno();attrs=termios.tcgetattr(fd);hidden=attrs.copy();hidden[3]&=~termios.ECHO;termios.tcsetattr(fd,termios.TCSANOW,hidden)
print('READY_SITE_SOURCE_JSON_STDIN_HIDDEN',flush=True)
try:
 request=json.loads(sys.stdin.readline());credential=request['credential'];project=request['project_id'];action=request['action']
 assert action in ['open','package']
 assert json.loads((site/'.openai/hosting.json').read_text())['project_id']==project=='appgprj_6ac2e89b4db08191b308c175371ee7c6'
 assert credential['auth_mode']=='http_extra_header' and credential['branch']=='main' and not credential.get('publish_on_push_accepted',False)
 url=urllib.parse.urlparse(credential['remote_url']);assert url.scheme=='https' and url.username is None and url.password is None
 env=os.environ.copy();env.update(GIT_TERMINAL_PROMPT='0',GIT_CONFIG_COUNT='1',GIT_CONFIG_KEY_0='http.extraHeader',GIT_CONFIG_VALUE_0='Authorization: Bearer '+credential['token'])
 rows=[]
 def run(args,auth=False):
  start=datetime.datetime.now(datetime.timezone.utc).isoformat();r=subprocess.run(args,cwd=site,env=env if auth else os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
  rows.append({'argv':args,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actual_exit':r.returncode})
  if r.returncode:raise RuntimeError('Site source command failed; actual_exit='+str(r.returncode))
  return r.stdout.strip()
 old='87cccf2152ce112c36a704efa332f16e7692867b'
 assert run(['git','rev-parse','HEAD'])==old
 assert run(['git','remote','get-url','origin'])==credential['remote_url']
 assert run(['git','ls-remote','origin','refs/heads/main'],True).split()[0]==old
 if action=='open':
  assert not run(['git','status','--porcelain'])
  assert json.loads((site/'BUNDLE-IDENTITY.json').read_text())['game_source_sha']=='8532c4c3084d1a5672bbe28dc96e1c02522a8f05'
  result={'project_id':project,'checkout_path':str(site),'commit_sha':old,'remote_readback_sha':old,'worktree_clean':True,'actual_exit':0,'commands':rows,'helper':'manual exact Git workflow; packaged Sites helper unavailable in selected environment and cloud scripts resource unavailable; existing source maintained','opening_only':True}
  (BASE/'site-source-open.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='commands'}),flush=True)
 else:
  opening=json.loads((BASE/'site-source-open.json').read_text());assert opening['project_id']==project and opening['commit_sha']==old
  assert json.loads((site/'BUNDLE-IDENTITY.json').read_text())['game_source_sha']=='1ec3198e9c0db367af96fc264604c5a286003b5e'
  run(['git','diff','--check']);run(['git','add','--','dist','BUNDLE-IDENTITY.json']);run(['git','commit','-m','Update private game replay progress preservation from verified 1ec3198'])
  sha=run(['git','rev-parse','HEAD']);run(['git','push','origin','HEAD:refs/heads/main'],True)
  remote=run(['git','ls-remote','origin','refs/heads/main'],True).split()[0];assert remote==sha
  archive=Path('/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/ambush-loop-site-v4.tar')
  assert not archive.exists();run(['git','archive','--format=tar','-o',str(archive),sha,'.openai/hosting.json','dist'])
  payload=[]
  with tarfile.open(archive) as t:
   for member in t:
    if member.isfile():
     data=t.extractfile(member).read();assert data==subprocess.check_output(['git','show',sha+':'+member.name],cwd=site)
     payload.append({'path':member.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
  expected=['.openai/hosting.json']+['dist/'+r['path'] for r in json.loads((BASE/'site-package.json').read_text())['files']]
  assert sorted(r['path'] for r in payload)==sorted(expected) and len(payload)==13
  assert not run(['git','status','--porcelain'])
  result={'project_id':project,'commit_sha':sha,'pushed_exact_remote_sha':remote,'archive':str(archive),'archive_bytes':archive.stat().st_size,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'payload':payload,'commands':rows,'actual_exit':0,'publish_on_push_accepted':False,'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','helper':opening['helper'],'deployment_started':False}
  (BASE/'site-source-package.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ['commands','payload']}),flush=True)
finally:termios.tcsetattr(fd,termios.TCSANOW,attrs)
