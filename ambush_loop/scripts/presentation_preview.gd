extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Use the isolated runner with --render (PowerShell: -Rendered).")
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(true)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	print("PRESENTATION_PREVIEW_RUNNING isolated_user_data=", ProjectSettings.globalize_path("user://"))
