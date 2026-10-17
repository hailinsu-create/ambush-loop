extends SceneTree

## Skeleton empty test for Ambush VS.
## Must be launched via scripts/run_isolated_test.sh|.ps1.
## Direct entry without isolation env → quit(91).

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	print("EMPTY_TEST_OK ambush_vs")
	quit(0)
