#!/usr/bin/env python3
"""Seal read-only source/engine/optional record bytes before an A3 test run."""
import argparse
import hashlib
import json
import pathlib
import subprocess


def digest(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def prepare(args: argparse.Namespace) -> dict:
    root = pathlib.Path(__file__).resolve().parents[2]
    project = root / "ambush_loop"
    def git(*items: str) -> str:
        return subprocess.check_output(["git", *items], cwd=root).decode().strip()
    if subprocess.run(["git", "diff", "--quiet", "HEAD", "--", "ambush_loop"], cwd=root).returncode:
        raise ValueError("Tracked project differs from HEAD; freeze and commit the candidate first")
    consumer = git("rev-parse", "HEAD")
    engine = pathlib.Path(args.engine).resolve(strict=True)
    files = []
    modes = {}
    for item in subprocess.check_output(["git","ls-tree","-rz","HEAD","--","ambush_loop"],cwd=root).decode().split("\0"):
        if item:
            info, name = item.split("\t",1)
            modes[name] = info.split(" ",1)[0]
    tracked = subprocess.check_output(["git", "ls-files", "-z", "--", "ambush_loop"], cwd=root)
    for item in tracked.decode().split("\0"):
        if not item:
            continue
        path = root / item
        if path.is_symlink() or not path.is_file():
            raise ValueError(f"Expected regular tracked project file: {item}")
        files.append({"path": path.relative_to(project).as_posix(), "mode": modes[item],
                      "bytes": path.stat().st_size, "sha256": digest(path)})
    imported = []
    if args.include_import_cache:
        for path in sorted((project/".godot/imported").rglob("*")):
            if path.is_file():
                imported.append({"path":str(path),"bytes":path.stat().st_size,"sha256":digest(path)})
        if not imported:
            raise ValueError("Requested imported cache proof but no imported files exist")
    records = []
    if args.record and not args.producer_sha:
        raise ValueError("--record requires explicit --producer-sha; filenames do not prove producer identity")
    for item in args.record:
        level, separator, raw_path = item.partition("=")
        if not separator or not level:
            raise ValueError("--record must be level=path")
        path = pathlib.Path(raw_path).resolve(strict=True)
        records.append({"level_id": level, "path": str(path), "bytes": path.stat().st_size,
                        "sha256": digest(path), "producer_commit": args.producer_sha,
                        "attribution": "caller-declared producer commit; actual original bytes verified"})
    if args.producer_sha:
        git("cat-file", "-e", f"{args.producer_sha}^{{commit}}")
    if git("rev-parse", "HEAD") != consumer or subprocess.run(
        ["git", "diff", "--quiet", "HEAD", "--", "ambush_loop"], cwd=root
    ).returncode:
        raise ValueError("Source changed during receipt creation")
    return {"format": 2, "consumer_commit": consumer, "consumer_game_tree": git("rev-parse", "HEAD:ambush_loop"),
            "consumer_build": "loose tracked source, official executable; no PCK",
            "tracked_project_clean": True, "source_root": str(project), "source_files": files,
            "engine": {"path": str(engine), "bytes": engine.stat().st_size, "sha256": digest(engine)},
            "producer_records": records,
            "imported_cache": imported,
            "cache_scope": "complete existing warm .godot/imported inventory verified; no cold asset import claim" if imported else "generated .godot import cache excluded; formal loaded-resource proof incomplete",
            "record_attribution_scope": "record hashes prove unchanged bytes; producer commit remains declared unless independently matched to its sealed author manifest"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--record", action="append", default=[])
    parser.add_argument("--producer-sha", default="")
    parser.add_argument("--include-import-cache", action="store_true")
    args = parser.parse_args()
    result = prepare(args)
    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"receipt": str(output), "consumer_commit": result["consumer_commit"],
                      "game_tree": result["consumer_game_tree"],
                      "source_files": len(result["source_files"]), "records": len(result["producer_records"]),
                      "imported_cache_files":len(result["imported_cache"]),
                      "receipt_sha256": digest(output)}))


if __name__ == "__main__":
    main()
