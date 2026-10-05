from pathlib import Path
import subprocess, os, json, hashlib, shutil, tarfile, io, datetime, re, struct
ROOT=Path('/workspace/ambush-pr15')
BASE=Path('/tmp/pr15-web-controls/fresh-native-dab-20261005')
SOURCE='dab870595175eed37a6d2a012bc69a76062d48b0'
STAGE=Path('/workspace/pr15-fresh-native-stage-dab-20261005')
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'fresh-native-qa-20261005'
ENGINE=Path('/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64')
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*a):return subprocess.check_output(['git','-C',str(ROOT),*a])
def entries(path):
 b=path.read_bytes();assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
 file_base=struct.unpack_from('<Q',b,24)[0];directory=struct.unpack_from('<Q',b,32)[0]
 count=struct.unpack_from('<I',b,directory)[0];p=directory+4;out={}
 for _ in range(count):
  size=struct.unpack_from('<I',b,p)[0];p+=4
  name=b[p:p+size].rstrip(b'\0').decode();p+=size
  offset,nbytes=struct.unpack_from('<QQ',b,p);p+=16
  md5=b[p:p+16];p+=16;flags=struct.unpack_from('<I',b,p)[0];p+=4
  assert flags==0,(name,flags)
  payload=b[file_base+offset:file_base+offset+nbytes]
  assert len(payload)==nbytes and hashlib.md5(payload).digest()==md5,(name,offset,nbytes)
  assert name not in out
  out[name]={'bytes':nbytes,'sha256':hashlib.sha256(payload).hexdigest()}
 return out
start=utc()
assert not STAGE.exists() and not OUT.exists()
assert git('rev-parse',SOURCE+':ambush_loop').decode().strip()=='4f49a7c9cb5a789fbb570bceb947eab7df2eb54a'
STAGE.mkdir();OUT.mkdir(parents=True)
archive=git('archive',SOURCE+':ambush_loop')
with tarfile.open(fileobj=io.BytesIO(archive)) as t:
 members=[m for m in t.getmembers() if not m.name.endswith('.blend') and not m.name.endswith('.blend.import')]
 t.extractall(STAGE,members=members,filter='data')
shutil.copytree('/workspace/pr15-web-stage-dab8705/.godot',STAGE/'.godot')
sidecars=json.loads(Path('/tmp/pr15-hud-diagnostic/import-sidecars-manifest.json').read_text())
copied=[]
for item in sidecars['files']:
 p=ROOT/'ambush_loop'/item['path']
 if p.name.endswith('.blend.import'):continue
 q=STAGE/p.relative_to(ROOT/'ambush_loop')
 if q.exists():assert q.read_bytes()==p.read_bytes()
 else:shutil.copy2(p,q)
 copied.append(str(q.relative_to(STAGE)))
(STAGE/'qa').mkdir()
bridge=BASE/'readonly_campaign_bridge.gd';shutil.copy2(bridge,STAGE/'qa'/bridge.name)
project=STAGE/'project.godot';original=project.read_text()
assert 'FreshObserver' not in original
project.write_text(original.replace('[autoload]','[autoload]\n\nFreshObserver="*res://qa/readonly_campaign_bridge.gd"',1))
data=BASE/'isolated-data';config=BASE/'isolated-config';cache=BASE/'isolated-cache'
templates=data/'godot/export_templates/4.7.2.stable';templates.mkdir(parents=True)
for name in ['version.txt','web_nothreads_debug.zip']:
 shutil.copy2(Path('/workspace/.ambush-loop-env/web/4.7.2/templates')/name,templates/name)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(config),'XDG_CACHE_HOME':str(cache)})
tracked=[x.decode() for x in git('ls-tree','-r','--name-only','-z',SOURCE,'ambush_loop').split(b'\0') if x]
before={x:sha(ROOT/x) for x in tracked}
source_proof=[]
for full in tracked:
 rel=Path(full).relative_to('ambush_loop')
 if str(rel).endswith(('.blend','.blend.import')):continue
 if str(rel)=='project.godot':assert git('show',SOURCE+':'+full).decode()==original
 else:assert (STAGE/rel).read_bytes()==git('show',SOURCE+':'+full),full
 source_proof.append(full)
argv=[str(ENGINE),'--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
meta={'source':SOURCE,'tree':'4f49a7c9cb5a789fbb570bceb947eab7df2eb54a','start':start,'argv':argv,'bridge_sha256':sha(bridge),'stage':str(STAGE),'output':str(OUT),'production_source_verified':len(source_proof),'same_byte_sidecars':len(copied),'scope':'original full Title production source plus external read-only observer; fixture PCK identity is separate'}
print(json.dumps({'fixture_export_START':utc(),'argv':argv}),flush=True)
with (BASE/'export.log').open('wb') as log:
 try:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=45);code=r.returncode
 except subprocess.TimeoutExpired:code=124
logtext=(BASE/'export.log').read_text(errors='replace')
meta.update({'end':utc(),'actual_exit':code,'ERROR':len(re.findall('^ERROR:',logtext,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',logtext,re.M)),'production_worktree_unchanged':before=={x:sha(ROOT/x) for x in tracked}})
(BASE/'export.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta),flush=True)
assert code==0 and meta['ERROR']==0 and meta['SCRIPT_ERROR']==0 and meta['production_worktree_unchanged']
old=entries(Path('/workspace/pr15-web-artifacts')/SOURCE/'debug/index.pck')
new=entries(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in set(old)&set(new) if old[k]!=new[k])
allowed_changed={'project.binary','.godot/global_script_class_cache.cfg','.godot/uid_cache.bin'}
allowed_added=lambda name:name.startswith('qa/readonly_campaign_bridge.')
audit={'source':SOURCE,'original_debug_pck':{'bytes':38082080,'sha256':sha(Path('/workspace/pr15-web-artifacts')/SOURCE/'debug/index.pck')},'fixture_pck':{'bytes':(OUT/'index.pck').stat().st_size,'sha256':sha(OUT/'index.pck')},'original_entries':len(old),'fixture_entries':len(new),'all_payload_md5_verified':True,'added':added,'removed':removed,'changed':changed,'unexpected_added':[x for x in added if not allowed_added(x)],'unexpected_changed':[x for x in changed if x not in allowed_changed],'old':old,'new':new}
(BASE/'pck-payload-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps({k:v for k,v in audit.items() if k not in ['old','new']}),flush=True)
assert not removed and not audit['unexpected_added'] and not audit['unexpected_changed']
