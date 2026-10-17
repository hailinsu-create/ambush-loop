#!/usr/bin/env python3
"""Generate ambush_vs/data/levels/yard.json from yard_paper_v1_1 ASCII."""
from __future__ import annotations

import json
from pathlib import Path

# North at top; row index = y. Lines are y=15 .. y=0.
ASCII_ROWS = [
    "#########NNNN###########",  # 15
    "####...TG.==.####.######",  # 14
    "####.C.TT.==.####.######",  # 13
    "####.P.#P.==.####.######",  # 12
    "###bbb#...==......######",  # 11
    "###bBB....==w.....######",  # 10
    "###bBB....==w..ww......#",  # 09
    "###bbb#.P.==...ww~~~~~.#",  # 08
    "####RR....==.LL.....~~~E",  # 07
    "####....ww==.LL.....~~~E",  # 06
    "####....ww==........~H.#",  # 05
    "####.P..Pw==.w.C..######",  # 04
    "####.....w==.w....######",  # 03
    "####......==......######",  # 02
    "####......==......######",  # 01
    "##########SSS###########",  # 00
]

KIND_MAP = {
    "#": ("wall", None, False),
    ".": ("ground", "ground", False),
    "=": ("road", "ground", False),
    "~": ("alley", "ground", False),
    "N": ("gate_n", "ground", False),
    "S": ("gate_s", "ground", False),
    "E": ("gate_e", "ground", False),
    "G": ("high", "high", False),
    "T": ("high", "high", False),
    "B": ("high", "high", False),
    "b": ("structure", None, False),
    "R": ("ramp", "ground", False),
    "L": ("high", "high", False),
    "w": ("ground", "ground", True),
    "C": ("ground", "ground", False),
    "H": ("ground", "ground", False),
    "P": ("ground", "ground", False),
}


