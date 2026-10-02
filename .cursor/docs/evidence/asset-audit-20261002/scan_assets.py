#!/usr/bin/env python3
"""Read-only inventory of tracked Ambush Loop source assets; no engine required.

Run from any directory; JSON goes to stdout. Mesh statistics sum mesh definitions,
not scene instances or measured draw calls. This does not validate visual quality.
"""

import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[4]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def fingerprint(path):
    data = (ROOT / path).read_bytes()
    return {"path": path, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def glb_inventory(path):
    data = (ROOT / path).read_bytes()
    magic, version, length = struct.unpack_from("<III", data)
    if magic != 0x46546C67 or version != 2 or length != len(data):
        raise ValueError(f"Invalid GLB header: {path}")
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != 0x4E4F534A:
        raise ValueError(f"Missing initial JSON chunk: {path}")
    model = json.loads(data[20:20 + chunk_length])
    accessors = model.get("accessors", [])
    primitives = [p for m in model.get("meshes", []) for p in m["primitives"]]
    vertices = triangles = uv_primitives = 0
    for primitive in primitives:
        attributes = primitive["attributes"]
        vertex_count = accessors[attributes["POSITION"]]["count"]
        vertices += vertex_count
        index_count = accessors[primitive["indices"]]["count"] if "indices" in primitive else vertex_count
        if primitive.get("mode", 4) == 4:
            triangles += index_count // 3
        if any(name.startswith("TEXCOORD_") for name in attributes):
            uv_primitives += 1
    return {
        **fingerprint(path),
        "meshes": len(model.get("meshes", [])),
        "primitives": len(primitives),
        "triangles_mesh_definition_sum": triangles,
        "vertices_mesh_definition_sum": vertices,
        "materials": len(model.get("materials", [])),
        "textures": len(model.get("textures", [])),
        "primitives_with_uv": uv_primitives,
        "skins": len(model.get("skins", [])),
        "animations": len(model.get("animations", [])),
    }


def main():
    paths = git("ls-files").splitlines()
    source_models = [glb_inventory(p) for p in paths if p.startswith("ambush_loop/ArtSource/") and p.endswith(".glb")]
    code_paths = [p for p in paths if p.startswith("ambush_loop/") and Path(p).suffix in {".gd", ".tscn", ".godot", ".tres"}]
    references = {}
    for path in code_paths:
        for line_number, line in enumerate((ROOT / path).read_text(encoding="utf-8").splitlines(), 1):
            for resource in re.findall(r'res://[^"\s)]+', line):
                references.setdefault(resource, []).append({"path": path, "line": line_number})
    runtime_images = []
    for path in paths:
        if path.startswith("ambush_loop/art/") and path.endswith(".png"):
            data = (ROOT / path).read_bytes()
            if data[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError(f"Invalid PNG: {path}")
            width, height = struct.unpack_from(">II", data, 16)
            resource = "res://" + path.removeprefix("ambush_loop/")
            runtime_images.append({**fingerprint(path), "width": width, "height": height, "references": references.get(resource, [])})
    cue_text = (ROOT / "ambush_loop/scripts/sfx/sfx_bus.gd").read_text(encoding="utf-8")
    cue_start = cue_text.index("const CUES := [")
    cues = re.findall(r'"([^\"]+)"', cue_text[cue_start:cue_text.index("\n]", cue_start)])
    game_media = [p for p in paths if p.startswith("ambush_loop/") and "/docs/" not in p and "/ArtSource/" not in p]
    inspected_images = [
        ".cursor/docs/evidence/20261002/16_scout_yard_ref.png",
        ".cursor/docs/evidence/20261002/17_alert_yard_w1.png",
        ".cursor/docs/evidence/20261002/30_scout_radio_empty.png",
        "ambush_loop/ArtSource/yard_crate_turnaround.png",
        "ambush_loop/ArtSource/sandbag_turnaround.png",
        "ambush_loop/ArtSource/field_radio_turnaround.png",
    ]
    report = {
        "schema_version": 1,
        "date": "2026-10-02",
        "source_commit": git("rev-parse", "HEAD"),
        "scope": "Tracked source assets and direct resource references; current-run static inspection with previously archived images. No new gameplay or audio playback verification.",
        "summary": {
            "source_glb_count": len(source_models),
            "runtime_look_png_count": len(runtime_images),
            "model_texture_count": sum(m["textures"] for m in source_models),
            "model_primitives_with_uv": sum(m["primitives_with_uv"] for m in source_models),
            "model_primitive_count": sum(m["primitives"] for m in source_models),
            "model_triangles_mesh_definition_sum": sum(m["triangles_mesh_definition_sum"] for m in source_models),
            "model_animation_count": sum(m["animations"] for m in source_models),
            "model_skin_count": sum(m["skins"] for m in source_models),
            "procedural_audio_cue_count": len(cues),
        },
        "source_models": source_models,
        "runtime_images": runtime_images,
        "direct_model_references": {k: v for k, v in references.items() if Path(k).suffix in {".glb", ".gltf"}},
        "tracked_audio_files_outside_docs_and_art_source": [p for p in game_media if Path(p).suffix.lower() in {".wav", ".ogg", ".mp3", ".flac"}],
        "tracked_font_files_outside_docs_and_art_source": [p for p in game_media if Path(p).suffix.lower() in {".ttf", ".otf", ".woff", ".woff2"}],
        "procedural_audio_cues": cues,
        "inspected_image_sources": [fingerprint(p) for p in inspected_images],
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
