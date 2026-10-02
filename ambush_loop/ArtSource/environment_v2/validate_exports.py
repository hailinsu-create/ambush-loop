#!/usr/bin/env python3
"""Validate emitted GLB bytes (not generator counts), dependencies and budgets."""
import argparse,hashlib,json,math,struct
from pathlib import Path
H=Path(__file__).resolve().parent;P=H.parents[1]
a=argparse.ArgumentParser();a.add_argument('--output',type=Path,default=P/'art/environment_v2');a.add_argument('--compare',type=Path);opt=a.parse_args();O=opt.output
checks=0;notes=[]
def check(ok,msg):
 global checks
 checks+=1
 if not ok:raise AssertionError(msg)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
formats={5120:('b',1),5121:('B',1),5122:('h',2),5123:('H',2),5125:('I',4),5126:('f',4)}
lengths={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def glb(p):
 d=p.read_bytes();magic,v,n=struct.unpack_from('<III',d);check(magic==0x46546c67 and v==2 and n==len(d),str(p)+' header');jlen,typ=struct.unpack_from('<II',d,12);check(typ==0x4e4f534a,str(p)+' JSON');j=json.loads(d[20:20+jlen]);off=20+jlen;blen,btyp=struct.unpack_from('<II',d,off);check(btyp==0x004e4942 and off+8+blen==len(d),str(p)+' BIN');return j,d[off+8:]
def array(j,d,index):
 ac=j['accessors'][index];view=j['bufferViews'][ac['bufferView']];fmt,n=formats[ac['componentType']];width=lengths[ac['type']];stride=view.get('byteStride',n*width);start=view.get('byteOffset',0)+ac.get('byteOffset',0)
 return [struct.unpack_from('<'+fmt*width,d,start+i*stride) for i in range(ac['count'])]
ex=json.loads((O/'exports.json').read_text());reports=[]
for asset in ex['assets']:
 for i,lod in enumerate(asset['lods']):
  p=O/'models'/Path(lod['path']).name;check(sha(p)==lod['sha256'],str(p)+' SHA');j,b=glb(p);tris=0;surfaces=0
  check(not j.get('images') and not j.get('textures'),str(p)+' must share external textures')
  check(not j.get('skins') and not j.get('animations'),str(p)+' no hidden skeleton/animation')
  names={m.get('name') for m in j.get('materials',[])};check(names<=set(asset['materials']) and 'environment_v2_atlas' in names,str(p)+' material names')
  for mesh in j['meshes']:
   for prim in mesh['primitives']:
    surfaces+=1;attrs=prim['attributes'];check(prim.get('mode',4)==4,str(p)+' topology')
    check({'POSITION','NORMAL','TEXCOORD_0'}<=attrs.keys(),str(p)+' vertex attributes')
    pos=array(j,b,attrs['POSITION']);norm=array(j,b,attrs['NORMAL']);uv=array(j,b,attrs['TEXCOORD_0']);idx=array(j,b,prim['indices'])
    check(len(idx)%3==0 and all(0<=v[0]<len(pos) for v in idx),str(p)+' indices');tris+=len(idx)//3
    check(all(all(math.isfinite(x) for x in v) for v in pos+norm+uv),str(p)+' finite attributes')
    check(all(abs(sum(x*x for x in n)-1)<.015 for n in norm),str(p)+' unit normals')
    check(all(-.001<=x<=1.001 for pair in uv for x in pair),str(p)+' atlas UV bounds')
  check(tris==lod['triangles'] and surfaces==lod['surfaces'],str(p)+' actual triangle/surface counts')
  budget=2000 if asset['category']=='prop' else 5000
  check(tris<=budget,str(p)+' geometry budget')
  if asset['category']=='prop':check(surfaces<=2,str(p)+' surface budget')
  nodes={n.get('name'):n for n in j['nodes']}
  for k,m in asset['moving_nodes'].items():
   n=nodes.get(m['node']);check(n is not None,str(p)+' pivot exists');actual=n.get('translation',[0,0,0]);check(all(abs(x-y)<.002 for x,y in zip(actual,m['position_m'])),str(p)+' pivot translation')
  for k,m in asset['sockets'].items():check(asset['asset_id']+'__socket_'+k in nodes,str(p)+' socket exists')
  if opt.compare:
   other=opt.compare/'models'/p.name;check(other.is_file() and sha(other)==sha(p),str(p)+' independent byte match')
  reports.append({'asset_id':asset['asset_id'],'lod':i,'bytes':p.stat().st_size,'triangles':tris,'surfaces':surfaces,'sha256':sha(p)})
for t in ex['textures']:
 p=O/'textures'/Path(t['path']).name;check(sha(p)==t['sha256'],str(p)+' texture SHA')
 if opt.compare:check(sha(p)==sha(opt.compare/'textures'/p.name),str(p)+' independent texture byte match')
if opt.compare:check(sha(O/'exports.json')==sha(opt.compare/'exports.json'),'deterministic exports metadata')
cat=json.loads((H/'catalog_candidate.json').read_text());expected={'ammo_can','barbed_wire','fence_section','field_radio','gun_case','handcart','jerry_can','lamp_post','oil_drum','rations_crate','sandbag','spare_tire','wooden_barrel','yard_crate'}
check({r['original_class'] for r in cat['original_14_mapping']}==expected,'exact fourteen classes')
for dep in cat['reuse_dependencies']:check(sha(P/dep['path'])==dep['sha256'],'unchanged reuse dependency '+dep['path'])
for theme,r in cat['themes'].items():
 check(r['landmark'] in {x['asset_id'] for x in ex['assets']},'theme landmark '+theme)
for name in ('ammo_can','gun_case','rations_crate','yard_crate'):
 entry=next(x for x in cat['new_assets'] if x['asset_id']=='env_'+name);check('lid_pivot' in entry['moving_nodes'],'interactive lid '+name)
report={'checks':checks,'status':'pass','models':reports,'model_bytes':sum(r['bytes'] for r in reports),'total_lod0_triangles':sum(r['triangles'] for r in reports if r['lod']==0),'max_prop_lod0_triangles':max(r['triangles'] for r in reports if r['lod']==0 and next(a for a in ex['assets'] if a['asset_id']==r['asset_id'])['category']=='prop'),'independent_output_match':bool(opt.compare),'textures':ex['textures'],'atlas_resident_uncompressed_estimate_bytes':3*1024*1024*4*4//3,'notes':['Simple walls/grounds intentionally below triangle target range','Warehouse shell has six independently removable display surfaces; not a single surface asset','No collision shapes or authored gameplay mapping','No mobile performance claim']}
(O/'evidence').mkdir(exist_ok=True);(O/'evidence/structure_report.json').write_text(json.dumps(report,indent=2)+'\n');print('ENVIRONMENT_STRUCTURE_OK',checks,'checks',report['model_bytes'],'GLB bytes')
