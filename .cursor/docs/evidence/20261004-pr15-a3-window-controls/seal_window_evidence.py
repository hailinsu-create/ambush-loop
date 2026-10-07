from pathlib import Path
import csv,hashlib,json,shutil,subprocess
repo=Path('/workspace/ambush-pr15');temp=Path('/tmp/pr15-a3-window-controls');dest=repo/'.cursor/docs/evidence/20261004-pr15-a3-window-controls'
assert not dest.exists();dest.mkdir(parents=True)
for label,uuid in [('probe-1dab','4372677ae2654d29a8119d065301949d'),('overhead-1dab','0b223a23a4d145438bb1aa6e441d9752')]:
 kind='a3-collector-probe' if label.startswith('probe') else 'a3-overhead-window'
 shutil.copytree(repo/'ambush_loop/build/asset_review/pr15-runtime'/f'{kind}-{uuid}',dest/label)
for name in ['provenance-b832.json','provenance-1dab.json','capacity-preflight.txt','readonly-b832.md','readonly-42249.md','formal-a3-api-map.md','probe-1dab.log','probe-1dab.exit','probe-raw-validation.json','overhead-1dab.log','overhead-1dab.exit','overhead-summary-1dab.json','overhead-summary-1dab.log','overhead-summary-1dab.exit','overhead-summary-hardened.json','overhead-summary-hardened.log','overhead-summary-hardened.exit','Xorg-124.log','Xorg-124.stdout','Xorg-124.pid','Xorg-124.exit','Xorg-124-closure.json']:
 shutil.copy2(temp/name,dest/name)
shutil.copy2('/tmp/pr15-full-xorg.conf',dest/'Xorg-124.conf')
source=['a3_window_context.gd','a3_cadence_sampler.gd','a3_collector_probe_test.gd','a3_collector_overhead_test.gd','a3_render_metrics.gd','a3_provenance.gd','prepare_a3_provenance.py','summarize_a3_window_controls.py','run_isolated_test.sh','run_isolated_test.ps1']
for name in source:
 p=dest/'source-1dab'/name;p.parent.mkdir(exist_ok=True);p.write_bytes(subprocess.check_output(['git','show',f'1dabd57d6694ef4630c9362086048ae818d3fd9f:ambush_loop/scripts/{name}'],cwd=repo))
p=dest/'analysis-7c968'/ 'summarize_a3_window_controls.py';p.parent.mkdir();shutil.copy2(repo/'ambush_loop/scripts/summarize_a3_window_controls.py',p)
for sha in ['b832587e9097acc78f69be4486cdf8587a014385','42249dfd4e753c2d994bea4aa8c2d0f73159ce44','7c968f4baa6bb1b0d2fdaf3486d67e4daa46cb54']:
 (dest/f'{sha[:7]}.patch').write_bytes(subprocess.check_output(['git','show','--format=fuller',sha,'--','ambush_loop'],cwd=repo))
prod=['scripts/main.gd','scripts/presentation/presenter_3d.gd','scripts/presentation/view_state.gd','scripts/presentation/shot_fx_pool.gd','scripts/presentation/tool_fx_pool.gd','scripts/presentation/movement_dust_pool.gd','scripts/replay/replay_player.gd']
# Obtain actual paths, then compare all tracked production source except test-only instrumentation/entries.
paths=[x for x in subprocess.check_output(['git','ls-files','ambush_loop'],cwd=repo).decode().splitlines() if x.endswith(('.gd','.tscn','.tres','.json','.py'))]
changed=subprocess.check_output(['git','diff','--name-only','16c7ec35432f1eaf392a42f2ffbc1b3286265da5','7c968f4baa6bb1b0d2fdaf3486d67e4daa46cb54','--','ambush_loop'],cwd=repo).decode().splitlines()
allowed={'ambush_loop/scripts/'+n for n in ['a3_window_context.gd','a3_cadence_sampler.gd','a3_collector_probe_test.gd','a3_collector_overhead_test.gd','summarize_a3_window_controls.py','run_isolated_test.sh','run_isolated_test.ps1']}
assert set(changed)<=allowed,changed
unchanged=[p for p in paths if p not in allowed]
proof={'base':'16c7ec35432f1eaf392a42f2ffbc1b3286265da5','window_consumer':'1dabd57d6694ef4630c9362086048ae818d3fd9f','offline_analyzer':'7c968f4baa6bb1b0d2fdaf3486d67e4daa46cb54','changed_project_paths':changed,'unchanged_tracked_source_paths':len(unchanged),'asset_ownership':'No ArtSource/build_yard_kit/GLB/Blender/atlas/production manifest changes; independent accepted R5 unchanged','scope':'Window rendered at1dab; analyzer-only hardened7c consumes SAME original raw after both engines ended. b832 receipt is obsolete unrun static-history, not reused.'}
(dest/'scope-and-production-unchanged.json').write_text(json.dumps(proof,indent=2)+'\n')
summary=json.loads((dest/'overhead-summary-hardened.json').read_text());report=json.loads((dest/'overhead-1dab/report.json').read_text())
rows=sum(len(list(csv.DictReader(p.open()))) for p in (dest/'overhead-1dab').glob('*/cadence.csv'));crows=sum(len(list(csv.DictReader(p.open()))) for p in (dest/'overhead-1dab').glob('*/collector/raw.csv'))
counts={'probe_checks':37,'overhead_checks':168,'raw_cadence_rows':rows,'raw_collector_rows':crows,'accepted_cadence_rows':sum(f['baseline_interval_usec']['n']+f['attached_interval_usec']['n'] for f in summary['families'].values()),'conditions':16,'collector_chunks':8,'probe_collector_chunks':3,'PNG':3,'all_raw_files_retained':True}
(dest/'counts.json').write_text(json.dumps(counts,indent=2)+'\n')
shutil.copy2(Path(__file__),dest/'seal_window_evidence.py')
items=[{'path':str(p.relative_to(dest)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dest.rglob('*')) if p.is_file()]
manifest={'format':1,'window_source':'1dabd57d6694ef4630c9362086048ae818d3fd9f','code_slice':'42249dfd4e753c2d994bea4aa8c2d0f73159ce44','offline_analyzer':'7c968f4baa6bb1b0d2fdaf3486d67e4daa46cb54','files':items,'file_count':len(items),'bytes':sum(x['bytes'] for x in items),'counts':counts,'scope':'Original Window controls only; actual0 E0S0 both suites. Formal six-level A3/normal13/dynamicFX/performance/art/mobile/FINAL/APK pending.'}
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
for item in items:
 p=dest/item['path'];assert p.stat().st_size==item['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==item['sha256']
print(json.dumps({k:v for k,v in manifest.items() if k!='files'}))
