extends SceneTree

## PLAY-3 / VS-FX1: view combat FX consumes every fire/kill from plan A log.
## Ambush NightSim / W2 golden hashes unchanged.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const CombatFxScript := preload("res://view/combat_fx.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_fx_consumes_plan_a_events()
	_test_golden_hash_unchanged()
	await _test_greybox_scene_fx_counts()
	print("W5_COMBAT_FX_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _count_log(events: Array, typ: String) -> int:
	var n := 0
	for e in events:
		if str(e.get("type", "")) == typ:
			n += 1
	return n


func _test_fx_consumes_plan_a_events() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	var fx = CombatFxScript.new()
	while not sim.is_finished():
		sim.advance_one_tick()
	var fire_n := _count_log(sim.log.events, "fire")
	var hit_n := _count_log(sim.log.events, "hit")
	var kill_n := _count_log(sim.log.events, "kill")
	_assert(fire_n > 0, "plan A log has fire events n=%d" % fire_n)
	_assert(kill_n > 0, "plan A log has kill events n=%d" % kill_n)
	var got: Dictionary = fx.consume_events(sim.log.events, sim.enemies, sim.operators)
	_assert(int(got.get("fires", -1)) == fire_n, "fx fires match log %d==%d" % [got.get("fires"), fire_n])
	_assert(int(got.get("hits", -1)) == hit_n, "fx hits match log %d==%d" % [got.get("hits"), hit_n])
	_assert(int(got.get("kills", -1)) == kill_n, "fx kills match log %d==%d" % [got.get("kills"), kill_n])
	_assert(fx.fires_seen == fire_n, "fx.fires_seen == log fires")
	_assert(fx.kills_seen == kill_n, "fx.kills_seen == log kills")
	_assert(fx.bodies.size() == kill_n, "body sprites == kills got=%d" % fx.bodies.size())
	_assert(fx.bodies.size() == sim.killed_ids.size(), "bodies == killed_ids")
	# Tracers/flashes: friendly fire + PLAY-6 enemy_fire both spawn presentation.
	var enemy_fire_n := _count_log(sim.log.events, "enemy_fire")
	_assert(fx.tracers.size() == fire_n + enemy_fire_n, "tracers spawned per fire+enemy_fire")
	_assert(fx.flashes.size() == fire_n + enemy_fire_n, "muzzle flashes spawned per fire+enemy_fire")


func _test_golden_hash_unchanged() -> void:
	var batch: Dictionary = SimRunner.run_plan("res://data/fixtures/plan_a.json")
	var golden: Dictionary = SimRunner.load_json("res://data/golden/hashes.json")
	_assert(str(batch.get("log_hash", "")) == str(golden.get("plan_a", "")), "plan A golden hash unchanged with FX module present")
	_assert(int(batch.get("detonate_tick", -1)) == int(golden.get("t0_a", 520)), "plan A t0=520")


func _test_greybox_scene_fx_counts() -> void:
	## AUTO path consumes FX; controller totals must match the live match's log.
	## T5 climb: the scene plan carries climb fields that the bare fixture does
	## not, so compare counts against scene.sim.log.events — the match actually
	## consumed — not a re-run. T5b: preset A takes the north ladder and restores
	## the standard ambush (520).
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "fx scene change_scene err=%s" % err)
	for _i in range(2500):
		await process_frame
		var scene = current_scene
		if scene == null:
			continue
		if scene.get("last_summary") is Dictionary and not (scene.last_summary as Dictionary).is_empty():
			var ls: Dictionary = scene.last_summary
			_assert(int(ls.get("detonate_tick", -1)) == 520, "scene fx path t0=520 got=%s" % ls.get("detonate_tick"))
			_assert(bool(ls.get("standard_ambush", false)) == true, "scene fx path standard_ambush")
			# Self-consistency: last_summary is this match's own outcome_summary.
			var sim_sum: Dictionary = scene.sim.outcome_summary()
			_assert(
				int(ls.get("detonate_tick", -1)) == int(sim_sum.get("detonate_tick", -2)),
				"scene fx path t0 self-consistent %s==%s" % [ls.get("detonate_tick"), sim_sum.get("detonate_tick")]
			)
			_assert(
				bool(ls.get("standard_ambush", false)) == bool(sim_sum.get("standard_ambush", false)),
				"scene fx path standard_ambush self-consistent %s==%s" % [ls.get("standard_ambush"), sim_sum.get("standard_ambush")]
			)
			# Expected FX counts come from this match's own log. kills counts every
			# "kill" event (enemy + operator); bodies is keyed by kill target id, so
			# the expected body count is the number of distinct kill targets.
			var fire_n := 0
			var kill_n := 0
			var kill_targets: Dictionary = {}
			var climbed_ids: Dictionary = {}
			for ev in scene.sim.log.events:
				var et := str(ev.get("type", ""))
				if et == "fire":
					fire_n += 1
				elif et == "kill":
					kill_n += 1
					kill_targets[str(ev.get("target", ""))] = true
				elif et == "climb_start":
					climbed_ids[str(ev.get("actor", ""))] = true
			# The sample plan must pay the same climb cost as any high-point plan.
			var high_ids: Dictionary = {}
			for op in scene.plan.get("operators", []):
				if bool(op.get("climbing", false)):
					high_ids[str(op.get("id", ""))] = true
			var climb_ok := not high_ids.is_empty()
			for oid in high_ids.keys():
				if not climbed_ids.has(oid):
					climb_ok = false
			_assert(climb_ok, "scene plan A high op(s) climb_start in log high=%s climbed=%s" % [high_ids.keys(), climbed_ids.keys()])
			var st: Dictionary = scene.combat_fx_stats() if scene.has_method("combat_fx_stats") else {}
			_assert(int(st.get("fires", -1)) == fire_n, "scene fx fires==log %s==%d" % [st.get("fires"), fire_n])
			_assert(int(st.get("kills", -1)) == kill_n, "scene fx kills==log %s==%d" % [st.get("kills"), kill_n])
			_assert(int(st.get("bodies", -1)) == kill_targets.size(), "scene fx bodies==distinct kill targets %s==%d" % [st.get("bodies"), kill_targets.size()])
			OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
			return
	_assert(false, "scene fx auto did not finish in time")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
