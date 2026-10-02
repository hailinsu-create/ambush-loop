"""Independent raw GLB contacts/endpoints and all7 corpse x all3 role pairing."""
import argparse,json,sys
from pathlib import Path
import numpy as np
from .validate import read,acc,pose,worlds
from .validate_firearms import MOUNT,point

def length(d,b,a):return max(float(acc(d,b,s['input'])[-1,0]) for s in a['samplers'])

def skin(d,b,w):
    s=d['skins'][0]; inv=acc(d,b,s['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    p=d['meshes'][0]['primitives'][0];a=p['attributes'];v=acc(d,b,a['POSITION'])
    j=acc(d,b,a['JOINTS_0']);weights=acc(d,b,a['WEIGHTS_0'])
    return np.einsum('nv,nvij,nj->ni',weights,np.array([w[i]@ib for i,ib in zip(s['joints'],inv)])[j],np.column_stack((v,np.ones(len(v)))))[:,:3]

def audit(project,profiles,catalog):
    contract=json.loads(profiles.read_text());manifest=json.loads(catalog.read_text())
    result={'configurations':[],'body_pairs':[],'transition_endpoints':[],'failures':[]}
    def check(ok,message):
        if not ok:result['failures'].append(message)
    for lod in range(3):
        for role in contract['roles']:
            d,b=read(project/'art/v2/models'/f'{role}_lod{lod}.glb')
            nodes={n['name']:i for i,n in enumerate(d['nodes'])};clips={a['name']:a for a in d['animations']}
            states={}
            for name in contract['clips']:
                a=clips[name];duration=length(d,b,a);max_grip=0.;ground=[];tips=[];hands=[]
                tool={'knife_stab':'knife','grenade_throw':'grenade','decoy_place':'decoy'}.get(name)
                if tool:
                    td,tb=read(project/'art/v2/models'/f'{tool}_lod{min(lod,1)}.glb')
                    markers={n['name'].split('__socket_')[-1]:worlds(td)[i][:3,3] for i,n in enumerate(td['nodes']) if '__socket_' in n['name']}
                for phase in np.linspace(0,1,25):
                    w=pose(d,b,a,duration*phase);palm=w[nodes['hand.R']]@point([0,.035,0])
                    hands.append(palm[:3].tolist())
                    if tool:
                        mount=w[nodes['hand.R']]@MOUNT
                        mount[:3,3]-=mount[:3,:3]@markers['grip']
                        max_grip=max(max_grip,float(np.linalg.norm((mount@point(markers['grip']))[:3]-palm[:3])))
                        if name=='decoy_place' and .40<=phase<=.60:ground.append(abs(mount[1,3]))
                        if name=='knife_stab':tips.append((mount@point(markers['tip']))[:3].tolist())
                row={'role':role,'lod':lod,'clip':name,'samples':25,'max_grip_m':max_grip,
                    'ground_origin_error_m':max(ground) if ground else None,
                    'knife_forward_excursion_m':max(tips[0][2]-p[2] for p in tips) if tips else None,
                    'throw_prepare_to_release_m':float(np.linalg.norm(np.array(hands[12])-hands[6])) if name=='grenade_throw' else None}
                check(max_grip<.0001,f'{role}/{name}/lod{lod} grip')
                if ground:check(max(ground)<.015,f'{role}/{name}/lod{lod} ground {max(ground)}')
                if tips:check(row['knife_forward_excursion_m']>.20,f'{role}/lod{lod} knife reach')
                if name=='grenade_throw':check(row['throw_prepare_to_release_m']>.45,f'{role}/lod{lod} throw arc')
                result['configurations'].append(row)
            for name,(enter,leave) in contract['transitions'].items():
                entering=pose(d,b,clips[enter],0);start=pose(d,b,clips[name],0)
                end=pose(d,b,clips[name],length(d,b,clips[name]));after=pose(d,b,clips[leave],0)
                error=max(float(abs(x[i]-y[i]).max()) for x,y in [(entering,start),(end,after)] for i in d['skins'][0]['joints'])
                check(error<.0001,f'{role}/lod{lod}/{name} seam {error}')
                result['transition_endpoints'].append({'role':role,'lod':lod,'clip':name,'max_matrix_component_error':error})
            actor=clips['corpse_drag'];duration=length(d,b,actor)
            for body in [e['asset_id'] for e in manifest['assets'] if e['category']=='character']:
                cd,cb=read(project/'art/v2/models'/f'{body}_lod{lod}.glb')
                cn={n['name']:i for i,n in enumerate(cd['nodes'])};ca=next(a for a in cd['animations'] if a['name']=='corpse_dragged')
                cw=pose(cd,cb,ca,0);shoulders=np.array([cw[cn['upper_arm.'+s]][:3,3] for s in ['L','R']]);body_points=skin(cd,cb,cw)
                errors=[];floors=[]
                for phase in np.linspace(0,1,25):
                    aw=pose(d,b,actor,duration*phase);palms=np.array([(aw[nodes['hand.'+s]]@point([0,.035,0]))[:3] for s in ['L','R']])
                    offset=palms.mean(axis=0)-shoulders.mean(axis=0)
                    errors.append(float(np.linalg.norm(palms-shoulders-offset,axis=1).max()))
                    floors.append(float(body_points[:,1].min()+offset[1]))
                check(max(errors)<.015 and min(floors)>-.015,f'{role}/{body}/lod{lod} pair {max(errors)} floor {min(floors)}')
                result['body_pairs'].append({'role':role,'body':body,'lod':lod,'samples':25,'max_shoulder_error_m':max(errors),'min_y_m':min(floors)})
    return result

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--profiles',type=Path,required=True);ap.add_argument('--catalog',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
    result=audit(args.project,args.profiles,args.catalog);args.output.write_text(json.dumps(result,indent=2)+'\n')
    print('UTILITY_BINARY_REVIEW configurations',len(result['configurations']),'body_pairs',len(result['body_pairs']),'failures',len(result['failures']))
    for message in result['failures']:print(message)
    sys.exit(bool(result['failures']))
