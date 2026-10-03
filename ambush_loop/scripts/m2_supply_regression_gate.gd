extends "res://scripts/smoke_test.gd"

## Run the changed shared resource/pack/transfer contract without the unrelated
## long touch-follow suite. This is NOT the full six-mission smoke.
func _run() -> void:
	create_timer(180.0).timeout.connect(func(): quit(3))
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		quit(2)
		return
	for frame in 14:
		await process_frame
	var main = current_scene
	if main == null or main.level == null or main.level.level_id != "yard":
		quit(2)
		return
	main.set_process(false)
	if main.tutorial_overlay != null and main.tutorial_overlay.is_open():
		for page in 3:
			main.tutorial_overlay._on_next()
	if not _assert_raid_contract(main):
		quit(2)
		return
	print("M2_SHARED_RESOURCE_CONTRACT_OK not_full_smoke=1")
	quit(0)
