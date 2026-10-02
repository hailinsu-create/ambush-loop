#!/usr/bin/env python3
"""Independent binary GLB audit; no Blender API or exporter counts trusted."""
import hashlib,json,struct,sys,math
from pathlib import Path
import numpy as np
PROJECT=Path(__file__).resolve().parents[3]

def read(path):
 data=path.read_bytes();magic,version,total=struct.unpack_from('<III',data)
 assert (magic,version,total)==(0x46546c67,2,len(data))
 n,kind=struct.unpack_from('<II',data,12);assert kind==0x4e4f534a
 doc=json.loads(data[20:20+n]); n2,kind=struct.unpack_from('<II',data,20+n);assert kind==0x004e4942
 return doc,data[28+n:28+n+n2]

def acc(d,b,i):
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']]
 dtype={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
 count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
 width=np.dtype(dtype).itemsize; off=v.get('byteOffset',0)+a.get('byteOffset',0)
 arr=np.ndarray((a['count'],count),dtype=dtype,buffer=b,offset=off,strides=(v.get('byteStride',width*count),width)).copy()
 if a.get('normalized'):arr=arr.astype(float)/np.iinfo(dtype).max
 return arr

def matrix(n):
 if 'matrix' in n:return np.array(n['matrix']).reshape(4,4).T
 x,y,z,w=n.get('rotation',[0,0,0,1]); m=np.eye(4)
 m[:3,:3]=[[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]
 m[:3,:3]@=np.diag(n.get('scale',[1,1,1]));m[:3,3]=n.get('translation',[0,0,0]);return m

def worlds(d,overrides={}):
 nodes=d['nodes']; parents={c:p for p,n in enumerate(nodes) for c in n.get('children',[])};cache={}
 def world(i):
  if i not in cache:
   m=matrix({**nodes[i],**overrides.get(i,{})});cache[i]=world(parents[i])@m if i in parents else m
  return cache[i]
 return [world(i) for i in range(len(nodes))]

def pose(d,b,a,t):
 mods={}
 for ch in a['channels']:
  s=a['samplers'][ch['sampler']];ts=acc(d,b,s['input'])[:,0];vs=acc(d,b,s['output']);k=np.searchsorted(ts,t,side='right')-1;k=max(0,min(k,len(ts)-1))
  value=vs[k].copy()
  if k+1<len(ts):
   alpha=np.clip((t-ts[k])/(ts[k+1]-ts[k]),0,1);nxt=vs[k+1].copy()
   if ch['target']['path']=='rotation' and np.dot(value,nxt)<0:nxt=-nxt
   value=value*(1-alpha)+nxt*alpha
   if ch['target']['path']=='rotation':value/=np.linalg.norm(value)
  mods.setdefault(ch['target']['node'],{})[ch['target']['path']]=value.tolist()
 return worlds(d,mods)

def audit(project,strict=True):
 manifest=json.loads((project/'art/v2/actors_manifest.json').read_text());out={'assets':[],'violations':[]};reference=None
 def check(ok,msg):
  if not ok:out['violations'].append(msg)
 for e in manifest['assets']:
  item={'asset_id':e['asset_id'],'lods':[]}
  for level,lod in enumerate(e['lods']):
   p=project/lod['path'];d,b=read(p);label=f"{e['asset_id']}/lod{level}";entry={'level':level,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
   check(entry['sha256']==lod['sha256'],label+' hash')
   check(not d.get('images'),label+' duplicate textures');check([m['name'] for m in d.get('materials',[])]==['v2_actor_atlas'],label+' material')
   tris=0;degenerate=0;verts=0
   for m in d['meshes']:
    for prim in m['primitives']:
     at=prim['attributes'];pos=acc(d,b,at['POSITION']);norm=acc(d,b,at['NORMAL']);uv=acc(d,b,at['TEXCOORD_0']);ix=acc(d,b,prim['indices']).ravel();tris+=len(ix)//3;verts+=len(pos)
     check(np.isfinite(pos).all() and np.isfinite(uv).all(),label+' nonfinite');check((abs(np.linalg.norm(norm,axis=1)-1)<.02).all(),label+' normals')
     check((uv>=0).all() and (uv<=1).all(),label+' uv');check(ix.max()<len(pos) and len(ix)%3==0,label+' indices')
     a,bp,c=pos[ix.reshape(-1,3)].transpose(1,0,2);areas=np.linalg.norm(np.cross(bp-a,c-a),axis=1);degenerate+=int((areas<1e-12).sum())
     if e['category']=='character':
      joints=acc(d,b,at['JOINTS_0']);w=acc(d,b,at['WEIGHTS_0']);check((abs(w.sum(axis=1)-1)<1e-5).all() and (w>=0).all(),label+' weights');check(joints.max()<20,label+' joints')
   entry.update(triangles=tris,vertices=verts,degenerate_triangles=degenerate)
   if e['category']=='weapon' or e['asset_id']=='knife':
    world=worlds(d)
    markers={n['name']:world[i][:3,3] for i,n in enumerate(d['nodes']) if '__socket_' in n['name']}
    for key,value in e['sockets'].items():
     if value is not None:check(e['asset_id']+'__socket_'+key in markers and np.allclose(markers[e['asset_id']+'__socket_'+key],value,atol=1e-6),label+' socket '+key)
    entry['socket_positions_m']={k:v.tolist() for k,v in markers.items()}
   check(degenerate==0,label+' degenerate triangles');check(tris==lod['triangles'],label+' stated triangles')
   cap={'character':[8000,4000,1800],'weapon':[3000,1500],'tool':[2000,1000]}[e['category']][level];check(tris<=cap,label+' budget')
   if e['category']=='character':
    skin=d['skins'][0];nodes=[d['nodes'][i] for i in skin['joints']];check(len(nodes)==20,label+' skeleton');signature=[(n['name'],np.round(matrix(n),5).tolist(),n.get('children',[])) for n in nodes]
    # Node indices vary by scene; compare names, rest transforms and named parents.
    parents={c:d['nodes'][p]['name'] for p,n in enumerate(d['nodes']) for c in n.get('children',[])}
    sig=[(n['name'],np.round(matrix(n),5).tolist(),parents.get(i) if parents.get(i) in {n['name'] for n in nodes} else None) for i,n in zip(skin['joints'],nodes)]
    if reference is None:reference=sig
    check(sig==reference,label+' incompatible rest rig')
    animations={a['name']:a for a in d.get('animations',[])};check(set(animations)=={x['name'] for x in e['animations']},label+' clips')
    inv=acc(d,b,skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    primitive=d['meshes'][0]['primitives'][0]; at=primitive['attributes'];pos=acc(d,b,at['POSITION']);j=acc(d,b,at['JOINTS_0']);w=acc(d,b,at['WEIGHTS_0']);hom=np.column_stack((pos,np.ones(len(pos))))
    root=next(i for i in skin['joints'] if d['nodes'][i]['name']=='root');metrics={}
    for name,anim in animations.items():
     duration=max(float(acc(d,b,s['input'])[-1,0]) for s in anim['samplers']); mins=[];maxs=[];gap=0;first=None;last=None
     for t in np.linspace(0,duration,25):
      world=pose(d,b,anim,t);check(np.allclose(world[root],np.eye(4),atol=1e-5),label+'/'+name+' root motion')
      mats=np.array([world[i]@ib for i,ib in zip(skin['joints'],inv)])
      skinned=np.einsum('nv,nvij,nj->ni',w,mats[j],hom)[:,:3];mins.append(skinned.min(axis=0));maxs.append(skinned.max(axis=0))
      if first is None:first=skinned
      last=skinned
      for child in ['forearm.L','forearm.R','hand.L','hand.R','shin.L','shin.R','foot.L','foot.R']:
       ci=next(i for i in skin['joints'] if d['nodes'][i]['name']==child)
       pi=next(i for i in skin['joints'] if ci in d['nodes'][i].get('children',[]))
       length=np.linalg.norm(np.array(d['nodes'][ci]['translation']))
       gap=max(gap,float(np.linalg.norm((world[pi]@np.array([0,length,0,1]))[:3]-world[ci][:3,3])))
     seam=float(np.linalg.norm(first-last,axis=1).max())
     metrics[name]={'duration_s':duration,'min_y_m':round(float(min(p[1] for p in mins)),5),'max_y_m':round(float(max(p[1] for p in maxs)),5),'max_limb_endpoint_gap_m':round(gap,6),'loop_seam_m':round(seam,6),'samples':25}
     check(gap<.012,label+'/'+name+' detached limb endpoint')
     if next(x['loop'] for x in e['animations'] if x['name']==name):check(seam<.001,label+'/'+name+' loop seam')
     check(min(p[1] for p in mins)>-.015,label+'/'+name+' below floor');
     check(abs(duration-round(next(x['duration'] for x in e['animations'] if x['name']==name)*30)/30)<1e-4,label+'/'+name+' duration')
    entry['animation_samples']=metrics
   item['lods'].append(entry)
  check(all(a['triangles']>b['triangles'] for a,b in zip(item['lods'],item['lods'][1:])),e['asset_id']+' LOD progression');out['assets'].append(item)
 for tex in manifest['textures']:check(hashlib.sha256((project/tex['path']).read_bytes()).hexdigest()==tex['sha256'],'texture '+tex['path'])
 out.update(asset_count=len(out['assets']),lod_count=sum(len(x['lods']) for x in out['assets']))
 return out

if __name__=='__main__':
 import argparse
 ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=PROJECT);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--diagnostic',action='store_true');args=ap.parse_args()
 result=audit(args.project);args.output.write_text(json.dumps(result,indent=2)+'\n');print('ACTOR_BINARY_AUDIT',result['asset_count'],result['lod_count'],'violations',len(result['violations']));print('\n'.join(result['violations']));sys.exit(bool(result['violations']) and not args.diagnostic)
