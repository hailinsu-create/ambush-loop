extends RefCounted
class_name BriefingCopy

## P0-3: all Chinese briefing / first-time teaching strings live here.
## CI blacklist scans `all_teaching_texts()` — never use 高点/高处/谷仓/二层/制高.

const FORBIDDEN := ["高点", "高处", "谷仓", "二层", "制高"]

const TITLE := "今夜简报"

const SEC_GOAL := "目标"
const SEC_EXIT := "出口"
const SEC_BEATS := "五拍"

const GOAL_BODY := "全歼来犯，不放跑任何人。"
const EXIT_BODY := "北门、南门、东巷——任一有人逃脱即失败。"
const ASSIST_OFF := "还击辅助：关"
const ASSIST_ON := "还击辅助：开（每名敌人最多命中一次）"

## Beat chips: short name only (row of numbered tags).
const BEATS := [
	{"n": "1", "name": "侦察"},
	{"n": "2", "name": "搜集"},
	{"n": "3", "name": "布阵"},
	{"n": "4", "name": "等待"},
	{"n": "5", "name": "起爆"},
]

const BEAT_HINT := "侦察摸路线 · 搜集拾补给 · 布阵定站位 · 等待可调速 · 长按起爆开火"
const TIP := "点「知道了」关闭。随时点右上「?」可再打开。"
const TIP_PHONE := "「知道了」关闭 · 右上「?」再开"

## Flat BODY kept for tests / blacklist aggregation (all keywords present).
const BODY := """目标：全歼来犯，不放跑任何人。

三个出口：北门、南门、东巷。
任一有人逃脱即失败。

五拍流程：
1. 侦察——摸清路线与动静
2. 搜集——拾取补给，充实套件
3. 布阵——安排队员站位、朝向与起爆条件
4. 等待——静观其变，必要时调整朝向
5. 起爆——长按起爆，按预案开火

点「知道了」关闭。随时点右上「?」可再打开。"""

const DISMISS := "知道了"

const TIP_SCOUT := "侦察：点队员，再点格子移动；靠近箱子可开箱。"
const TIP_SETUP := "布阵：用工具栏放置队员，拖方向柄设定朝向。"
const TIP_WAIT := "等待：可暂停与调速；确认预案后长按起爆。"
const TIP_RESULT := "结算：查看复盘要点，可重来或再侦察。"

const TIP_CLOSE := "关闭"


static func all_teaching_texts() -> PackedStringArray:
	var out := PackedStringArray([
		TITLE, BODY, DISMISS,
		SEC_GOAL, SEC_EXIT, SEC_BEATS,
		GOAL_BODY, EXIT_BODY, ASSIST_OFF, ASSIST_ON, BEAT_HINT, TIP, TIP_PHONE,
		TIP_SCOUT, TIP_SETUP, TIP_WAIT, TIP_RESULT, TIP_CLOSE,
	])
	for b in BEATS:
		out.append("%s%s" % [b["n"], b["name"]])
		out.append(str(b["name"]))
	return out


static func assist_label(on: bool) -> String:
	return ASSIST_ON if on else ASSIST_OFF


static func phase_tip(phase_name: String) -> String:
	match phase_name:
		"scout":
			return TIP_SCOUT
		"setup":
			return TIP_SETUP
		"wait":
			return TIP_WAIT
		"result":
			return TIP_RESULT
		_:
			return ""


static func forbidden_hits(text: String) -> PackedStringArray:
	var hits: PackedStringArray = []
	for w in FORBIDDEN:
		if text.find(w) >= 0:
			hits.append(w)
	return hits
