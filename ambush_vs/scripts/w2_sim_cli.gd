extends SceneTree

## Headless CLI: run a plan and print t0 / standard_ambush / kills / escapes / alert / hash.
## Usage (via isolated runner):
##   run_isolated_test.sh <godot> w2_sim_cli.gd
## Env: AMBUSH_PLAN=A|B|path  (default A)

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	var plan_arg := OS.get_environment("AMBUSH_PLAN")
	if plan_arg.is_empty():
		var args := OS.get_cmdline_user_args()
		if args.size() > 0:
			plan_arg = args[0]
	if plan_arg.is_empty():
		plan_arg = "A"
	var plan_path := _resolve_plan(plan_arg)
	var summary: Dictionary = SimRunner.run_plan(plan_path)
	if summary.has("error"):
		printerr("W2_CLI_FAIL error=", summary["error"])
		quit(1)
		return
	print("W2_CLI plan=", summary.get("event_log", {}).get("plan_id", plan_arg))
	print("t0_tick=", summary.get("detonate_tick", -1))
	print("t0_s=", float(summary.get("detonate_tick", -1)) / 20.0)
	print("standard_ambush=", summary.get("standard_ambush", false))
	print("outcome=", summary.get("outcome", ""))
	print("trigger=", summary.get("trigger", ""))
	print("alert=", summary.get("alert", ""))
	print("kills=", ",".join(PackedStringArray(summary.get("kills", []))))
	print("escapes=", ",".join(PackedStringArray(summary.get("escapes", []))))
	print("hash=", summary.get("log_hash", ""))
	quit(0)


func _resolve_plan(arg: String) -> String:
	match arg:
		"A", "a", "plan_a":
			return "res://data/fixtures/plan_a.json"
		"B", "b", "plan_b":
			return "res://data/fixtures/plan_b.json"
		_:
			if arg.begins_with("res://") or arg.begins_with("/"):
				return arg
			return "res://data/fixtures/%s" % arg
