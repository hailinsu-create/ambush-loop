extends SceneTree

## P0-3: teaching/briefing copy must never contain height/barn spoilers.
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const BriefingCopy := preload("res://ui/briefing_copy.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	for t in BriefingCopy.all_teaching_texts():
		var hits: PackedStringArray = BriefingCopy.forbidden_hits(str(t))
		if hits.is_empty():
			_passed += 1
			print("PASS clean: ", str(t).substr(0, 48).replace("\n", " "))
		else:
			_failed += 1
			printerr("FAIL blacklist hits=", hits, " text=", t)
	## Sanity: forbidden list itself is the contract.
	_assert(BriefingCopy.FORBIDDEN.size() == 5, "forbidden set size 5")
	for w in ["高点", "高处", "谷仓", "二层", "制高"]:
		_assert(BriefingCopy.FORBIDDEN.has(w), "forbidden has %s" % w)
	## Positive control: detector works.
	var probe := BriefingCopy.forbidden_hits("此处有高点与谷仓")
	_assert(probe.size() >= 2, "detector finds spoilers got=%s" % str(probe))
	print("W8_BRIEFING_BLACKLIST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
