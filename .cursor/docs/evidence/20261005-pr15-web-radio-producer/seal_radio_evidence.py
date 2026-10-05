from pathlib import Path
import json,hashlib,datetime,subprocess,shutil,socket,sys
ROOT=Path('/workspace/ambush-pr15');BASE=Path('/tmp/pr15-web-controls/radio-native-1ec-20261005');RUN=BASE/'run'
def digest(p):
 b=p.read_bytes();return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def verify_receipts():
 out=[]
 for p in sorted((RUN/'receipts').glob('*.json')):
  seal=json.loads((RUN/'receipt-vault'/(p.stem+'.seal.json')).read_text());proof=digest(p)
  assert proof['bytes']==seal['bytes'] and proof['sha256']==seal['sha256'] and p.read_bytes()==(RUN/'receipt-vault'/p.name).read_bytes(),p.name
  receipt=json.loads(p.read_text());assert receipt['actual_exit'] in [0,1],(p.name,receipt['actual_exit'])
  if 'loaded_script_sha256' in receipt:assert digest(RUN/'loaded-controls'/(p.stem+'.py'))['sha256']==receipt['loaded_script_sha256']
  out.append({'label':p.stem,**proof,'actual_exit':receipt['actual_exit'],'start':receipt['start'],'end':receipt['end']})
 return out
