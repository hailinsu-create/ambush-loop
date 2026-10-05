#!/usr/bin/env python3
"""Package an existing full Godot Web export for a 25 MiB static-file host.

Only transport changes: PCK chunks reassemble to the original SHA-256 before
Godot preloads the pack; WASM decompresses in the browser. Never builds art.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import shutil


def digest(data):
    return hashlib.sha256(data).hexdigest()


def package(export, destination, source_sha, game_tree):
    if destination.exists():
        raise ValueError("Use a new destination to preserve prior bundle evidence")
    destination.mkdir(parents=True)
    pack = (export / "index.pck").read_bytes()
    parts = []
    chunk_size = 24 * 1024 * 1024
    for i, offset in enumerate(range(0, len(pack), chunk_size)):
        name = f"index.pck.part{i:02d}"
        data = pack[offset:offset + chunk_size]
        (destination / name).write_bytes(data)
        parts.append({"path": name, "bytes": len(data), "sha256": digest(data)})
    pack_info = {"bytes": len(pack), "sha256": digest(pack), "parts": parts}
    assert b"".join((destination / x["path"]).read_bytes() for x in parts) == pack
    for path in sorted(export.iterdir()):
        if path.name == "index.pck":
            continue
        if path.name == "index.wasm":
            raw = path.read_bytes()
            data = gzip.compress(raw, compresslevel=9, mtime=0)
            assert gzip.decompress(data) == raw
            (destination / (path.name + ".gz")).write_bytes(data)
        elif path.is_file():
            shutil.copy2(path, destination / path.name)

    html = destination / "index.html"
    text = html.read_text()
    marker = "const engine = new Engine(GODOT_CONFIG);"
    assert text.count(marker) == 1
    # Keep the official startGame path, progress/error UI and main-pack argument.
    # Its public preloadFile API accepts a buffer; intercept just this pack URL.
    wasm_info = {"bytes": (export / "index.wasm").stat().st_size,
                 "sha256": digest((export / "index.wasm").read_bytes())}
    loader = """
\tconst packTransport = __PACK_INFO__;
\tconst wasmTransport = __WASM_INFO__;
\tconst originalFetch = window.fetch.bind(window);
\tconst wasmURL = new URL('index.wasm', document.baseURI).href;
\twindow.fetch = async function (input, init) {
\t\tconst url = new URL(input instanceof Request ? input.url : input, document.baseURI).href;
\t\tif (url !== wasmURL) return originalFetch(input, init);
\t\tif (typeof DecompressionStream === 'undefined') throw new Error('This game needs a browser with gzip DecompressionStream support.');
\t\tconst response = await originalFetch('index.wasm.gz', init);
\t\tif (!response.ok) throw new Error('Engine download failed (' + response.status + ')');
\t\tconst bytes = await new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
\t\tconst hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
\t\tif (bytes.byteLength !== wasmTransport.bytes || hash !== wasmTransport.sha256) throw new Error('Engine download integrity check failed. Please reload.');
\t\treturn new Response(bytes, {headers: {'Content-Type': 'application/wasm', 'Content-Length': String(bytes.byteLength)}});
\t};
\tconst originalPreloadFile = engine.preloadFile.bind(engine);
\tengine.preloadFile = async function (file, path) {
\t\tif (file !== 'index.pck') return originalPreloadFile(file, path);
\t\tconst pack = new Uint8Array(packTransport.bytes);
\t\tlet offset = 0;
\t\tfor (const part of packTransport.parts) {
\t\t\tconst response = await fetch(part.path, {credentials: 'same-origin'});
\t\t\tif (!response.ok) throw new Error('Game download failed: ' + part.path + ' (' + response.status + ')');
\t\t\tconst bytes = new Uint8Array(await response.arrayBuffer());
\t\t\tif (bytes.length !== part.bytes) throw new Error('Incomplete game download: ' + part.path);
\t\t\tpack.set(bytes, offset);
\t\t\toffset += bytes.length;
\t\t}
\t\tconst hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', pack)), b => b.toString(16).padStart(2, '0')).join('');
\t\tif (offset !== packTransport.bytes || hash !== packTransport.sha256) throw new Error('Game download integrity check failed. Please reload.');
\t\treturn originalPreloadFile(pack.buffer, path);
\t};
""".replace("__PACK_INFO__", json.dumps(pack_info, separators=(",", ":"))).replace(
        "__WASM_INFO__", json.dumps(wasm_info, separators=(",", ":")))
    html.write_text(text.replace(marker, marker + loader))
    (destination / "_headers").write_text(
        "/index.wasm.gz\n  Content-Type: application/gzip\n"
        "/index.pck.part*\n  Content-Type: application/octet-stream\n"
        "/index.html\n  Cache-Control: no-cache\n"
    )
    files = [{"path": p.name, "bytes": p.stat().st_size, "sha256": digest(p.read_bytes())}
             for p in sorted(destination.iterdir()) if p.is_file()]
    assert all(x["bytes"] <= 25 * 1024 * 1024 for x in files)
    manifest = {"source_sha": source_sha, "game_tree": game_tree, "pck": pack_info,
                "full_Title_entry": True, "files": files,
                "wasm_raw_sha256": digest((export / "index.wasm").read_bytes()),
                "all_stored_files_under_25MiB": True}
    (destination / "game-build.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("export", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--game-tree", required=True)
    args = parser.parse_args()
    print(json.dumps(package(args.export, args.destination, args.source_sha, args.game_tree), indent=2))
