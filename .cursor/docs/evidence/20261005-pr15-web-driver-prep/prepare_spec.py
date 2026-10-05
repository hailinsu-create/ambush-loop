#!/usr/bin/env python3
"""Source-only driver specification. No engine, browser, fixture or upload calls."""
import datetime
import hashlib
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[4]
DOCS = ROOT / ".cursor/docs"
EVIDENCE = pathlib.Path(__file__).resolve().parent
SOURCE = "dab870595175eed37a6d2a012bc69a76062d48b0"
TREE = "4f49a7c9cb5a789fbb570bceb947eab7df2eb54a"
QA_HEAD = "b46c31c008ae8dea700b3c36ad9b514e68b7e1ac"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


start = utc()
assert git("rev-parse", SOURCE + ":ambush_loop").decode().strip() == TREE
assert git("rev-parse", "HEAD:ambush_loop").decode().strip() == TREE
source_paths = [
    "scripts/first_visit_journey_test.gd",
    "scripts/title_menu_viewport_test.gd",
    "scripts/main.gd",
    "scripts/title.gd",
    "scripts/game_settings.gd",
    "scripts/web_config_store.gd",
    "scripts/level/level_def.gd",
    "scripts/simulation/sim_clock.gd",
    "scripts/replay/battle_log.gd",
    "scripts/replay/replay_player.gd",
    "scripts/ui/night_handoff.gd",
    "scripts/ui/tutorial_overlay.gd",
    "scripts/ui/pause_overlay.gd",
    "scripts/ui/credits_overlay.gd",
]
pins = []
text_by_path = {}
for path in source_paths:
    full = "ambush_loop/" + path
    data = git("show", SOURCE + ":" + full)
    text_by_path[path] = data.decode()
    pins.append({"path": full, "git_blob": git("rev-parse", SOURCE + ":" + full).decode().strip(),
                 "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})

rows = [
    ("yard", [1, 2, 5], [90, 180, 180], 2),
    ("warehouse", [1, 3, 5], [180, 0, 180], 2),
    ("pump", [1, 4, 5], [90, 0, 180], 2),
    ("railcut", [1, 4, 5], [270, 270, 180], 2),
    ("depot", [1, 4, 5], [270, 270, 180], 2),
    ("radio", [1, 4, 5], [270, 90, 270], 3),
]
missions = []
for i, (level, covers, facing, waves) in enumerate(rows):
    match = re.search(r"static func make_" + level + r"\(\).*?(?=\nstatic func |\Z)",
                      text_by_path["scripts/level/level_def.gd"], re.S)
    assert match, level
    wave_block = re.search(r"l\.waves = \[(.*?)\n\t\]", match[0], re.S)
    assert wave_block, level
    actual_waves = len(re.findall(r"\n\t\t\[", wave_block[1]))
    assert actual_waves == waves, (level, actual_waves)
    assert re.search('\\["' + level + '"' + r",\s*" + re.escape(str(covers).replace(" ", "")),
                     text_by_path["scripts/first_visit_journey_test.gd"]), level
    pack = re.search(r"l\.has_ammo_pack = (true|false)", match[0])[1] == "true"
    assert pack == (level != "yard")
    missions.append({
        "level": level, "wave_count": waves, "wave_ids": list(range(waves)),
        "cover_array_indices_by_operator": covers, "facing_degrees_by_operator": facing,
        "collect": [{"family": family, "operator_index": op}
                    for family, op in [("rifle", 0), ("mg", 1), ("scout", 2), ("grenade", 0)]]
                   + ([{"family": "mine", "operator_index": 0}] if level in ["depot", "radio"] else []),
        "ammo_pack_operator": (0 if level == "railcut" else 1) if pack else None,
        "scout_policy_inputs": ([{"operator_index": 0, "input": "I -> original auto button off -> close"}]
                                if level == "railcut" else
                                [{"operator_index": 1, "input": "F"}] if level == "warehouse" else []),
        "scout_mine_cell": [7, 11] if level in ["depot", "radio"] else None,
        "sweep_loot_operator": 2 if level == "railcut" else 0,
        "first_sweep_authored_ammo_operator": 1 if level in ["warehouse", "pump", "railcut"] else None,
        "first_sweep_mine_cell": [24, 5] if level == "warehouse" else None,
        "next_level": rows[i + 1][0] if i + 1 < len(rows) else None,
        "expected_after_natural_win": {
            "cleared": [r[0] for r in rows[:i + 1]],
            "unlocked": [r[0] for r in rows[:min(i + 2, len(rows))]],
            "continue_level": rows[i + 1][0] if i + 1 < len(rows) else None,
            "complete": i == len(rows) - 1,
        },
        "producer_status": "UNRUN", "whole_1x_status": "UNRUN", "whole_2x_status": "UNRUN",
        "progress_reload_status": "UNRUN",
    })

spec = {
    "schema": 1, "kind": "source_only_fresh_web_native_input_driver_contract",
    "status": "SOURCE_PLAN", "driver_implemented": False, "observer_implemented": False,
    "runtime_started": False, "gpt_plan_review": "unavailable",
    "window": {"owner": "independent_storage_QA", "root_engine_browser_allowed": False,
               "next_start_requires": "parent QA END and explicit window return",
               "qa_worktree_head_frozen": QA_HEAD},
    "candidate": {
        "source_commit": SOURCE, "game_tree": TREE, "engine": "4.7.2.stable.official.ed1daf0bf",
        "original_entry": "res://scenes/title.tscn", "viewport_css": [1280, 720], "device_pixel_ratio": 1,
        "release_directory": "/workspace/pr15-web-artifacts/" + SOURCE + "/release",
        "release_pck": {"bytes": 38082080, "sha256": "2d8eac7f8be1d7931762f5c31364c5695eef912d23fd193a7389eb967af4c0b6"},
        "wasm": {"bytes": 39514754, "sha256": "fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0"},
        "site_source_commit": "aa19d5b03c014c3483a2b98320018ea3e4e02042",
        "site_version": "appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_0011120092a88191bf67cace12146522",
        "production_origin_browser_acceptance": "UNRUN_BLOCKED_CONNECT",
        "fixture_pck_sha256": None, "fixture_bridge_sha256": None,
        "fixture_identity_rule": "enumerate every PCK difference; never claim byte equality with release PCK",
    },
    "source_strategy_pins": pins,
    "profile": {"fresh_root_owned": True, "persistent_single_campaign": True,
                "origin_and_path_fixed": True, "import_or_seed": False,
                "clear_user_or_independent_QA_storage": False,
                "close_reopen_checkpoints": ["after_yard_next_tutorial", "after_radio_credits"]},
    "trusted_input_allowlist": ["CDP keyboard press/down/up", "CDP mouse move/click/down/up/wheel"],
    "forbidden_actions": ["direct pressed.emit", "direct load_level/raid_force_alarm/record_win/mark_tutorial_seen",
                          "phase/tick/HP/ammo/resources/facing assignments", "sim_step/process/manual replay advance",
                          "DOM dispatchEvent/Input.parse_input_event", "old web_qa_bridge mutations", "force_fs_sync"],
    "observer_rpc_allowlist": ["state", "controls", "project_targets", "copy_record_bytes", "fingerprints"],
    "observer_writes": "own reply/serialization buffers and diagnostic counters only",
    "semantic_controls": ["title_start", "title_continue", "mission_row:<level>", "brief_go",
                          "tutorial_next", "alarm", "pause", "speed", "tool", "pack",
                          "backpack_auto", "backpack_close", "replay", "scrub",
                          "camera_clockwise", "handoff_cta", "pause_title", "credits_scroll", "credits_back"],
    "observer_state_contract": ["scene/level/phase/modals", "attempt_id/wave_id/main.run_id",
                                "sim.tick/speed/paused/_accum", "original operators/inventory/stashes/loot/covers/mines",
                                "replay.scrub_tick/max_tick/speed/playing", "original GameSettings reads",
                                "original cfg texts and public checkpoint value/hash", "present identity and input trace"],
    "world_target_rules": {"read_only_projection": "rig.project_logic",
                           "read_only_pick": "pick_at/pointer_over_ui; audit getter implementation before use",
                           "coordinate_map": "CSS -> canvas -> logical; account DPR/letterbox and sent pixel rounding",
                           "max_original_clockwise_camera_clicks": 12,
                           "stash_height": 0.55, "cover_height": 0.08, "loot_height": 0.12,
                           "ground_height": 0.02, "ground_neighbor_pixel_checks": 4},
    "facing": {"mg_quantum": 8, "other_quantum": 15, "max_actual_key_turns": 24,
               "tolerance": "quantum/2+0.01; actual A/D only"},
    "mine": {"walk_offset_cell": [1, 0], "max_distance_logic": 64,
             "original_tool_cycle": ["DEPLOY", "TRIPWIRE", "DEPLOY"],
             "assert": "carried mines -1 and raid_mines +1 through actual ground click"},
    "sweep": {"max_original_uncollected_loot_attempts": 20, "order": "original loot_piles order",
              "observe": "natural collection, original loot event, actual resources and walking completion",
              "redeploy_before_next_wave": True},
    "deadlines_wall_seconds": {"ui_or_walk": 120, "natural_alert_wave": 300, "level_producer_total": 900,
                               "max_original_FAILED_retries_per_level": 2,
                               "retry_budget_is_inside_level_total": True,
                               "whole": "max(180,6*(playback_terminal_tick/60)/rate+30)",
                               "clock": "controller monotonic wall; no quiet extension or forced terminal"},
    "initial_entry": ["fresh Title rows/Continue disabled", "original Start/yard row/brief_go",
                      "all original tutorial pages", "knife-only SCOUT", "original settings UI + restore standard"],
    "missions": missions,
    "continuous_boundary_order": ["natural WON and copy original record", "whole1x and whole2x; Space -> WON",
                                  "original Continue loads next SCOUT then handoff", "original handoff CTA",
                                  "all next first-visit tutorial pages", "Esc -> original pause_title",
                                  "Title rows/config/checkpoint", "same-origin reload",
                                  "original Title Continue -> new knife-only SCOUT attempt"],
    "preview_attempts": "record as abandoned-preview after tutorial/reload; never stitch into winning attempt",
    "final_boundary": ["radio WON and record/whole", "original Continue -> credits",
                       "original wheel scroll/back", "Title reload/reopen: six cleared/unlocked, complete, Continue disabled"],
    "record": {"format": "original Godot var_to_bytes; preserve Variant/Vector types",
               "fields": ["attempt_id", "events", "snapshots", "terminal_tick", "terminal_reason",
                          "playback_schema", "playback_snapshots", "playback_terminal_tick"],
               "copy_when": "natural WON before any level or scene change",
               "each_copy_has_sha256": True, "new_completed_records": 6, "winning_waves": 13,
               "all_waves_per_record_same_attempt": True,
               "failed_attempts_preserved_not_counted": True,
               "original_a05_dependency": False},
    "whole": {"rates": [1, 2], "original_default_rate": 2,
              "order": ["original ReplayButton", "original pause", "original desired speed input",
                        "original slider minimum", "observe paused/tick0/rate", "original resume",
                        "natural terminal and playing=false"],
              "seek_focus_checks_are_separate": True,
              "record_bytes_and_domain_fingerprints_unchanged": True,
              "callback_terminal_time_separate_from_poll_and_capture": True,
              "checks": ["monotonic playback time", "stable attempt/wave/seq/event_id", "continuous frame_seq",
                         "latest same-tick snapshot", "future-event cutoff", "3D roots/bones/weapons/tools/source identity"]},
    "evidence": {"per_level_seal": True, "statuses": ["PASS", "FAIL", "BLOCKED", "UNRUN"],
                 "unknown_is_not_zero": True,
                 "retain": ["fixed source/fixture/browser identity", "trusted input trace and action pre/post identity",
                            "natural failed and successful attempts", "original record bytes/hashes",
                            "console/network", "actual phase/present screenshots", "cfg/public checkpoint/reload reads",
                            "START/END/actual exit and wall durations"]},
    "execution_order_after_window_return": ["observer source audit and fixture identity gate", "yard bounded packet/seal",
                                           "same profile warehouse/pump/railcut/depot/radio packets/seals"],
    "not_proved_by_this_spec": ["fresh Web natural 13 waves", "six new records or whole1x/2x",
                               "production origin", "stranger playtest", "touch lifecycle", "ears audio",
                               "fullsmoke/all-art/FINAL", "A3 frame budget", "APK", "device performance"],
    "library": {"status": "BLOCKED_NO_UPLOAD_IDS", "original_batch_files": 8,
                "host": "chatgpt.com", "path": "/backend-api/wham/apps", "runtime_endpoint_override": False,
                "failure_stage": "tools/list discovery before first upload mutation",
                "original_stderr": "library upload failed: hosted apps tools/list request failed: network",
                "later_read_only_diagnostic": "HTTPS proxy CONNECT403; not original stderr or origin response",
                "prepared_tools_surfaced": True, "single_fast_path_for_this_batch": False,
                "resume_rule": "official helper route restored then unchanged ordered eight-file helper; no bypass"},
}
assert len(missions) == 6 and sum(m["wave_count"] for m in missions) == 13
assert len(spec["record"]["fields"]) == 8
assert not spec["runtime_started"]
spec_path = DOCS / "AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json"
spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n")
reloaded = json.loads(spec_path.read_text())
assert reloaded == spec
receipt = {"kind": "source_only_preparation", "start": start, "end": utc(), "actual_exit": 0,
           "argv": ["python3", str(pathlib.Path(__file__).resolve())],
           "base_head": git("rev-parse", "HEAD").decode().strip(),
           "source_commit": SOURCE, "game_tree": TREE, "pinned_source_files": len(pins),
           "source_verified_level_counts": {m["level"]: m["wave_count"] for m in missions},
           "source_total_waves": sum(m["wave_count"] for m in missions),
           "driver_runtime_status": "UNRUN", "observer_runtime_status": "UNRUN",
           "engine_browser_export_upload_calls": 0,
           "spec_bytes": spec_path.stat().st_size,
           "spec_sha256": hashlib.sha256(spec_path.read_bytes()).hexdigest()}
(EVIDENCE / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt, ensure_ascii=False))
