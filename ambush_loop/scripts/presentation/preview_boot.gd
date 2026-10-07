extends Node

## Entry for the separate A0 test package. Never enabled by the normal export.
func _ready() -> void:
	var settings = get_node("/root/GameSettings")
	settings.set_force_touch_hud(true)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	Engine.max_fps = 30
	get_tree().change_scene_to_file.call_deferred("res://scenes/presentation/yard_3d.tscn")
