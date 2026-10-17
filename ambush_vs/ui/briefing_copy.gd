extends RefCounted
class_name BriefingCopy

## P0-3: all Chinese briefing / first-time teaching strings live here.
## CI blacklist scans `all_teaching_texts()` — never use 高点/高处/谷仓/二层/制高.

const FORBIDDEN := ["高点", "高处", "谷仓", "二层", "制高"]

const TITLE := "今夜简报"

const BODY := """目标：全歼来犯，不放跑任何人。

三个出口：北门、南门、东巷——任一有人逃脱即失败。

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
	return PackedStringArray([
		TITLE, BODY, DISMISS,
		TIP_SCOUT, TIP_SETUP, TIP_WAIT, TIP_RESULT, TIP_CLOSE,
	])


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
