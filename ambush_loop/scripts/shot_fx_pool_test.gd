extends "res://scripts/shot_fx_boundary_test.gd"
## Explicit original backend fixture / saved consumer. Not native normal play.
const ViewState := preload("res://scripts/presentation/view_state.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const POOL_PATH := "res://scripts/presentation/shot_fx_pool.gd"
var pool: Node3D
var captures := []
var directory := ""

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_POOL_FAIL "+message)

func _run_cases() -> void:
	pass

func _run() -> void:
	directory = "res://build/asset_review/pr15-runtime/shot-fx-pool-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(ResourceLoader.exists(POOL_PATH),"planned finite saved-shot 3D pool interface exists")
	if ResourceLoader.exists(POOL_PATH):
		await _run_cases()
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"Bounded saved-shot 3D consumer / explicit backend and corrupt history fixtures. No native normal/full13/final/A3/device acceptance."},"  "))
	file.close()
	print("SHOT_FX_POOL_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
