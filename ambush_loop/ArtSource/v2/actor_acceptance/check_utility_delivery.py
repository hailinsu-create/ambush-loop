"""Reproduce R4 compatibility, constructive LOD budgets and final artifact scope."""
import argparse,hashlib,json,subprocess
from pathlib import Path
import numpy as np
from .semantic_hash import compare
from .validate import read,acc

def clip_keys(d,b,a):
    result=[]
    for c in a['channels']:
        s=a['samplers'][c['sampler']];values=acc(d,b,s['output']).copy()
        if c['target']['path']=='rotation':
            for v in values:
                if v[np.argmax(abs(v))]<0:v*=-1
        result.append({'bone':d['nodes'][c['target']['node']]['name'],'path':c['target']['path'],
            'interpolation':s.get('interpolation','LINEAR'),
            'times':np.rint(acc(d,b,s['input'])*1e6).astype(int).tolist(),
            'values':np.rint(values*1e6).astype(int).tolist()})
    return sorted(result,key=lambda c:(c['bone'],c['path']))

def check(project,baseline_models,first,second,output):
    output.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((project/'ArtSource/v2/actor_acceptance/catalog_candidate.json').read_text())
    classification=[];legacy=[];budget=[];repeat=[]
    for asset in manifest['assets']:
        for lod_index,lod in enumerate(asset['lods']):
            p=project/lod['path'];old=baseline_models/p.name
            r=compare(old,p);classification.append(r)
            od,ob=read(old);nd,nb=read(p)
            if od.get('skins'):
                oa={a['name']:a for a in od['animations']};na={a['name']:a for a in nd['animations']}
                passed=all(name in na and clip_keys(od,ob,a)==clip_keys(nd,nb,na[name]) for name,a in oa.items())
                assert passed,p.name
                assert len(oa)==52 and len(na)==64,p.name
                assert [x['component'] for x in r['differences']]==['animations'],r['differences']
                legacy.append({'file':p.name,'old_clips':len(oa),'new_clips':len(na),'old_sha256':r['old']['raw_sha256'],'new_sha256':r['new']['raw_sha256'],'all_old_clip_keys_equal':passed})
            else:assert r['raw_equal'],p.name
            budget.append({'asset':asset['asset_id'],'lod':lod_index,'triangles':lod['triangles'],'surfaces':lod['surfaces'],
                'old_glb_bytes':old.stat().st_size,'new_glb_bytes':p.stat().st_size,'byte_delta':p.stat().st_size-old.stat().st_size})
    for name in [l['path'] for a in manifest['assets'] for l in a['lods']]+[t['path'] for t in manifest['textures']]+['catalog_candidate.json','firearm_profiles_candidate.json','utility_profiles_candidate.json']:
        aa=(first/name).read_bytes();assert aa==(second/name).read_bytes(),name
        target=project/name if name.startswith('art/') else project/'ArtSource/v2/actor_acceptance'/name
        assert aa==target.read_bytes(),name
        repeat.append({'path':name,'sha256':hashlib.sha256(aa).hexdigest(),'raw_repeat_equal':True,'equal_to_tracked':True})
    reports={'change-classification.json':classification,'old52-compatibility.json':legacy,'raw-repeat.json':repeat,
        'resource-budget.json':{'models':budget,'total_old_glb_bytes':sum(x['old_glb_bytes'] for x in budget),
            'total_new_glb_bytes':sum(x['new_glb_bytes'] for x in budget),
            'characters_old52_new64':'21 skins x12 added clips; file bytes are not imported animation memory',
            'remaining':'Main author scene/imported-animation memory and actual FPS acceptance; no device claim'}}
    for name,value in reports.items():(output/name).write_text(json.dumps(value,indent=2)+'\n')
    print('UTILITY_DELIVERY_COMPATIBILITY 21x52 old clips /30 raw equipment /57 repeat and tracked artifacts passed')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--baseline-models',type=Path,required=True);ap.add_argument('--first',type=Path,required=True);ap.add_argument('--second',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);a=ap.parse_args()
    check(a.project,a.baseline_models,a.first,a.second,a.output)
