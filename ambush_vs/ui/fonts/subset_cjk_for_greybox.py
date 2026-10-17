#!/usr/bin/env python3
"""Subset Noto Sans CJK SC to glyphs used by greybox UI + weapons.csv. OFL-1.1 preserved."""
from __future__ import annotations

import csv
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_WOFF2 = os.path.join(ROOT, "NotoSansCJKsc-Regular.woff2")
OUT_WOFF2 = os.path.join(ROOT, "NotoSansCJKsc-GreyboxSubset.woff2")
WEAPONS = os.path.join(ROOT, "..", "..", "data", "weapons.csv")

# All Chinese / CJK strings currently shown in greybox UI (controller + scene + alerts).
UI_TEXT = """
布阵 SETUP 等待 WAIT 结算 RESULT
加载方案 已加载 可微调站位朝向后开始
警报：安静 起疑 区域警戒 全图警报
预设方案 A（高点） 预设方案 B（地雷）
点地面看谁能看见 开始等待 G2 G3 美术：开关
暂停 继续 倍速 手动起爆 重新开始 再来一局
美术 锥扇标记仍叠加
见首敌 地雷 越线标记 手动
标准伏击：是否 胜负：胜利失败 起爆 tick 条件
击杀 逃脱 无 警报档 原因
请先加载方案或放置队员 必须选择一个起爆条件
选中 拖拽设朝向 点格移动
格 可见观察者 可见
已请求手动起爆
被岗哨巡逻发现升至全图警报
起爆过早侧翼未入杀伤区 起爆过晚 敌人逃脱
清场但未达标准伏击成功 超时
院子 锥扇标记仍叠加
"""


def collect_codepoints() -> str:
	blob = UI_TEXT
	blob += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	blob += "：:·×?!.,()[]%/+-_<>\"' \n\t"
	if os.path.isfile(WEAPONS):
		with open(WEAPONS, encoding="utf-8") as f:
			blob += f.read()
	chars = {c for c in blob if len(c) == 1 and (ord(c) >= 32 or c in "\n\t")}
	return "".join(sorted(chars))


def main() -> int:
	if not os.path.isfile(SRC_WOFF2):
		print("missing source", SRC_WOFF2, file=sys.stderr)
		return 1
	text = collect_codepoints()
	unicodes = sorted({ord(c) for c in text})
	uni_arg = ",".join("U+%04X" % u for u in unicodes)
	pyft = os.path.expanduser("~/.local/bin/pyftsubset")
	if not os.path.isfile(pyft):
		pyft = shutil.which("pyftsubset") or "pyftsubset"
	# fontTools can read woff2 with brotli; output woff2
	cmd = [
		pyft,
		SRC_WOFF2,
		f"--unicodes={uni_arg}",
		"--layout-features=*",
		"--glyph-names",
		"--symbol-cmap",
		"--legacy-cmap",
		"--notdef-glyph",
		"--notdef-outline",
		"--recommended-glyphs",
		"--name-IDs=*",
		"--name-legacy",
		"--name-languages=*",
		"--flavor=woff2",
		f"--output-file={OUT_WOFF2}",
	]
	print("subset glyphs", len(unicodes), "->", OUT_WOFF2)
	subprocess.check_call(cmd)
	src_sz = os.path.getsize(SRC_WOFF2)
	out_sz = os.path.getsize(OUT_WOFF2)
	print(f"size {src_sz} -> {out_sz} ({100.0 * out_sz / src_sz:.1f}%)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
