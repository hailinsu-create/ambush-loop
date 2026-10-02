extends SceneTree
## Exhibition-only renderer counts. No FPS or Android acceptance claim.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://art/environment_v2/sample/review.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	var rows: Array = []
	for theme in scene.catalog.themes:
		for lod in range(2):
			scene.build_theme(theme,lod)
			scene.lighting(true)
			scene.pose(35,55,14 if lod==0 else 20,Vector3(0,1,0))
			for i in range(4): await RenderingServer.frame_post_draw
			rows.append({"theme":theme,"lod":lod,"yaw":35,"pitch":55,"camera_span_m":14 if lod==0 else 20,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	var dest := OS.get_environment("ENV_REVIEW_OUTPUT")
	var f := FileAccess.open(dest.path_join("exhibition_budget.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info(),"scope":"standalone exhibition, no actors/combat/UI integration; cloud llvmpipe Compatibility","not_acceptance":"not six-level runtime performance or Android FPS/thermal tests","samples":rows},"\t"))
	print("ENVIRONMENT_BUDGET_CAPTURED ",rows.size()," samples")
	quit(0)
