"""Binary contact and transition audit across actual 10 guns / 3 roles / 3 LODs."""
import argparse, hashlib, json, sys
from pathlib import Path
import numpy as np
from .validate import read, acc, pose, worlds

ROLES = ['operator_rifle', 'operator_mg', 'operator_scout']
MOUNT=np.array([[1,0,0,0],[0,0,-1,.035],[0,1,0,0],[0,0,0,1]],dtype=float)
def point(value):return np.array([*value,1.],dtype=float)
def audit(project,profiles):
    contract=json.loads(profiles.read_text());out={'configurations':[],'failures':[],'transition_endpoints':[],'samples_per_action':25}
    def check(ok,msg):
        if not ok:out['failures'].append(msg)
    for profile in contract['profiles']:
        gun=profile['weapon_id']
        for role in ROLES:
            for lod in range(3):
                d,b=read(project/'art/v2/models'/f'{role}_lod{lod}.glb')
                gd,gb=read(project/'art/v2/models'/f'{gun}_lod{min(lod,1)}.glb')
                nodes={n['name']:i for i,n in enumerate(d['nodes'])};anims={a['name']:a for a in d['animations']}
                markers={n['name'].split('__socket_')[-1]:worlds(gd)[i][:3,3] for i,n in enumerate(gd['nodes']) if '__socket_' in n['name']}
                label=f'{role}/{gun}/lod{lod}'
                row={'role':role,'weapon':gun,'lod':lod,'actions':{}}
                for stage,name in profile['clips'].items():
                    anim=anims[name];duration=max(float(acc(d,b,s['input'])[-1,0]) for s in anim['samplers'])
                    support=[];eye=[];reload=[];muzzle_forward=[]
                    for phase in np.linspace(0,1,25):
                        w=pose(d,b,anim,duration*phase);g=w[nodes['hand.R']]@MOUNT
                        palm=w[nodes['hand.L']]@point([0,.035,0]);contact=g@point(markers['pose_support'])
                        support.append(float(np.linalg.norm(palm[:3]-contact[:3])))
                        if stage=='reload_contact' and .40<=phase<=.60:
                            reload.append(float(np.linalg.norm(palm[:3]-(g@point(markers['reload_contact']))[:3])))
                        e=w[nodes['head']]@point([.037,.139,-.106]);s=g@point(markers['sight']);direction=-g[:3,2]
                        eye.append(float(np.linalg.norm((e-s)[:3]-direction*np.dot((e-s)[:3],direction))))
                        m=(g@point(markers['muzzle']))[:3];origin=g[:3,3]
                        muzzle_forward.append(float(np.dot(m-origin,direction)))
                        check(np.isfinite(m).all() and abs(np.linalg.norm(direction)-1)<1e-4,label+'/'+stage+' muzzle invalid')
                    if stage!='reload_contact':check(max(support)<.015,label+'/'+stage+' support error '+str(max(support)))
                    else:check(reload and max(reload)<.015,label+' reload contact '+str(reload))
                    if stage in ['aim','fire']:check(max(eye)<.035,label+'/'+stage+' sight error '+str(max(eye)))
                    check(min(muzzle_forward)>.10,label+'/'+stage+' muzzle behind grip')
                    row['actions'][stage]={'clip':name,'duration_s':duration,'max_support_error_m':max(support),
                                           'max_eye_line_error_m':max(eye),'max_reload_contact_error_m':max(reload) if reload else None,
                                           'min_muzzle_forward_m':min(muzzle_forward)}
                out['configurations'].append(row)
                for key,transition in contract['transitions'].items():
                    entering=anims[profile['clips'][transition['entry']['clip_key']]]
                    middle=anims[profile['clips'][transition['clip_key']]]
                    leaving=anims[profile['clips'][transition['exit']['clip_key']]]
                    length=max(float(acc(d,b,s['input'])[-1,0]) for s in middle['samplers'])
                    before=pose(d,b,entering,0);start=pose(d,b,middle,0)
                    end=pose(d,b,middle,length);after=pose(d,b,leaving,0)
                    # Full skeleton matrices, not just palm marker coincidence.
                    joints=d['skins'][0]['joints']
                    error=max(float(abs(a[i]-z[i]).max()) for a,z in [(before,start),(end,after)] for i in joints)
                    check(error<1e-4,label+'/'+key+' endpoint seam '+str(error))
                    out['transition_endpoints'].append({'role':role,'weapon':gun,'lod':lod,'transition':key,'max_matrix_component_error':error})
    return out

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--profiles',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
    result=audit(args.project,args.profiles);args.output.write_text(json.dumps(result,indent=2)+'\n')
    print('FIREARM_BINARY_REVIEW configurations',len(result['configurations']),'failures',len(result['failures']))
    for failure in result['failures']:print(failure)
    sys.exit(bool(result['failures']))
