#!/usr/bin/env python3
"""Validate exported GLBs and shared texture hashes without Blender/Godot."""
import hashlib
import json
import math
from pathlib import Path
import struct

PROJECT=Path(__file__).resolve().parents[2]


def read_glb(path):
    data=path.read_bytes()
    magic,version,size=struct.unpack_from("<III",data)
    assert magic==0x46546C67 and version==2 and size==len(data), path
    length,kind=struct.unpack_from("<II",data,12)
    assert kind==0x4E4F534A
    document=json.loads(data[20:20+length])
    start=20+length
    bin_length,bin_kind=struct.unpack_from("<II",data,start)
    assert bin_kind==0x004E4942
    return document,data[start+8:start+8+bin_length]


def accessor(doc,blob,index):
    entry=doc["accessors"][index]; view=doc["bufferViews"][entry["bufferView"]]
    scalar={5123:"H",5125:"I",5126:"f"}[entry["componentType"]]
    count={"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4}[entry["type"]]
    fmt="<"+scalar*count; width=struct.calcsize(fmt)
    base=view.get("byteOffset",0)+entry.get("byteOffset",0)
    return [struct.unpack_from(fmt,blob,base+i*view.get("byteStride",width)) for i in range(entry["count"])]


def main():
    manifest=json.loads((PROJECT/"art/v2/manifest.json").read_text())
    checked=0
    for texture in manifest["textures"]:
        assert hashlib.sha256((PROJECT/texture["path"]).read_bytes()).hexdigest()==texture["sha256"]
    for asset in manifest["assets"]:
        for lod in asset["lods"]:
            path=PROJECT/lod["path"]
            assert hashlib.sha256(path.read_bytes()).hexdigest()==lod["sha256"],path
            doc,blob=read_glb(path)
            assert not doc.get("images"), "Shared textures must not be embedded repeatedly"
            triangles=0; surfaces=0; bounds=[]
            for mesh in doc["meshes"]:
                for primitive in mesh["primitives"]:
                    surfaces+=1
                    attrs=primitive["attributes"]
                    positions=accessor(doc,blob,attrs["POSITION"])
                    normals=accessor(doc,blob,attrs["NORMAL"])
                    uv=accessor(doc,blob,attrs["TEXCOORD_0"])
                    indices=accessor(doc,blob,primitive["indices"])
                    triangles+=len(indices)//3
                    assert len(indices)%3==0
                    assert all(0<=i[0]<len(positions) for i in indices)
                    assert all(math.isfinite(v) for row in positions for v in row)
                    assert all(abs(sum(v*v for v in row)-1)<.015 for row in normals)
                    assert all(-.001<=v<=1.001 for row in uv for v in row),path
                    bounds.extend(positions)
                    checked+=len(positions)
            assert triangles==lod["triangles"] and surfaces==lod["surfaces"],path
            assert triangles <= (5000 if asset["category"]=="building" else 2000),path
            # All model nodes are baked at the ground origin, with no baked rotation.
            for node in doc["nodes"]:
                assert not node.get("translation") and not node.get("rotation") and not node.get("scale"),path
            dimensions=[max(p[i] for p in bounds)-min(p[i] for p in bounds) for i in range(3)]
            assert all(abs(a-b)<.05 for a,b in zip(dimensions,asset["dimensions_m"])), (path, dimensions)
            if asset["category"]=="prop":
                assert abs(min(p[1] for p in bounds))<.025,path
        assert asset["lods"][1]["triangles"]<asset["lods"][0]["triangles"]
    print(f"ASSET_EXPORTS_OK assets={len(manifest['assets'])} lods={len(manifest['assets'])*2} vertices_checked={checked} texture_hashes=3")


if __name__=="__main__": main()
