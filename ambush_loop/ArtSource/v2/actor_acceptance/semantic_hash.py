"""GLB semantics independent of buffer, vertex, triangle, joint and node order.

Positions/normals/UV/weights use the artifact's 1e-6 precision, explicitly
reported. Triangle winding and multiplicity remain significant. Unreferenced
vertices and duplicate GPU split vertices do not change rendered semantics.
Rig, animation, material and marker contracts remain separately significant.
"""
import hashlib,json,argparse
from pathlib import Path
import numpy as np
from .validate import read,acc,worlds,matrix
QUANTUM=1e-6

def q(a): return np.rint(np.asarray(a,dtype=float)/QUANTUM).astype('<i8')
def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def array_digest(a):return hashlib.sha256(np.ascontiguousarray(a,dtype='<i8').tobytes()).hexdigest()
def sort_rows(a):return a[np.lexsort(a.T[::-1])]
def triangles(rows,indices):
 a=rows[indices.reshape(-1,3)]
 # Lowest complete corner key starts each oriented triangle; no winding flip.
 order=np.array([min(range(3),key=lambda i:tuple(row[i])) for row in a])
 a=np.take_along_axis(a,((np.arange(3)[None,:]+order[:,None])%3)[:,:,None],axis=1)
 return sort_rows(a.reshape(len(a),-1))

