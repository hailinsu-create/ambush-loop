extends "res://scripts/title_menu_viewport_test.gd"
## Fresh original title -> yard entry. Native inputs, actual engine callbacks.
## No tutorial-seen/unlock/win/loadout/reference/vacuum fixture.

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FIRST_VISIT_FAIL " + sample + " " + message)

func _save_journey() -> void:
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/first-visit-journey-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"native_inputs":input_rows,"scope":"Fresh isolated original title -> yard -> first-visit tutorial. Real XTest and engine process, no tutorial/progress/resource grant fixture. Does not claim all six missions/13 waves."}, "  "))
	print("FIRST_VISIT_JOURNEY_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _run() -> void:
	settings = root.get_node("GameSettings")
	if DisplayServer.get_name() == "headless":
		print("FIRST_VISIT_JOURNEY requires native rendered verification")
		quit(2)
		return
	root.position = Vector2i.ZERO
	root.size = Vector2i(1600, 720)
	root.content_scale_factor = 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	sample = "first_visit_yard_1600_200_desktop"
	await _title()
	_check(not settings.has_progress() and not settings.has_seen_tutorial("yard"), "fresh isolated player has no progress or completed tutorial")
	await _click(main.start_btn)
	_check(main.mission_select_visible(), "original native Start opens missions")
	await _click(main._mission_btns[0])
	_check(main.briefing_visible() and main.pending_mission_id() == "yard", "original native available yard opens brief")
	await _click(main._brief_go)
	await _settle()
	main = current_scene
	_check(main.scene_file_path == "res://scenes/main.tscn" and main.level.level_id == "yard" and main.phase == main.Phase.SETUP, "ordinary fresh original entry reaches actual yard SCOUT")
	_check(main.tutorial_overlay.is_open(), "first visit naturally shows original tutorial")
	_check(main.operators.all(func(op) -> bool: return op.weapon_id == "knife"), "first visit retains authored knife-only loadouts")
	var tutorial = main.tutorial_overlay
	for page in tutorial.pages_for("yard").size():
		await _settle()
		var rect: Rect2 = tutorial._next.get_global_rect()
		var reachable := _hit_visible(tutorial._next)
		rows.append({"level":"yard","page":page,"viewport":_rect(root.get_visible_rect()),"next_rect":_rect(rect),"next_reachable":reachable,"body":tutorial._body.text,"phase":main.phase})
		await _modal_capture(sample + "_tutorial_page" + str(page))
		_check(reachable, "original tutorial next/Start is fully reachable on page " + str(page) + " " + str(rect))
		if not reachable:
			_save_journey()
			return
		await _click(tutorial._next)
	_check(not tutorial.is_open() and settings.has_seen_tutorial("yard"), "native complete pages dismisses tutorial and writes original seen state")
	_check(main.phase == main.Phase.SETUP and not main._modal_blocks_input(), "first visit permits ordinary SCOUT commands")
	_save_journey()
