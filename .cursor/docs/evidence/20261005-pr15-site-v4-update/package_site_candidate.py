from pathlib import Path
import subprocess,json,hashlib,gzip,re,datetime
ROOT=Path('/workspace/ambush-pr15');BASE=Path('/tmp/pr15-web-controls/site-update-1ec-20261005')
SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e';TREE='1e8af45ee23098f763acc139b56f8f7e0f41665a'
EXPORT=Path('/workspace/pr15-web-artifacts')/SOURCE/'release'
DEST=Path('/workspace/pr15-web-artifacts')/SOURCE/'site-candidate/dist'
manifest=json.loads((BASE/'export-receipt.json').read_text());manifest['game_tree']=TREE
assert manifest['source']==SOURCE and manifest['game_tree']==TREE and manifest['actual_exit']==manifest['ERROR']==manifest['SCRIPT_ERROR']==0
for row in manifest['files']:
 p=EXPORT/Path(row['path']).name;assert p.stat().st_size==row['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],p
packager=ROOT/'ambush_loop/tools/package_web_site.py';assert hashlib.sha256(packager.read_bytes()).hexdigest()=='00fb0d067e52a879dcca27d04b5f85e7ba11ed584af3aabf5bc90c7b6b1b7118'
argv=['python3',str(packager),str(EXPORT),str(DEST),'--source-sha',SOURCE,'--game-tree',TREE]
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
result=subprocess.run(argv,capture_output=True,text=True);(BASE/'site-package.log').write_text(result.stdout+result.stderr)
assert result.returncode==0
data=json.loads((DEST/'game-build.json').read_text())
allowed={'_headers','game-build.json','index.apple-touch-icon.png','index.audio.position.worklet.js','index.audio.worklet.js','index.html','index.icon.png','index.js','index.pck.part00','index.pck.part01','index.png','index.wasm.gz'}
assert {p.name for p in DEST.iterdir()}==allowed
raw=b''.join((DEST/r['path']).read_bytes() for r in data['pck']['parts'])
assert raw==(EXPORT/'index.pck').read_bytes() and hashlib.sha256(raw).hexdigest()=='0eabd893591bc97c6e7ad897e370759ba58b6e36419d47e80a0aefce638c6523'
assert gzip.decompress((DEST/'index.wasm.gz').read_bytes())==(EXPORT/'index.wasm').read_bytes()
html=(DEST/'index.html').read_text();assert html.count('engine.startGame(')==1 and 'pr15Observer' not in html
inline=re.findall(r'<script(?:[^>]*)>(.*?)</script>',html,re.S)
checks=[]
for i,script in enumerate(inline):
 if not script.strip():continue
 p=BASE/f'site-inline-{i}.js';p.write_text(script);check=subprocess.run(['node','--check',str(p)],capture_output=True,text=True);assert check.returncode==0,check.stderr;checks.append({'argv':['node','--check',str(p)],'actual_exit':check.returncode})
checks.append({'argv':['node','--check',str(DEST/'index.js')],'actual_exit':subprocess.run(['node','--check',str(DEST/'index.js')],capture_output=True).returncode});assert checks[-1]['actual_exit']==0
files=[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(DEST.iterdir())]
assert len(files)==12 and all(r['bytes']<=25*1024*1024 for r in files)
receipt={'source':SOURCE,'game_tree':TREE,'argv':argv,'actual_exit':result.returncode,'start':start,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'production_manifest_rehashed':True,'full_Title_entry':True,'packager_unchanged':True,'original_pck_reassembled_exact':True,'original_wasm_decompressed_exact':True,'all_stored_files_under_25MiB':True,'files':files,'total_files':len(files),'total_bytes':sum(r['bytes'] for r in files),'checks':checks,'production_candidate_only':True,'qa_bridge_records_excluded':True,'site_modified':False,'deployed':False,'scope':'prepare proven production release source8532 with unchanged transport; one authorized official production release export; no asset generation'}
(BASE/'site-package.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k not in ['files','checks']}),flush=True)
