import json,struct,hashlib
from pathlib import Path
new=Path('/tmp/pr15-r4-candidate-c4c2170/ambush_loop')
old=Path('/workspace/ambush-pr15/ambush_loop')
c=json.loads((new/'ArtSource/v2/actor_acceptance/catalog_candidate.json').read_text())
counts={'assets':0,'lods':0,'characters':0,'legacy_clips':0,'same_character_geometry':0,'same_original_socket':0}; errors=[]
def load(path):
 b=path.read_bytes();magic,version,length=struct.unpack_from('<III',b)
 assert magic==0x46546c67 and version==2 and length==len(b)
 n,kind=struct.unpack_from('<II',b,12);assert kind==0x4e4f534a
 d=json.loads(b[20:20+n]);p=20+n;n,kind=struct.unpack_from('<II',b,p);assert kind==0x004e4942
 return d,b[p+8:p+8+n]
def acc(d,b,i):
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']];assert 'sparse' not in a
 width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]*{5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}[a['componentType']]
 offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',width)
 raw=b''.join(b[offset+j*stride:offset+j*stride+width] for j in range(a['count']))
 return (a['count'],a['type'],a['componentType'],a.get('normalized',False),hashlib.sha256(raw).hexdigest())
def animation(d,b,a):
 rows=[]
 for ch in a['channels']:
  s=a['samplers'][ch['sampler']];rows.append((d['nodes'][ch['target']['node']]['name'],ch['target']['path'],s.get('interpolation','LINEAR'),acc(d,b,s['input']),acc(d,b,s['output'])))
 return sorted(rows)
def geometry(d,b):
 return [[{'attrs':{k:acc(d,b,v) for k,v in p['attributes'].items()},'indices':acc(d,b,p['indices']),'mode':p.get('mode',4),'mat':d['materials'][p['material']]['name']} for p in m['primitives']] for m in d['meshes']]
def node_record(d,n):
 parents={child:i for i,p in enumerate(d['nodes']) for child in p.get('children',[])}
 i=d['nodes'].index(n)
 return {k:n.get(k) for k in ['translation','rotation','scale','matrix']}|{'parent':d['nodes'][parents[i]]['name'] if i in parents else None}
for entry in c['assets']:
 counts['assets']+=1
 for lod in entry['lods']:
  counts['lods']+=1;p=lod['path'];assert hashlib.sha256((new/p).read_bytes()).hexdigest()==lod['sha256'],p
  a,ab=load(old/p);z,zb=load(new/p)
  if entry['category']=='character':
   counts['characters']+=1
   aa={v['name']:v for v in a['animations']};zz={v['name']:v for v in z['animations']}
   assert len(aa)==12 and len(zz)==52,(p,len(aa),len(zz))
   for name,clip in aa.items():
    assert animation(a,ab,clip)==animation(z,zb,zz[name]),(p,name)
    counts['legacy_clips']+=1
   assert geometry(a,ab)==geometry(z,zb),p;counts['same_character_geometry']+=1
   old_skin=a['skins'][0];new_skin=z['skins'][0]
   assert acc(a,ab,old_skin['inverseBindMatrices'])==acc(z,zb,new_skin['inverseBindMatrices']),p
   old_bones=[a['nodes'][j] for j in old_skin['joints']];new_bones=[z['nodes'][j] for j in new_skin['joints']]
   assert [n['name'] for n in old_bones]==[n['name'] for n in new_bones] and len(old_bones)==20,p
   for bone,other in zip(old_bones,new_bones):assert node_record(a,bone)==node_record(z,other),(p,bone['name'])
  else:
   zs={n['name']:n for n in z['nodes']}
   for n in a['nodes']:
    if '__socket_' in n.get('name',''):
     assert n['name'] in zs and node_record(a,n)==node_record(z,zs[n['name']]),(p,n['name'])
     counts['same_original_socket']+=1
for filename in ['actor_atlas_albedo.png','actor_atlas_normal.png','actor_atlas_orm.png']:
 assert (old/'art/v2/textures'/filename).read_bytes()==(new/'art/v2/textures'/filename).read_bytes(),filename
report={'scope':'read-only R3 vs R4 binary compatibility; no generator, no Godot battle or final art acceptance','r3_source':'00b270863ba5a2cd5425abf2a31e78965c72ae45','r4_source':'194d9c41aaddbf014f05c70c14d40c09e6d8131b','r4_delivery':'c4c21708a2e06d3a7eaefbb8ab6bfeee31f5073d','counts':counts,'errors':errors,'note':'Added rear-grip geometry in six gun GLBs is not an exact historical mesh match; runtime must preserve old R3 gun resources for exact old-version rendering.'}
Path('/tmp/pr15-r4-readonly-compat.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
