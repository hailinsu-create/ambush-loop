"""Falsification fixtures: ordering is ignored, meaningful changes are caught."""
import copy,json,struct,tempfile,argparse
from pathlib import Path
import numpy as np
from .validate import read,acc
from .semantic_hash import semantics

def put(doc,blob,index,values):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
 dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
 width=np.dtype(dtype).itemsize
 np.ndarray(values.shape,dtype=dtype,buffer=blob,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',width*values.shape[1]),width))[:]=values

def save(path,d,b):
 encoded=json.dumps(d,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
 b=bytes(b)+b'\0'*(-len(b)%4)
 path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(encoded)+len(b))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(b),0x004e4942)+b)

def check(path,output):
 doc,raw=read(path);reference=semantics(path);cases=[];rng=np.random.default_rng(1984)
 with tempfile.TemporaryDirectory() as directory:
  def run(name,mutate,expected):
   d,b=copy.deepcopy(doc),bytearray(raw);mutate(d,b);p=Path(directory)/f'{name}.glb';save(p,d,b);s=semantics(p)
   changed={k for k,v in reference['components'].items() if s['components'][k]!=v}
   assert changed==set(expected),(name,changed,expected)
   assert s['raw_sha256']!=reference['raw_sha256']
   cases.append({'case':name,'changed_components':sorted(changed),'passed':True})
  def reorder(d,b):
   p=d['meshes'][0]['primitives'][0];at=p['attributes'];count=d['accessors'][at['POSITION']]['count']
   order=rng.permutation(count);inverse=np.argsort(order)
   for i in at.values():put(d,b,i,acc(doc,raw,i)[order])
   ix=inverse[acc(doc,raw,p['indices']).reshape(-1,3)]
   put(d,b,p['indices'],np.roll(ix[rng.permutation(len(ix))],1,axis=1).reshape(-1,1))
   # Reorder joint table while preserving named influences and inverse binds.
   skin=d['skins'][0];order=rng.permutation(len(skin['joints']));inverse=np.argsort(order)
   skin['joints']=[skin['joints'][i] for i in order]
   put(d,b,skin['inverseBindMatrices'],acc(doc,raw,skin['inverseBindMatrices'])[order])
   ji=at['JOINTS_0'];values=acc(d,b,ji);put(d,b,ji,inverse[values])
   # Reorder nodes while retaining every reference.
   order=rng.permutation(len(d['nodes']));inverse=np.argsort(order)
   d['nodes']=[d['nodes'][i] for i in order]
   for n in d['nodes']:
    if 'children' in n:n['children']=[int(inverse[i]) for i in n['children']]
   for scene in d['scenes']:scene['nodes']=[int(inverse[i]) for i in scene['nodes']]
   for skin in d['skins']:
    skin['joints']=[int(inverse[i]) for i in skin['joints']]
    if 'skeleton' in skin:skin['skeleton']=int(inverse[skin['skeleton']])
   for a in d['animations']:
    a['channels'].reverse()
    for ch in a['channels']:ch['target']['node']=int(inverse[ch['target']['node']])
   d['asset']['generator']='Irrelevant provenance string'
  run('permuted_nodes_joints_vertices_triangles_channels_metadata',reorder,[])
  def attribute(name,amount):
   def mutate(d,b):
    p=d['meshes'][0]['primitives'][0];index=p['attributes'][name];v=acc(d,b,index);vertex=int(acc(d,b,p['indices'])[0,0]);v[vertex,0]+=amount;put(d,b,index,v)
   return mutate
  run('moved_vertex',attribute('POSITION',.001),['geometry','normals','uv','weights'])
  run('changed_normal',attribute('NORMAL',.01),['normals'])
  run('changed_uv',attribute('TEXCOORD_0',.001),['uv'])
  run('changed_bone_influence',attribute('JOINTS_0',1),['weights'])
  def animation(d,b):
   ch=next(c for c in d['animations'][0]['channels'] if c['target']['path']=='translation')
   index=d['animations'][0]['samplers'][ch['sampler']]['output'];v=acc(d,b,index);v[0,0]+=.002;put(d,b,index,v)
  run('changed_animation_key',animation,['animations'])
  def rest(d,b):d['nodes'][d['skins'][0]['joints'][1]].setdefault('translation',[0,0,0])[0]+=.001
  run('changed_rig_rest',rest,['rig'])
  def material(d,b):d['materials'][0]['pbrMetallicRoughness']['roughnessFactor']=.42
  run('changed_material',material,['materials'])
 output.write_text(json.dumps({'asset':str(path),'quantum':1e-6,'cases':cases,'passed':len(cases)},indent=2)+'\n')
 print('SEMANTIC_HASH_FALSIFICATION',len(cases),'passed')

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--asset',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();check(args.asset,args.output)
