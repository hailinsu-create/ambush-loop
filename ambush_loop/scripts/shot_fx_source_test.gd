extends "res://scripts/campaign_replay_test.gd"
## Actual original reference battles; resource grants/direct ticks are explicit.
## This source-only contract is not native gameplay or rendered FX acceptance.
var fx_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_SOURCE_FAIL " + message)

func _run() -> void:
	var settings = root.get_node("GameSettings")
	for case in CASES: settings.mark_tutorial_seen(case[0])
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	for case in CASES:
		await _battle(main, case, 60, 1.0, false)
		var found := 0
		for event: Dictionary in main.battle_log.events:
			if event.type not in ["fire", "return_fire"]: continue
			found += 1
			var raw: Variant = event.payload.get("fx", {})
			var fx: Dictionary = raw if raw is Dictionary else {}
			_check(not fx.is_empty(), str(case[0])+" actual original shot descriptor "+str(event.event_id))
			if fx.is_empty(): continue
			_check(int(fx.get("schema", 0)) == 1 and fx.get("confirmed", false), "actual successful callback confirmed")
			_check(fx.get("event_id") == event.event_id and fx.get("attempt_id") == event.attempt_id and fx.get("wave_id") == event.wave_id and fx.get("seq") == event.seq, "stable original identity")
			_check(fx.get("level_id") == case[0] and fx.get("clock_domain") == "playback" and fx.get("clock_tick") == event.playback_tick, "explicit original source clock/level")
			_check(fx.get("source_group") == ("ops" if event.type == "fire" else "enemies") and fx.get("target_group") == ("enemies" if event.type == "fire" else "ops"), "same actor number group disambiguation")
			_check(fx.get("source_id") == event.actor_id and fx.get("target_id") == event.target_id and fx.get("source_pos") == event.position, "original actor/target/position")
			_check(fx.get("visual_weapon") == event.payload.visual_weapon and fx.get("actor_asset_revision") == "29749157c5db064bfea626c3ed9d75d9a1791ece", "original shot gun and R5 revision")
			_check(fx.get("pose", {}) is Dictionary and not fx.get("pose", {}).is_empty(), "saved shot pose before damage/repack")
			var before: float = float(fx.get("hp_before", NAN))
			var after: float = float(fx.get("hp_after", NAN))
			var damage: float = float(fx.get("damage", NAN))
			_check(is_finite(before) and is_finite(after) and is_finite(damage) and damage > 0.0 and is_equal_approx(damage, before-after), "actual post-backend HP delta")
			fx_rows.append({"level":case[0],"event":event.event_id,"wave":event.wave_id,"type":event.type,"weapon":fx.visual_weapon,"damage":damage})
		_check(found > 0, str(case[0])+" original actual shots reached")
	root.get_node("AudioDirector").pause_for_background()
	var directory := "res://build/asset_review/pr15-runtime/shot-fx-source-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"shots":fx_rows,"runs":report_rows,"scope":"Original controlled six reference battles and real successful backend calls. Resources/snap/directtick/vacuum fixtures explicit. Source-only descriptors, not native normal or rendered3D FX/final/A3/device acceptance."},"  "))
	file.close()
	print("SHOT_FX_SOURCE_TEST checks=%d failures=%d output=%s" % [checks, failures, directory])
	quit(0 if failures == 0 else 1)
