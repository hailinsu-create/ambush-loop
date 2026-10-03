from pathlib import Path
import json,hashlib,re,shutil,sys

name, sha, script, engine, mode, report_name = sys.argv[1:]
root=Path('/workspace/ambush-pr15')
base=root/'.cursor/docs/evidence/20261003-pr15-full-record'
out=base/('formal-'+name)
out.mkdir(parents=True,exist_ok=True)
logpath=Path('/tmp/pr15-full-final-'+name+'.log')
exitpath=Path('/tmp/pr15-full-final-'+name+'.exit')
log=logpath.read_text()
shutil.copyfile(logpath,out/'run.log')
shutil.copyfile(exitpath,out/'run.exit')
env={}
if name.startswith('campaign-'):env['AMBUSH_CAMPAIGN_LEVEL']=name.split('-')[1]
if name.startswith('command-'):env['AMBUSH_LEGACY_RECORD_FIXTURE']=str(base/'actual-schema1-874d350/command-record-source-v1.bin')
report=None;captures=[]
if report_name!='none':
    report_path=root/'ambush_loop/build/asset_review/pr15-runtime'/report_name
    report=json.loads(report_path.read_text())
    shutil.copyfile(report_path,out/'report.json')
    for index,capture in enumerate(report.get('captures',[])):
        path=root/'ambush_loop'/capture['path'].removeprefix('res://')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==capture['sha256'],('capture overwritten',capture['path'])
        dest=out/('%02d_%s'%(index,path.name))
        shutil.copyfile(path,dest)
        captures.append(dict(capture,retained_path=str(dest.relative_to(root)),hash_verified=True))
    if 'source_binary' in report:
        binary=report['source_binary']
        path=root/'ambush_loop'/binary['path'].removeprefix('res://')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==binary['sha256']
        shutil.copyfile(path,out/path.name)
summaries=re.findall(r'^.*(?:_OK|_TEST|_FAILED).*checks=(\d+)(?: failures=(\d+))?.*$',log,re.M)
assert summaries,('no completion summary',name)
checks,failures=summaries[-1]
meta={'actual_source_sha':sha,'validation_kind':'fixed-source-formal','name':name,
      'command':['bash','ambush_loop/scripts/run_isolated_test.sh',engine,script]+['--'+mode],
      'environment':env,'run_id':re.search(r'^TEST_RUN_ID=(.+)$',log,re.M).group(1),
      'actual_exit_code':int(exitpath.read_text()),'checks':int(checks),'failures':int(failures or '0'),
      'engine_error_lines':len(re.findall(r'^(?:SCRIPT ERROR|ERROR):',log,re.M)),
      'captures':captures,'captured_frames':len(captures),
      'limits':['Linux Godot4.7.2; software renderer is not device performance','Reference deployments/vacuum and controlled command deltas; not normal complete player journey','Known inherited title200 menu P2 is outside this formal replay gate; dedicated next slice']}
if report and 'native_inputs' in report:meta['native_inputs']=len(report['native_inputs'])
(out/'run.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in meta.items() if k not in ['captures','limits','command','environment']},ensure_ascii=False))
