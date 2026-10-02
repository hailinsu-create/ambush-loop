#!/usr/bin/env python3
"""Build disposable standalone Godot project without importing/editing main project."""
import argparse,json,shutil
from pathlib import Path
H=Path(__file__).resolve().parent;P=H.parents[1];O=P/'art/environment_v2'
p=argparse.ArgumentParser();p.add_argument('target',type=Path);a=p.parse_args();T=a.target.resolve();T.mkdir(parents=True,exist_ok=True)
# only explicitly listed runtime candidates and unchanged baseline dependencies
cat=json.loads((H/'catalog_candidate.json').read_text());paths={v['path'] for asset in cat['new_assets'] for v in asset['lods']}
paths.update(v['path'] for v in cat['material_contract']['new_textures']);paths.update(v['path'] for v in cat['reuse_dependencies'])
paths.add('art/environment_v2/catalog_sample.json')
paths.update(str(p.relative_to(P)) for p in (O/'materials').glob('*.tres'))
for path in sorted(paths):
    dst=T/path;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(P/path,dst)
for path in (O/'sample').glob('*'):
    if path.suffix in ('.gd','.tscn'):dst=T/'art/environment_v2/sample'/path.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dst)
shutil.copy2(O/'sample/project.godot',T/'project.godot')
print('STAGED',len(paths),'files at',T)
