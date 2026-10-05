from pathlib import Path
import subprocess,os,json,hashlib,shutil,tarfile,io,datetime,re
root=Path('/workspace/ambush-pr15');base=Path('/tmp/pr15-web-controls/final-candidate');base.mkdir()
engine=Path('/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64')
source=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
assert source=='843f55c3bc618706d1ddc7aa18d01223927233fc'
stage=Path('/workspace/pr15-web-stage-843f');assert not stage.exists();stage.mkdir()
archive=subprocess.check_output(['git','-C',str(root),'archive',source+':ambush_loop'])
with tarfile.open(fileobj=io.BytesIO(archive)) as t:
 members=[x for x in t.getmembers() if not x.name.endswith('.blend') and not x.name.endswith('.blend.import')]
 t.extractall(stage,members=members,filter='data')
warm=root/'ambush_loop/.godot';shutil.copytree(warm,stage/'.godot')
copied=[]
loader=json.loads(Path('/tmp/pr15-hud-diagnostic/import-sidecars-manifest.json').read_text())
for item in loader['files']:
 p=root/'ambush_loop'/item['path']
 if p.name.endswith('.blend.import'):continue
 q=stage/p.relative_to(root/'ambush_loop')
 if q.exists():assert q.read_bytes()==p.read_bytes()
 else:shutil.copy2(p,q)
 copied.append(str(q.relative_to(stage)))
assert len(copied)==len([x for x in loader['files'] if not x['path'].endswith('.blend.import')])
assert not list(stage.rglob('*.blend'))
data=base/'isolated-data';config=base/'isolated-config';cache=base/'isolated-cache'
template_dir=data/'godot/export_templates/4.7.2.stable';template_dir.mkdir(parents=True,exist_ok=True)
for name in ['version.txt','web_nothreads_debug.zip','web_nothreads_release.zip']:
 shutil.copy2(Path('/workspace/.ambush-loop-env/web/4.7.2/templates')/name,template_dir/name)
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(config),'XDG_CACHE_HOME':str(cache)})
files=[x.decode() for x in subprocess.check_output(['git','-C',str(root),'ls-files','-z','ambush_loop']).split(b'\0') if x]
def proof():return {x:hashlib.sha256((root/x).read_bytes()).hexdigest() for x in files}
before=proof();rows=[]
for mode in ['debug','release']:
 dest=Path('/workspace/pr15-web-artifacts')/source/mode;dest.mkdir(parents=True)
 argv=[str(engine),'--audio-driver','Dummy','--headless','--path',str(stage),'--export-'+mode,'Web Game',str(dest/'index.html')]
 meta={'source':source,'game_tree':subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD:ambush_loop'],text=True).strip(),'mode':mode,'argv':argv,'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'copied_same_byte_existing_project_sidecars':len(copied),'excluded_author_blender_source':'ArtSource/v2/yard_kit.blend and .blend.import; never invoke Blender','full_Title_entry_preserved':True}
 print(json.dumps({'export_start':mode,'source':source,'argv':argv}),flush=True)
 with (base/('export-'+mode+'.log')).open('wb') as log:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT)
 text=(base/('export-'+mode+'.log')).read_text(errors='replace')
 meta.update({'actual_exit':r.returncode,'ERROR':len(re.findall(r'^ERROR:',text,re.M)),'SCRIPT_ERROR':len(re.findall(r'^SCRIPT ERROR:',text,re.M)),'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'files':[{'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dest.rglob('*')) if p.is_file()]})
 (base/('export-'+mode+'.json')).write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta),flush=True);rows.append(meta)
 if r.returncode:break
after=proof();assert before==after
(base/'full-game-source-proof.json').write_text(json.dumps({'source':source,'tracked':len(files),'before':before,'after':after,'unchanged':True,'stage':str(stage),'sidecars':copied},indent=2)+'\n')
assert len(rows)==2 and all(x['actual_exit']==0 and x['ERROR']==0 and x['SCRIPT_ERROR']==0 for x in rows),[(x['mode'],x['actual_exit'],x['ERROR'],x['SCRIPT_ERROR']) for x in rows]
print('FULL_GAME_WEB_EXPORT actual0 debug_and_release source_unchanged',flush=True)
