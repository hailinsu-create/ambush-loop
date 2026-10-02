"""Check sampler semantics against known rotation angles and discontinuities."""
import argparse,json,math
from pathlib import Path
import numpy as np
from .validate import pose

def run(output):
    cases=[]
    for label,mode,last,phase,expected in [
        ('quarter_slerp','LINEAR',90,.25,22.5),
        ('step_holds_before_next_key','STEP',90,.75,0),
        ('step_uses_terminal_key','STEP',90,1,90),
        ('antipodal_short_path','LINEAR',-90,.25,22.5),
        ('zero_angle','LINEAR',0,.5,0),
    ]:
        angle=math.radians(abs(last));end=[0,0,math.sin(angle/2),math.cos(angle/2)]
        if last<0:end=[-v for v in end]
        blob=np.array([0,1],dtype='<f4').tobytes()+np.array([[0,0,0,1],end],dtype='<f4').tobytes()
        d={'nodes':[{'name':'bone'}],'bufferViews':[{'byteOffset':0},{'byteOffset':8}],
           'accessors':[{'bufferView':0,'componentType':5126,'count':2,'type':'SCALAR'},
                        {'bufferView':1,'componentType':5126,'count':2,'type':'VEC4'}]}
        a={'samplers':[{'input':0,'output':1,'interpolation':mode}],
           'channels':[{'sampler':0,'target':{'node':0,'path':'rotation'}}]}
        matrix=pose(d,blob,a,phase)[0]
        actual=math.degrees(math.atan2(matrix[1,0],matrix[0,0]))
        assert abs(actual-expected)<1e-5,(label,actual,expected)
        cases.append({'case':label,'actual_deg':actual,'expected_deg':expected,'passed':True})
    output.write_text(json.dumps({'cases':cases,'passed':len(cases)},indent=2)+'\n')
    print('ANIMATION_SAMPLING_CHECK',len(cases),'passed')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();run(args.output)