def semantics(path,arrays=False):
 d,b=read(path);components={};tables={};world=worlds(d)
 assert len(d.get('meshes',[]))==1,'Hash scope: the one-mesh actor/equipment contract'
 material=[]
 for mi,m in enumerate(d.get('materials',[])):material.append(m)
 components['materials']=digest(sorted(material,key=lambda m:m.get('name','')))
 meshnode={n['mesh']:i for i,n in enumerate(d['nodes']) if 'mesh' in n}
 all_tables={k:[] for k in ['geometry','normals','uv','weights']}
 rig=[]
 for skin in d.get('skins',[]):
  parents={c:p for p,n in enumerate(d['nodes']) for c in n.get('children',[])}
  inv=acc(d,b,skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
  rig.extend([{'name':d['nodes'][i]['name'],'parent':d['nodes'][parents[i]]['name'] if parents.get(i) in skin['joints'] else None,'local_rest':q(matrix(d['nodes'][i])).tolist(),'inverse_bind':q(ib).tolist()} for i,ib in zip(skin['joints'],inv)])
 components['rig']=digest(sorted(rig,key=lambda x:x['name']))
 for mi,m in enumerate(d.get('meshes',[])):
  ni=meshnode[mi];skin=d.get('skins',[])[d['nodes'][ni]['skin']] if 'skin' in d['nodes'][ni] else None
  joint_names=[d['nodes'][i]['name'] for i in skin['joints']] if skin else []
  name_code={name:i for i,name in enumerate(sorted(joint_names))}
  for p in m['primitives']:
   at=p['attributes'];ix=acc(d,b,p['indices']).ravel();pos=q(acc(d,b,at['POSITION']));norm=q(acc(d,b,at['NORMAL']));uv=q(acc(d,b,at['TEXCOORD_0']))
   rows={'geometry':pos,'normals':np.column_stack((pos,norm)),'uv':np.column_stack((pos,uv))}
   if skin:
    j=acc(d,b,at['JOINTS_0']);w=q(acc(d,b,at['WEIGHTS_0']));named=np.array([[name_code[joint_names[int(v)]] for v in row] for row in j]);named[w==0]=-1
    order=np.argsort(named,axis=1,kind='stable');named=np.take_along_axis(named,order,axis=1);w=np.take_along_axis(w,order,axis=1)
    rows['weights']=np.column_stack((pos,named,w))
   else:rows['weights']=pos
   for k,row in rows.items():all_tables[k].append(triangles(row,ix))
 for k,parts in all_tables.items():
  table=sort_rows(np.concatenate(parts)) if parts else np.empty((0,0),dtype='<i8');components[k]=array_digest(table);tables[k]=table
 animations=[]
 for a in d.get('animations',[]):
  channels=[]
  for ch in a['channels']:
   s=a['samplers'][ch['sampler']];v=acc(d,b,s['output'])
   if ch['target']['path']=='rotation':
    # q and -q are the same orientation; canonicalize each key's sign.
    v=v.copy()
    for row in v:
     nz=np.where(abs(row)>QUANTUM/2)[0]
     if len(nz) and row[nz[0]]<0:row*=-1
   channels.append({'node':d['nodes'][ch['target']['node']]['name'],'path':ch['target']['path'],'interpolation':s.get('interpolation','LINEAR'),'time':q(acc(d,b,s['input'])).tolist(),'value':q(v).tolist()})
  animations.append({'name':a['name'],'channels':sorted(channels,key=lambda c:(c['node'],c['path']))})
 components['animations']=digest(sorted(animations,key=lambda a:a['name']))
 components['markers']=digest(sorted([{'name':n['name'],'world':q(world[i]).tolist()} for i,n in enumerate(d['nodes']) if '__socket_' in n['name']],key=lambda x:x['name']))
 components['mesh_transforms']=digest(sorted([q(world[i]).tolist() for i,n in enumerate(d['nodes']) if 'mesh' in n],key=lambda x:json.dumps(x)))
 result={'raw_sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'quantum':QUANTUM,'components':components,'semantic_sha256':digest(components),'triangles':sum(len(t) for t in all_tables['geometry']),'export_vertices':sum(d['accessors'][p['attributes']['POSITION']]['count'] for m in d.get('meshes',[]) for p in m['primitives'])}
 if arrays:result['_arrays']=tables
 return result

def compare(a,b):
 x,y=semantics(a,True),semantics(b,True);out={'file':Path(b).name,'raw_equal':x['raw_sha256']==y['raw_sha256'],'semantic_equal':x['semantic_sha256']==y['semantic_sha256'],'old':{k:v for k,v in x.items() if k!='_arrays'},'new':{k:v for k,v in y.items() if k!='_arrays'},'differences':[]}
 for k in x['components']:
  if x['components'][k]!=y['components'][k]:
   row={'component':k}
   if k in x['_arrays']:
    aa,bb=x['_arrays'][k],y['_arrays'][k];row['old_rows']=len(aa);row['new_rows']=len(bb)
    sa={r.tobytes() for r in aa};sb={r.tobytes() for r in bb};row['old_distinct_only']=len(sa-sb);row['new_distinct_only']=len(sb-sa)
   out['differences'].append(row)
 # Position-dependent fingerprints necessarily change with geometry. Compare
 # attribute values at common positions separately to avoid calling a moved
 # corner an independently changed skin weight.
 for k in ['normals','uv','weights']:
  def by_position(table):
   result={}
   for corner in table.reshape(-1,3,table.shape[1]//3).reshape(-1,table.shape[1]//3):
    result.setdefault(tuple(corner[:3]),set()).add(tuple(corner[3:]))
   return result
  aa,bb=by_position(x['_arrays'][k]),by_position(y['_arrays'][k]);common=aa.keys()&bb.keys()
  out.setdefault('common_position_attributes',{})[k]={'common_positions':len(common),'different_attribute_sets':sum(aa[p]!=bb[p] for p in common)}
 return out

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--first',type=Path,required=True);ap.add_argument('--second',type=Path,required=True);ap.add_argument('--catalog',type=Path);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
 names={Path(l['path']).name for a in json.loads(args.catalog.read_text())['assets'] for l in a['lods']} if args.catalog else None
 results=[compare(p,args.second/p.name) for p in sorted(args.first.glob('*.glb')) if (args.second/p.name).exists() and (names is None or p.name in names)];report={'quantum':QUANTUM,'assets':results,'raw_equal':sum(x['raw_equal'] for x in results),'semantic_equal':sum(x['semantic_equal'] for x in results),'files':len(results)};args.output.write_text(json.dumps(report,indent=2)+'\n');print('SEMANTIC_COMPARE',report['files'],'raw',report['raw_equal'],'semantic',report['semantic_equal']);print([(x['file'],[r['component'] for r in x['differences']]) for x in results if x['differences']])
