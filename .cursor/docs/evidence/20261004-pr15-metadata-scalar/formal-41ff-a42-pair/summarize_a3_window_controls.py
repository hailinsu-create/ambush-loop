#!/usr/bin/env python3
"""Validate sealed Window controls and report raw cadence/block spread outside timing."""
import argparse
import csv
import hashlib
import json
import math
import pathlib
import re
import statistics

CADENCE_COLUMNS = ["engine_frame", "sample_seq", "ticks_usec", "interval_usec", "included",
                   "exclusion_code", "render_counters_ready", "draw_calls", "primitives",
                   "render_objects", "static_bytes", "object_count", "node_count",
                   "resource_count", "process_seconds", "sampler_usec"]
ORDER = [False, True, True, False, True, False, False, True]
COLLECTOR_COLUMNS = ["frame", "ticks_usec", "interval_usec", "segment", "measured", "exclusion",
    "level_id", "attempt_id", "wave_id", "phase", "recorded_phase", "frame_seq", "local_tick", "playback_tick",
    "replay", "replay_speed", "sim_paused", "yaw_deg", "pitch_deg", "view_size", "policy",
    "shot_active", "shot_cache", "shot_reject_geometry", "shot_reject_socket", "tool_active",
    "tool_reject_geometry", "dust_active", "dust_reject_geometry", "render_setup_ms", "collector_usec",
    "presenter_valid", "main_auto_process", "tree_paused", "render_counters_ready", "collector_storage_bytes",
    "window_width", "window_height", "content_scale", "max_fps", "vsync",
    "TIME_PROCESS", "TIME_PHYSICS_PROCESS", "RENDER_TOTAL_DRAW_CALLS_IN_FRAME",
    "RENDER_TOTAL_PRIMITIVES_IN_FRAME", "RENDER_TOTAL_OBJECTS_IN_FRAME", "RENDER_TEXTURE_MEM_USED",
    "RENDER_BUFFER_MEM_USED", "RENDER_VIDEO_MEM_USED", "MEMORY_STATIC", "OBJECT_COUNT",
    "OBJECT_NODE_COUNT", "OBJECT_RESOURCE_COUNT", "OBJECT_ORPHAN_NODE_COUNT",
    "PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH", "PIPELINE_COMPILATIONS_SURFACE",
    "PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]
COLLECTOR_TEXT = {"segment", "exclusion", "level_id", "attempt_id", "policy"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def distribution(values):
    values = sorted(values)
    if not values:
        raise ValueError("No accepted raw samples")
    def percentile(q):
        rank = (len(values) - 1) * q
        low, high = math.floor(rank), math.ceil(rank)
        return values[low] + (values[high] - values[low]) * (rank - low)
    return {"n": len(values), "min": values[0], "median": statistics.median(values),
            "p95": percentile(.95), "p99": percentile(.99), "max": values[-1]}


def analyze(args):
    report_path = pathlib.Path(args.report).resolve(strict=True)
    root = report_path.parent
    project = pathlib.Path(args.project).resolve(strict=True)
    report = json.loads(report_path.read_text())
    log = pathlib.Path(args.log).read_text()
    if int(pathlib.Path(args.exit_file).read_text()) != 0 or re.search(r"^(?:ERROR:|SCRIPT ERROR:)", log, re.M):
        raise ValueError("Actual engine exit/E/S gate failed")
    if not re.search(r"A3_COLLECTOR_OVERHEAD_TEST checks=\d+ failures=0 windows=16", log):
        raise ValueError("Missing complete actual suite marker")
    if not report.get("complete") or report["failures"] or len(report["conditions"]) != 16:
        raise ValueError("Incomplete paired run")
    receipt_sha = report["receipt_sha256"]
    for proof in [report["source_proof_before"], report["source_proof_after"]]:
        if not proof.get("window_control_verified") or proof.get("receipt_sha256") != receipt_sha:
            raise ValueError("Fixed complete loaded-source provenance gate failed")

    def artifact(raw):
        path = (project / raw.removeprefix("res://")) if raw.startswith("res://") else pathlib.Path(raw)
        path = path.resolve(strict=True)
        if not path.is_relative_to(root):
            raise ValueError("Artifact escaped this immutable run root")
        return path

    families = {}
    all_receipts = []
    if {c["family"] for c in report["conditions"]} != {"full_buffer", "resident_callback"}:
        raise ValueError("Unexpected control family")
    if len({str(artifact(c["path"])) for c in report["conditions"]}) != 16:
        raise ValueError("Condition paths must be distinct")
    for family in ["full_buffer", "resident_callback"]:
        blocks = sorted((c for c in report["conditions"] if c["family"] == family), key=lambda c: c["index"])
        if [c["index"] for c in blocks] != list(range(8)) or [c["attached"] for c in blocks] != ORDER:
            raise ValueError("Missing ABBA/BAAB order")
        block_results = []
        collector_usec = []
        on_intervals, off_intervals = [], []
        on_sampler, off_sampler = [], []
        counter_signatures = []
        for block in blocks:
            if not block["valid"] or block["workload_before"] != report["canonical_workload"] or block["workload_after"] != report["canonical_workload"]:
                raise ValueError("Stationary source/camera/config mismatch")
            if block["receipt_sha256"] != receipt_sha:
                raise ValueError("Block receipt changed")
            raw = artifact(block["path"] + "/cadence.csv")
            metadata_path = artifact(block["path"] + "/cadence-metadata.json")
            metadata = json.loads(metadata_path.read_text())
            if metadata["receipt"] != {k: v for k, v in block.items() if k not in {"path", "cadence_sha256", "valid"}}:
                raise ValueError("Cadence metadata receipt differs from actual condition")
            if digest(raw) != block["cadence_sha256"] or digest(raw) != metadata["raw_sha256"] or metadata["run_incomplete"] or metadata["overflow_rows"]:
                raise ValueError("Cadence raw hash/completeness failed")
            with raw.open() as stream:
                reader = csv.DictReader(stream)
                if reader.fieldnames != CADENCE_COLUMNS:
                    raise ValueError("Cadence protocol header differs")
                rows = [{k: float(v) for k, v in row.items()} for row in reader]
            if len(rows) != metadata["rows"] or not all(math.isfinite(v) for row in rows for v in row.values()):
                raise ValueError("Raw width/count/finite gate failed")
            included = [r for r in rows if r["included"] == 1]
            if len(included) < 3 or len(included) != block["included_rows"]:
                raise ValueError("Insufficient accepted samples")
            if not all(r["render_counters_ready"] == 1 and r["exclusion_code"] == 0 and r["interval_usec"] > 0 for r in included):
                raise ValueError("Accepted unready/transition cadence")
            if any(r["sampler_usec"] < 0 for r in rows) or metadata["capacity"] != 32768 or metadata["payload_bytes"] != 32768 * 16 * 8:
                raise ValueError("Cadence buffer/timer contract differs")
            if not all(right["engine_frame"] > left["engine_frame"] and right["ticks_usec"] > left["ticks_usec"] for left, right in zip(rows, rows[1:])):
                raise ValueError("Nonmonotonic actual rendered frames")
            counters = {name: distribution([r[name] for r in included]) for name in ["draw_calls", "primitives", "render_objects"]}
            if any(stats["min"] <= 0 for stats in counters.values()):
                raise ValueError("Rendered scene counters require positive actual calibration")
            counter_signatures.append(tuple(stats["median"] for stats in counters.values()))
            intervals = [r["interval_usec"] for r in included]
            sampler_times = [r["sampler_usec"] for r in included]
            (on_intervals if block["attached"] else off_intervals).extend(intervals)
            (on_sampler if block["attached"] else off_sampler).extend(sampler_times)
            if block["attached"]:
                collector_raw = artifact(block["collector"]["path"] + "/raw.csv")
                collector_meta_path = artifact(block["collector"]["path"] + "/metadata.json")
                collector_meta = json.loads(collector_meta_path.read_text())
                if digest(collector_raw) != block["collector"]["raw_sha256"] or digest(collector_raw) != collector_meta["raw_sha256"]:
                    raise ValueError("Collector raw SHA mismatch")
                if not collector_meta["chunk_source_and_buffer_valid"] or not collector_meta["complete_buffer"] or collector_meta["run_incomplete"] or collector_meta["run_overflow_rows"] or collector_meta["overflow_rows"] or collector_meta["symbol_overflow"] or not collector_meta["receipt_stable"] or not collector_meta["warm_import_proof_complete"]:
                    raise ValueError("Collector chunk rejected")
                for proof in [collector_meta["metadata"]["source_proof_before"], collector_meta["source_proof_after"]]:
                    if not proof.get("verified") or proof.get("receipt_sha256") != receipt_sha:
                        raise ValueError("Collector fixed source receipt mismatch")
                with collector_raw.open() as stream:
                    reader = csv.DictReader(stream)
                    if reader.fieldnames != COLLECTOR_COLUMNS:
                        raise ValueError("Collector named column protocol differs")
                    collector_rows = [{k: v if k in COLLECTOR_TEXT else float(v) for k, v in row.items()} for row in reader]
                if len(collector_rows) != collector_meta["rows"] or len(collector_rows) != block["collector"]["rows"] or any(not math.isfinite(v) for row in collector_rows for k, v in row.items() if k not in COLLECTOR_TEXT):
                    raise ValueError("Collector raw count/finite gate failed")
                if any(row["collector_usec"] < 0 for row in collector_rows) or not all(right["frame"] > left["frame"] and right["ticks_usec"] > left["ticks_usec"] for left, right in zip(collector_rows, collector_rows[1:])):
                    raise ValueError("Collector duration/monotonicity gate failed")
                measured = [r for r in collector_rows if float(r["measured"]) == 1]
                if len(measured) < 3 or len(measured) != block["collector"]["measured_rows"] or not all(r["render_counters_ready"] == 1 and r["presenter_valid"] == 1 and r["main_auto_process"] == 0 and r["interval_usec"] > 0 and r["exclusion"] == "" for r in measured):
                    raise ValueError("Collector measured-row readiness gate failed")
                collector_usec.extend(float(r["collector_usec"]) for r in measured)
                all_receipts.extend([{"path": str(collector_raw), "sha256": digest(collector_raw)}, {"path": str(collector_meta_path), "sha256": digest(collector_meta_path)}])
            expected_payload = 32768 * 59 * 8 if (family == "resident_callback" or block["attached"]) else 0
            if block["collector_payload_bytes"] != expected_payload or block["common_sampler_payload_bytes"] != 32768 * 16 * 8:
                raise ValueError("Matched resident-buffer configuration differs")
            block_results.append({"index": block["index"], "attached": block["attached"], "raw_rows": len(rows),
                                  "interval_usec": distribution(intervals), "sampler_usec": distribution(sampler_times),
                                  "counters": counters, "rss_start_bytes": block["rss_start_bytes"],
                                  "rss_end_bytes": block["rss_end_bytes"], "static_start_bytes": block["static_start_bytes"],
                                  "actual_wall_seconds": block["actual_wall_seconds"]})
            all_receipts.extend([{"path": str(raw), "sha256": digest(raw)}, {"path": str(metadata_path), "sha256": digest(metadata_path)}])
        if len(set(counter_signatures)) != 1:
            raise ValueError("Paired median draw/primitives/objects differ; no matched-load inference")
        pairs = []
        for low in range(0, 8, 2):
            left, right = block_results[low:low + 2]
            on, off = (left, right) if left["attached"] else (right, left)
            delta = on["interval_usec"]["median"] - off["interval_usec"]["median"]
            pairs.append({"on_index": on["index"], "off_index": off["index"],
                          "median_interval_delta_usec": delta,
                          "delta_percent": 100 * delta / off["interval_usec"]["median"],
                          "rss_start_delta_bytes": on["rss_start_bytes"] - off["rss_start_bytes"]})
        families[family] = {"baseline_interval_usec": distribution(off_intervals),
                            "attached_interval_usec": distribution(on_intervals),
                            "baseline_sampler_usec": distribution(off_sampler),
                            "attached_sampler_usec": distribution(on_sampler),
                            "collector_callback_usec": distribution(collector_usec),
                            "blocks": block_results, "adjacent_on_off_pairs": pairs,
                            "render_load_matching": "identical median draw/primitives/objects across eight blocks; per-block min/max/quantiles retained, not identical per-frame geometry proof",
                            "pair_delta_usec_spread": distribution([p["median_interval_delta_usec"] for p in pairs]),
                            "scope": "resident callback cost" if family == "resident_callback" else "buffer allocation plus callback; collector script preloaded in baseline"}
    return {"format": 1, "source_sha": report["source_sha"], "receipt_sha256": receipt_sha,
            "report_sha256": digest(report_path), "environment": report["environment"], "families": families,
            "artifacts": all_receipts,
            "quantiles": "linear interpolation at (n-1)q; adjacent block deltas preserve order spread, not independent-frame confidence intervals",
            "limitations": "stationary short warm controls only; monitor lag and allocator/RSS retention remain; sampler paid in both; never subtract callback usecs from intervals or infer Android FPS"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--exit-file", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    result = analyze(args)
    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    print(json.dumps({"source_sha": result["source_sha"], "families": list(result["families"]), "output": str(output), "matched_load_validated": True}))


if __name__ == "__main__":
    main()
