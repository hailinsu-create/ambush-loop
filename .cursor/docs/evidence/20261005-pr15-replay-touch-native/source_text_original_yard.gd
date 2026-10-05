extends "res://scripts/replay_event_text_source_test.gd"
const YARD := "/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause/run/yard-record.bin"
const SHA := "e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5"
func _prepare() -> void:
	# Consumer alternative to the original monolithic gate's reference producer.
	# All source-text assertions remain inherited; no new victory is claimed.
	_check(FileAccess.get_sha256(YARD)==SHA,"original schema2 yard archive bytes")
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false); settings.mark_tutorial_seen("yard"); settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame; await process_frame
	main=current_scene; view=main.presentation_3d
	main.set_process(false); view.set_process(false)
	var values: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(YARD))
	source=BattleLog.new()
	for key in values: source.set(key,values[key])
	retained=_state(source)
	main.battle_log=source; main.phase=main.Phase.WON
	main.raid.wave_index=1; main.raid.waves_cleared=2; main._show_win_result()
	_check(source.playback_schema==2 and source.playback_snapshots.size()==1622 and source.events.size()==30,"actual original modern source, not regenerated reference")
	rows.append({"record_fixture":"original dab yard schema2 saved archive; paired controlled consumer, no reference/new producer", "sha256":SHA,"attempt":source.attempt_id})
func _exercise_source(label: String) -> void:
	await super._exercise_source("actual_schema2_original_yard" if label=="actual_schema2_reference" else label)
	_check(FileAccess.get_sha256(YARD)==SHA,"original modern archive unchanged after source exercises")
