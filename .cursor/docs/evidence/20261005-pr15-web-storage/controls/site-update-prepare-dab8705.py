from pathlib import Path
import hashlib,json,subprocess,shutil,datetime
root=Path('/workspace/sites/ambush-loop-html-game');candidate=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/site-candidate/dist')
assert subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()=='63642faff970fc8b01e4d54e624fa6ec129c929f'
assert json.loads((root/'BUNDLE-IDENTITY.json').read_text())['game_source_sha']=='bd9218a83047f1452cf8af910eed0f4784ec1335'
allowed={'_headers','game-build.json','index.apple-touch-icon.png','index.audio.position.worklet.js','index.audio.worklet.js','index.html','index.icon.png','index.js','index.pck.part00','index.pck.part01','index.png','index.wasm.gz'}
assert {p.name for p in candidate.iterdir()}==allowed and {p.name for p in (root/'dist').iterdir()}==allowed
build=json.loads((candidate/'game-build.json').read_text());assert build['source_sha']=='dab870595175eed37a6d2a012bc69a76062d48b0'
rows=[]
for p in sorted(candidate.iterdir()):
 assert p.is_file() and p.stat().st_size<=25*1024*1024
 row={'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()};rows.append(row);shutil.copy2(p,root/'dist'/p.name)
identity={'game_source_sha':build['source_sha'],'game_tree':build['game_tree'],'packager_sha':'fa18869bf105a7ccbb65f165438ce2a95169f2e6','packager_file_sha256':'00fb0d067e52a879dcca27d04b5f85e7ba11ed584af3aabf5bc90c7b6b1b7118','total_files':len(rows),'total_bytes':sum(x['bytes'] for x in rows),'scope':'Full Title, all resources; only twelve runtime files. Browser settings/progress checkpoint repair and WebGL Main canvas gate. No QA bridge/records/art source/evidence. No Vercel.','current_candidate':True,'rollback':{'site_commit':'63642faff970fc8b01e4d54e624fa6ec129c929f','game_source':'843f55c3bc618706d1ddc7aa18d01223927233fc','version_id':'appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_75b942a27f1c8191b533de7ebd4a5175','deployment_id':'appgdep_6ac2e9a317d08191b57f795017f0b25a'}}
(root/'BUNDLE-IDENTITY.json').write_text(json.dumps(identity,indent=2)+'\n')
receipt={'prepared_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'identity':identity,'runtime_files':rows,'hosting':json.loads((root/'.openai/hosting.json').read_text()),'archive_allowlist':['.openai/hosting.json']+['dist/'+x['path'] for x in rows]}
Path('/tmp/pr15-web-controls/site-update-prepare-dab8705.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'prepared':True,'files':len(rows),'bytes':identity['total_bytes'],'only_runtime_allowlist':True}))