def main() -> None:
    assert len(ASCII_ROWS) == 16
    assert all(len(r) == 24 for r in ASCII_ROWS)
    cells = []
    map_lines = []
    for i, row in enumerate(ASCII_ROWS):
        y = 15 - i
        map_lines.append(row)
        for x, ch in enumerate(row):
            kind, tier, low = KIND_MAP[ch]
            cell = {"x": x, "y": y, "kind": kind}
            if tier is not None:
                cell["tier"] = tier
            if low:
                cell["cover"] = {"height": "low", "blocks_los_same_level": True}
            cells.append(cell)
    # Paper v1.1 hard fix: (9,12) is solid # blocking G→L (ASCII row still ambiguous).
    for cell in cells:
        if cell["x"] == 9 and cell["y"] == 12:
            cell["kind"] = "wall"
            cell.pop("tier", None)
            cell.pop("cover", None)
            break
    # Road-side `w` at (12,9)/(12,10) blocks MP@(16,8)→column LOS; paper B still
    # claims standard ambush. Clear cover on those two cells (see W2_DISCREPANCIES).
    for cell in cells:
        if (cell["x"], cell["y"]) in ((12, 9), (12, 10)):
            cell.pop("cover", None)
    level = {
        "id": "yard",
        "version": 2,
        "title": "院子",
        "night": True,
        "ambush_targets": ["E1", "E2", "E3", "E4", "F1", "F2"],
        "default_trigger": {
            "type": "see_first_enemy",
            "bind": "op_kar_L",
            "plan_id": "A",
        },
        "grid": {
            "width": 24,
            "height": 16,
            "meters_per_cell": 1,
            "origin": "x0_west_y0_south",
        },
        "map_ascii": "\n".join(map_lines),
        "high_slots": [
            {
                "id": "barn_l2",
                "cells": [
                    {"x": 4, "y": 9},
                    {"x": 5, "y": 9},
                    {"x": 4, "y": 10},
                    {"x": 5, "y": 10},
                ],
                "enter_cost_s": 2,
                "silhouette_mul": 1.5,
            },
            {
                "id": "low_wall_pad",
                "cells": [
                    {"x": 13, "y": 6},
                    {"x": 14, "y": 6},
                    {"x": 13, "y": 7},
                    {"x": 14, "y": 7},
                ],
                "enter_cost_s": 2,
                "silhouette_mul": 1.5,
            },
        ],
        "exits": [
            {
                "id": "south_gate",
                "cells": [{"x": 10, "y": 0}, {"x": 11, "y": 0}, {"x": 12, "y": 0}],
                "fail_on_enemy_escape": True,
            },
            {
                "id": "east_alley",
                "cells": [{"x": 23, "y": 6}, {"x": 23, "y": 7}],
                "fail_on_enemy_escape": True,
            },
        ],
        "enemies": {
            "march_speed_cells_per_s": 0.5,
            "routes": [
                {
                    "id": "main_road",
                    "waypoints": [{"x": 11, "y": 14}, {"x": 11, "y": 0}],
                },
                {
                    "id": "east_flank",
                    "waypoints": [
                        {"x": 23, "y": 7},
                        {"x": 18, "y": 8},
                        {"x": 11, "y": 8},
                    ],
                },
            ],
            "alarm_route": {
                "id": "alarm_combat_entry",
                "waypoints": [
                    {"x": 11, "y": 14},
                    {"x": 11, "y": 10},
                    {"x": 12, "y": 9},
                ],
            },
            "spawns": [
                {"id": "E1", "route_id": "main_road", "enter_t_s": 0, "group": "main"},
                {"id": "E2", "route_id": "main_road", "enter_t_s": 3, "group": "main"},
                {"id": "E3", "route_id": "main_road", "enter_t_s": 6, "group": "main"},
                {"id": "E4", "route_id": "main_road", "enter_t_s": 9, "group": "main"},
                {
                    "id": "F1",
                    "route_id": "east_flank",
                    "enter_t_s": 4,
                    "group": "flank",
                },
                {
                    "id": "F2",
                    "route_id": "east_flank",
                    "enter_t_s": 4,
                    "group": "flank",
                    "path_offset_cells": -1.0,
                },
            ],
        },
        "sentries": [
            {
                "id": "gatehouse_G",
                "x": 8,
                "y": 14,
                "tier": "high",
                "cone": {"facing_deg": -59.0, "angle_deg": 50.0, "range_cells": 8.0},
                "threatens_slots": ["low_wall_pad"],
                "alert_route": {"facing_deg": -54.0},
            }
        ],
        "patrols": [
            {
                "id": "west_patrol",
                "waypoints": [
                    {"x": 6, "y": 12},
                    {"x": 6, "y": 8},
                    {"x": 6, "y": 4},
                    {"x": 8, "y": 4},
                    {"x": 8, "y": 8},
                    {"x": 8, "y": 12},
                ],
                "edge_s": 6.0,
                "cone": {"facing_deg": 0.0, "angle_deg": 50.0, "range_cells": 6.0},
                "threatens_slots": ["west_cover_8_5"],
                "alert_route": {
                    "waypoints": [
                        {"x": 8, "y": 8},
                        {"x": 8, "y": 5},
                        {"x": 9, "y": 5},
                    ],
                    "edge_s": 4.0,
                    "facing_deg": 0.0,
                },
            }
        ],
        "supplies": [
            {
                "id": "crate_nw",
                "x": 5,
                "y": 13,
                "visibility": "open",
                "contents": [{"weapon_id": "ammo_7.92", "amount": 10}],
            },
            {
                "id": "crate_se",
                "x": 15,
                "y": 4,
                "visibility": "open",
                "contents": [{"weapon_id": "ammo_9mm", "amount": 16}],
            },
            {
                "id": "hidden_H",
                "x": 21,
                "y": 5,
                "visibility": "hidden",
                "requires_scout_region": "east_alley",
                "contents": [{"weapon_id": "mg42", "amount": 1}],
            },
        ],
        "loadout_start": {
            "weapons": [
                {"weapon_id": "kar98k", "count": 1},
                {"weapon_id": "mp40", "count": 1},
                {"weapon_id": "mine", "count": 1},
                {"weapon_id": "grenade", "count": 2},
            ],
            "ammo_pools": [
                {"pool_id": "7.92", "rounds": 30},
                {"pool_id": "9mm", "rounds": 32},
            ],
        },
        "ambush_slots": [
            {"id": "barn_op", "x": 5, "y": 9, "height": "high"},
            {"id": "low_wall_pad", "x": 13, "y": 7, "height": "high"},
            {"id": "south_hold", "x": 11, "y": 2, "height": "ground"},
            {"id": "west_cover_8_5", "x": 8, "y": 5, "height": "ground"},
            {"id": "east_cover_16_8", "x": 16, "y": 8, "height": "ground"},
        ],
        "plans": [
            {
                "id": "A",
                "label": "高点压制",
                "expect": "win",
                "trigger": {"type": "see_first_enemy", "bind": "op_kar_L"},
                "t0_s": 14,
            },
            {
                "id": "B",
                "label": "地面交叉+地雷",
                "expect": "win",
                "trigger": {"type": "mine_detonate", "bind": "mine_11_6"},
                "t0_s": 16,
            },
        ],
        "fail": {
            "enemy_escape_exits": ["south_gate", "east_alley"],
            "squad_wipe": True,
        },
        "cells": cells,
    }

    out = Path(__file__).resolve().parents[1] / "ambush_vs" / "data" / "levels" / "yard.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(level, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out} cells={len(cells)}")


if __name__ == "__main__":
    main()
