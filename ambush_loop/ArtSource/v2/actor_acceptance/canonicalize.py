"""Canonicalize GLB surface ordering and micron precision for stable rebuilds.

No topology, joint hierarchy, animation channel or material changes. Mesh float
attributes are rounded to 1e-6, vertices sorted by all attributes, then triangles
sorted preserving winding. Binary accessor layouts/counts remain unchanged.
"""
import json,struct
import numpy as np
from .validate import read,acc

def normalize_glb(path):
 doc,raw=read(path);blob=bytearray(raw)
 def write(index,values):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
  width=np.dtype(dtype).itemsize;count=values.shape[1];off=v.get('byteOffset',0)+a.get('byteOffset',0)
  view=np.ndarray(values.shape,dtype=dtype,buffer=blob,offset=off,strides=(v.get('byteStride',width*count),width));view[:]=values
  if 'min' in a:a['min']=values.min(axis=0).tolist()
  if 'max' in a:a['max']=values.max(axis=0).tolist()
 for mesh in doc['meshes']:
  for primitive in mesh['primitives']:
   arrays={k:acc(doc,raw,i) for k,i in primitive['attributes'].items()}
   for name,values in arrays.items():
    if values.dtype.kind=='f':
     values[:]=np.round(values,6);values[values==0]=0.0
   table=np.column_stack([arrays[k] for k in sorted(arrays)])
   order=np.lexsort(table.T[::-1]);inverse=np.empty_like(order);inverse[order]=np.arange(len(order))
   # Rounding can make originally distinct exporter vertices identical. Route
   # all such references to the first identical row so tie ordering is stable.
   _,first,groups=np.unique(table[order],axis=0,return_index=True,return_inverse=True)
   inverse=first[groups][inverse]
   for name,values in arrays.items():write(primitive['attributes'][name],values[order])
   indices=inverse[acc(doc,raw,primitive['indices']).ravel()].reshape(-1,3)
   start=indices.argmin(axis=1);indices=np.take_along_axis(indices,(np.arange(3)[None,:]+start[:,None])%3,axis=1)
   indices=indices[np.lexsort(indices.T[::-1])]
   write(primitive['indices'],indices.reshape(-1,1))
 encoded=json.dumps(doc,separators=(',',':'),sort_keys=True).encode();encoded+=b' '*((-len(encoded))%4)
 blob+=b'\0'*((-len(blob))%4)
 path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(encoded)+len(blob))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(blob),0x004e4942)+blob)
