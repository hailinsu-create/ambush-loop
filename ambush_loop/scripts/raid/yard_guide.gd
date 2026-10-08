extends RefCounted

## One non-blocking preparation hint, recorded with the world for replay.
## Progress is observed state, not a command or a guaranteed winning plan.
static func line(host: Node) -> String:
	if host.level == null or host.level.level_id != "yard" or host.phase != host.Phase.SETUP:
		return ""
	if host.visual_snapshot._empty_stashes.is_empty():
		return "1/4 收集 · 开箱补充对应弹药"
	if host._deployed_count() < 2:
		return "2/4 站位 · 高点或地面掩体"
	if not host._plan_covers_route("main") or not host._plan_covers_route("flank"):
		return "3/4 瞄向 · 分别覆盖主路和侧翼"
	return "4/4 开战 · 检查弹药，再拉警报"
