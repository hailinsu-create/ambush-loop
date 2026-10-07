from pathlib import Path
import json, shutil, os, subprocess, datetime, re, hashlib
BASE=Path('/tmp/pr15-web-controls/fresh-native-dab-20261005')
STAGE=Path('/workspace/pr15-fresh-native-stage-dab-20261005')
PROD_STAGE=Path('/workspace/pr15-web-stage-dab8705')
OUT=Path('/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/fresh-native-qa-aligned-20261005');assert not OUT.exists();OUT.mkdir()
rows=json.loads((BASE/'fixture-identity-acceptance.json').read_text())['uid_only_import_metadata']
for row in rows:
 a=PROD_STAGE/row['path'];b=STAGE/row['path'];assert a.exists() and b.exists();shutil.copy2(a,b)
shutil.copy2(PROD_STAGE/'.godot/uid_cache.bin',STAGE/'.godot/uid_cache.bin')
env=os.environ.copy();env.update({'XDG_DATA_HOME':str(BASE/'isolated-data'),'XDG_CONFIG_HOME':str(BASE/'isolated-config'),'XDG_CACHE_HOME':str(BASE/'isolated-cache')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
meta={'argv':argv,'source':'dab870595175eed37a6d2a012bc69a76062d48b0','start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'copied_existing_production_stage_import_UID_metadata':len(rows),'not_asset_generation':True}
with (BASE/'aligned-export.log').open('wb') as log:r=subprocess.run(argv,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=45)
t=(BASE/'aligned-export.log').read_text(errors='replace')
meta.update({'actual_exit':r.returncode,'ERROR':len(re.findall('^ERROR:',t,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',t,re.M)),'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pck_sha256':hashlib.sha256((OUT/'index.pck').read_bytes()).hexdigest(),'pck_bytes':(OUT/'index.pck').stat().st_size})
(BASE/'aligned-export.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta))
assert r.returncode==0 and meta['ERROR']==meta['SCRIPT_ERROR']==0
exec((BASE/'audit_uid_metadata.py').read_text().split('old=read(')[0],globals())
old=read(ART/'debug/index.pck');new=read(OUT/'index.pck')
added=sorted(set(new)-set(old));removed=sorted(set(old)-set(new));changed=sorted(k for k in set(old)&set(new) if old[k]!=new[k])
receipt={'actual_exit':0,'added':added,'removed':removed,'changed':changed,'all_original_payloads_equal_except_registration_uid_cache':True,'source':meta['source'],'pck_sha256':meta['pck_sha256'],'pck_bytes':meta['pck_bytes'],'entries':len(new),'all_payload_MD5_verified':True}
(BASE/'aligned-payload-audit.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt))
assert not removed and changed==['.godot/uid_cache.bin','project.binary']
assert added==['qa/readonly_campaign_bridge.gd.remap','qa/readonly_campaign_bridge.gdc']