def checkpoint_receipts():
 receipts=verify_receipts();dst=BASE/'receipt-checkpoint-before-finish';assert not dst.exists();dst.mkdir()
 for row in receipts:
  p=RUN/'receipts'/(row['label']+'.json');shutil.copyfile(p,dst/p.name)
 (dst/'manifest.json').write_text(json.dumps({'sealed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'receipts':receipts,'scope':'independent copies of exact original controller receipts before finish; no backfill or endpoint rewrite'},indent=2)+'\n')
 print(json.dumps({'actual_exit':0,'scope':'pre-finish immutable receipt checkpoint','receipt_count':len(receipts)}))
def seal(stage):
 assert stage in ['producer','end'];producer=json.loads((RUN/'radio-producer.json').read_text());record=producer['record'];assert producer['status']=='PASS' and digest(RUN/'radio-record.bin')=={'bytes':record['bytes'],'sha256':record['sha256']}
 receipts=verify_receipts();pre=json.loads((BASE/'preflight.json').read_text())
 for pin in pre['pins']:
  assert digest(ROOT/pin['path'])=={'bytes':pin['bytes'],'sha256':pin['sha256']}
  assert subprocess.check_output(['git','hash-object',pin['path']],cwd=ROOT,text=True).strip()==pin['git_blob']
 assert subprocess.check_output(['git','rev-parse','HEAD:ambush_loop'],cwd=ROOT,text=True).strip()==pre['game_tree']
 old=ROOT/'.cursor/docs/evidence/20261005-pr15-web-radio-producer'
 dest=old if stage=='producer' else ROOT/'.cursor/docs/evidence/20261005-pr15-web-radio-functional-end'
 assert not dest.exists();existing=set();extra={}
 if stage=='end':
  previous=json.loads((old/'manifest.json').read_text())
  for f in previous['files']:assert digest(old/f['path'])=={'bytes':f['bytes'],'sha256':f['sha256']};existing.add(f['path'])
  assert json.loads((BASE/'browser-end-tool-receipt.json').read_text())['exit_code']==0
  lifecycle=json.loads((RUN/'engine-window-lifecycle.json').read_text());assert lifecycle['clean_context_end']
  proof=json.loads((RUN/'radio-browser-final-proof.json').read_text());assert proof['status']=='PASS'
  audit=json.loads((BASE/'radio-offline-audit-receipt.json').read_text());result=json.loads((BASE/'radio-offline-audit-result.json').read_text());assert audit['actual_exit']==audit['ERROR']==audit['SCRIPT_ERROR']==0 and audit['test_storage_guard_passed'] and not result['failures']
  checkpoint=json.loads((BASE/'receipt-checkpoint-before-finish/manifest.json').read_text())
  for row in checkpoint['receipts']:
   p=RUN/'receipts'/(row['label']+'.json');assert digest(p)=={'bytes':row['bytes'],'sha256':row['sha256']} and p.read_bytes()==(BASE/'receipt-checkpoint-before-finish'/p.name).read_bytes()
  for port in [12815,12816,12817]:
   s=socket.socket();closed=s.connect_ex(('127.0.0.1',port))!=0;s.close();assert closed
  processes=subprocess.check_output(['ps','-eo','stat,comm,args'],text=True).splitlines()[1:];live=[r for r in processes if not r.split()[0].startswith('Z') and r.split()[1] in ['chromium','chrome','Godot_v4.7.2-st','godot']];assert not live
  profile=Path('/workspace/.ambush-loop-env/web-fresh-native-dab-20261005');assert not (profile/'SingletonLock').exists() and not (profile/'SingletonLock').is_symlink()
  whole=[]
  for rate in [1,2]:
   packet=json.loads((RUN/f'radio-whole-{rate}x.json').read_text());rows=packet['observer_rows'];assert packet['status']=='PASS' and packet['record_sha256']==record['sha256'] and not packet['frame_checks']['failures']
   assert rows[0]['tick']==0 and rows[-1]['tick']==record['terminal'] and not rows[-1]['playing']
   assert all(r['view_tick']==r['tick'] and r['attempt']==record['attempt'] and r['rate']==rate for r in rows)
   assert all(a['tick']<=b['tick'] for a,b in zip(rows,rows[1:])) and packet['input_to_terminal_callback_wall']<packet['deadline_wall']
   before=json.loads((RUN/f'radio-whole-{rate}x-before-natural-full-fingerprint.json').read_text());after=json.loads((RUN/f'radio-whole-{rate}x-after-terminal-full-fingerprint.json').read_text());post=json.loads((RUN/f'radio-whole-{rate}x-post-WON-full-fingerprint.json').read_text())
   assert before['domain']==after['domain'] and before['record_sha256']==after['record_sha256']==post['record_sha256']==record['sha256']
   assert before['state']['settings']['configs']==after['state']['settings']['configs']==post['state']['settings']['configs']
   whole.append({k:v for k,v in packet.items() if k not in ['observer_rows','actual_input_rows']}|{'observer_row_count':len(rows)})
  extra={'prior_manifest':'../20261005-pr15-web-radio-producer/manifest.json','prior_file_count':previous['file_count'],'prior_total_bytes':previous['total_bytes'],'browser_final_proof':proof,'lifecycle':lifecycle,'whole':whole,'offline_artifact_result':result,'pre_finish_receipts_reverified':len(checkpoint['receipts']),'live_engines':live,'ports_closed':True,'profile_lock_absent':True}
  (BASE/'post-end-verification.json').write_text(json.dumps({'actual_exit':0,'source':pre['source'],'game_tree':pre['game_tree'],'pins':pre['pins'],'record':record,'receipts':receipts,**extra},ensure_ascii=False,indent=2)+'\n')
 dest.mkdir()
 chosen=[p for p in BASE.iterdir() if p.is_file() and p.suffix in ['.py','.gd','.json','.log']]
 if stage=='producer':
  stable=['profile-before.json','owned-pages-startup.json','radio-start-checkpoint.json','radio-producer.json','radio-record.bin','radio-original-fingerprints.json','radio-browser-trusted.json']
  chosen += [RUN/n for n in stable]+list(RUN.glob('*.png'))
  for folder in ['requests','loaded-controls','receipts','receipt-vault']:chosen+=list((RUN/folder).glob('*'))
 else:
  chosen += [p for p in RUN.rglob('*') if p.is_file()]+[p for p in (BASE/'receipt-checkpoint-before-finish').iterdir() if p.is_file()]
 files=[]
 for p in sorted(set(chosen)):
  rel=str(p.relative_to(BASE))
  if rel in existing:assert digest(p)==digest(old/rel),rel;continue
  target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target);files.append({'path':rel,**digest(target)})
 manifest={'source':pre['source'],'game_tree':pre['game_tree'],'sealed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PRODUCER_PASS_WHOLE_PROGRESS_PENDING' if stage=='producer' else 'PASS_BOUNDED_RADIO_FUNCTIONAL_END','original_record':record,'receipts':receipts,'files':files,'file_count':len(files),'total_bytes':sum(f['bytes'] for f in files),'scope':'immutable original producer files; live logs excluded' if stage=='producer' else 'all final whole/progress/END proof plus previously-live logs; original producer/bin referenced without rewrite; no full six/performance acceptance',**extra}
 (dest/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 for f in files:assert digest(dest/f['path'])=={'bytes':f['bytes'],'sha256':f['sha256']}
 print(json.dumps({k:v for k,v in manifest.items() if k in ['status','file_count','total_bytes','sealed_at','source','game_tree','pre_finish_receipts_reverified']},ensure_ascii=False))
if __name__=='__main__':
 if sys.argv[1]=='receipts':checkpoint_receipts()
 else:seal(sys.argv[1])
