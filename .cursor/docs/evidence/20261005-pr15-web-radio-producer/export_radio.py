from pathlib import Path
import os, subprocess, datetime, uuid, hashlib, json, re, struct, socket
ROOT=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005')
SOURCE='1ec3198e9c0db367af96fc264604c5a286003b5e'
STAGE=Path('/workspace/pr15-radio-observer-stage-1ec-20261005')
OUT=Path('/workspace/pr15-web-artifacts')/SOURCE/'radio-observer-qa-20261005'
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name,value):
    data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with (ROOT/name).open('xb') as f: f.write(data)
    return hashlib.sha256(data).hexdigest()
for port in [12815,12816,12817]:
    s=socket.socket(); assert s.connect_ex(('127.0.0.1',port))!=0; s.close()
active=[x for x in subprocess.check_output(['ps','-eo','stat,comm'],text=True).splitlines()[1:] if not x.split()[0].startswith('Z') and any(k in x.split()[1].lower() for k in ['godot','chromium'])]
assert not active,active
assert not OUT.exists(); OUT.mkdir()
run=ROOT/'export-isolated'/uuid.uuid4().hex; data=run/'data'; (data/'godot').mkdir(parents=True)
(data/'godot/export_templates').symlink_to('/tmp/pr15-web-controls/isolated-data/godot/export_templates',target_is_directory=True)
env=os.environ.copy(); env.update({'XDG_DATA_HOME':str(data),'XDG_CONFIG_HOME':str(run/'config'),'XDG_CACHE_HOME':str(run/'cache')})
argv=['/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64','--audio-driver','Dummy','--headless','--path',str(STAGE),'--export-debug','Web Game',str(OUT/'index.html')]
receipt={'source':SOURCE,'start':now(),'argv':argv,'isolated_data':str(data),'scope':'official 4.7.2 cached QA export, readonly CreditsScroll state addition only; no asset source generator/atlas/GLB/Blender rebuild'}
save('export-request.json',receipt)
with (ROOT/'export.log').open('xb') as f:
    child=subprocess.Popen(argv,env=env,stdout=f,stderr=subprocess.STDOUT); receipt['engine_pid']=child.pid
    try: child.wait(timeout=60); receipt['timed_out']=False
    except subprocess.TimeoutExpired: child.kill(); child.wait(); receipt['timed_out']=True
log=(ROOT/'export.log').read_text(); receipt.update({'actual_exit':child.returncode,'end':now(),'ERROR':len(re.findall('^ERROR:',log,re.M)),'SCRIPT_ERROR':len(re.findall('^SCRIPT ERROR:',log,re.M)),'files':[{'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.iterdir()) if p.is_file()]})
h=save('export-receipt.json',receipt); save('export-receipt-vault.json',receipt); save('export-receipt-seal.json',{'sha256':h,'scope':'original receipt duplicated immediately, exclusive creation'})
print(json.dumps(receipt),flush=True)
assert child.returncode==receipt['ERROR']==receipt['SCRIPT_ERROR']==0
def entries(path):
    b=path.read_bytes(); assert b[:4]==b'GDPC' and struct.unpack_from('<I',b,4)[0]==4
    base=struct.unpack_from('<Q',b,24)[0]; pos=struct.unpack_from('<Q',b,32)[0]; count=struct.unpack_from('<I',b,pos)[0]; pos+=4; out={}; payload={}
    for _ in range(count):
        n=struct.unpack_from('<I',b,pos)[0];pos+=4;name=b[pos:pos+n].rstrip(b'\0').decode();pos+=n
        off,size=struct.unpack_from('<QQ',b,pos);pos+=16;md5=b[pos:pos+16];pos+=16;flags=struct.unpack_from('<I',b,pos)[0];pos+=4;assert flags==0
        content=b[base+off:base+off+size];assert len(content)==size and hashlib.md5(content).digest()==md5
        out[name]={'bytes':size,'sha256':hashlib.sha256(content).hexdigest()};payload[name]=content
    return out,payload
old,old_payload=entries(OUT.parent/'event-log-cold-qa-v2-20261005/index.pck'); new,new_payload=entries(OUT/'index.pck')
delta={'added':sorted(set(new)-set(old)),'removed':sorted(set(old)-set(new)),'changed':sorted(k for k in set(old)&set(new) if old[k]!=new[k])}
allowed={'res://.godot/exported/','res://.godot/global_script_class_cache.cfg','res://.godot/uid_cache.bin'}
assert not delta['added'] and not delta['removed'],delta
assert all('event_log_observer' in k or k in allowed for k in delta['changed']),delta
def blocks(payload):
    text=payload['res://.godot/global_script_class_cache.cfg'].decode()
    return sorted(re.findall(r'\{[^{}]*\}',text,re.S))
assert blocks(old_payload)==blocks(new_payload)
report={'source':SOURCE,'all_payload_md5_verified':True,'qa_vs_fixed_qa':delta,'complete_class_blocks_equal':True,'class_blocks':len(blocks(new_payload)),'asset_payloads_unchanged':True,'production_bit_identical':False,'old':old,'new':new}
save('radio-payload-audit.json',report); print(json.dumps({k:v for k,v in report.items() if k not in ['old','new']}),flush=True)
