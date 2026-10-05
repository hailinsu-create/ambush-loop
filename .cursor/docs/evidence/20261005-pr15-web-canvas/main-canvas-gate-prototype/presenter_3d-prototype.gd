extends Node3D

const Space := preload("res://scripts/presentation/world_space.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Rig := preload("res://scripts/presentation/camera_rig_3d.gd")
const Picker := preload("res://scripts/presentation/world_picker_3d.gd")
const Commands := preload("res://scripts/input/command_router.gd")
const CameraInput := preload("res://scripts/input/camera_input.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const Occlusion := preload("res://scripts/presentation/occlusion_controller.gd")
const DeviceProbe := preload("res://scripts/presentation/device_probe.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
const EnvironmentScene := preload("res://scripts/presentation/environment_scene.gd")
const EnvironmentVisual := preload("res://scripts/presentation/environment_visual.gd")
const CorpsePose := preload("res://scripts/presentation/corpse_pose.gd")
const CorpseVisual := preload("res://scripts/presentation/corpse_visual.gd")
const ShotFxPool := preload("res://scripts/presentation/shot_fx_pool.gd")
const ToolFxPool := preload("res://scripts/presentation/tool_fx_pool.gd")
const MovementDustPool := preload("res://scripts/presentation/movement_dust_pool.gd")

var host: Node
var rig: Node3D
var gestures := CameraInput.new()
var frame: Dictionary = {}
var geometry := Node3D.new()
var proxies := Node3D.new()
var walls: Array = []
var actors: Dictionary = {}
var corpses: Dictionary = {}
var shot_fx: Node3D
var tool_fx: Node3D
var movement_dust: Node3D
var _actor_scope: Array = []
var objects: Dictionary = {}
var _object_scope: Array = []
var _environment_scene: Node3D
var _environment_lod := 0
var cones: Dictionary = {}
var _layout_hash := 0
var _selected_ring: MeshInstance3D
var _event_ring: MeshInstance3D
var _focus_attempt := ""
var _focus_wave := -1
var _focus_tick := -1
var _focus_playback_tick := -1
var _compass: Label
var _pitch_slider: HSlider
var _camera_controls: CanvasLayer
var _camera_panel: VBoxContainer
var _camera_toggle: Button
var _camera_plate: ColorRect
var _compact_camera := false
var _camera_layout_key := ""
var _camera_open := false
var _occlusion_acc := 0.0
var _last_pose := Transform3D.IDENTITY
var _steel: StandardMaterial3D
var _crate: StandardMaterial3D
var _cover: StandardMaterial3D
var _hostile: StandardMaterial3D
var _role_materials: Array[StandardMaterial3D] = []
var _probe := DeviceProbe.new()
var _probe_button: Button
var _probe_result: Label


func bind(main: Node) -> void:
	host = main
	if OS.has_feature("web"):
		host.visible = false
	# Parent's simulation update and child actors finish before we take a frame.
	process_priority = 100
	geometry.name = "Geometry"
	proxies.name = "Proxies"
	add_child(geometry)
	add_child(proxies)
	shot_fx = ShotFxPool.new()
	shot_fx.name = "ShotFx"
	add_child(shot_fx)
	tool_fx = ToolFxPool.new()
	tool_fx.name = "ToolFx"
	add_child(tool_fx)
	movement_dust = MovementDustPool.new()
	movement_dust.name = "MovementDust"
	add_child(movement_dust)
	rig = Rig.new()
	rig.name = "CameraRig"
	add_child(rig)
	_steel = Geometry.material(Color("353d42"))
	_crate = Geometry.material(Color("8c7150"))
	_cover = Geometry.material(Color("777762"))
	_hostile = Geometry.material(Color("5c5150"))
	for color in [Color("7e8d6a"), Color("566b61"), Color("687b88")]:
		_role_materials.append(Geometry.material(color))
	_make_lighting()
	_make_controls()
	var ring_mat := Geometry.material(Color(0.55, 0.94, 0.82, 0.72), true)
	ring_mat.no_depth_test = true
	_selected_ring = Geometry.ring(proxies, 0.55, 0.055, Vector3.ZERO, ring_mat)
	_selected_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var focus_mat := Geometry.material(Color(1.0, 0.8, 0.25, 0.68), true)
	focus_mat.no_depth_test = true
	_event_ring = Geometry.ring(proxies, 0.72, 0.055, Vector3.ZERO, focus_mat)
	_event_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_event_ring.visible = false
	refresh()


func _make_lighting() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("171d26")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b6c5de")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "DuskKey"
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.light_color = Color("c5d1e4")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(10.0, 3.0, 3.0)
	lamp.light_color = Color("ffbf76")
	lamp.light_energy = 2.5
	lamp.omni_range = 11.0
	lamp.shadow_enabled = false
	add_child(lamp)


func _make_controls() -> void:
	_camera_controls = CanvasLayer.new()
	_camera_controls.layer = 4
	add_child(_camera_controls)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_controls.add_child(root)
	var panel := VBoxContainer.new()
	_camera_panel = panel
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -204
	panel.offset_right = -16
	panel.offset_top = 132
	panel.add_theme_constant_override("separation", 6)
	root.add_child(panel)
	_camera_plate = ColorRect.new()
	_camera_plate.color = Color(0.035, 0.04, 0.045, 0.96)
	_camera_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_camera_plate)
	root.move_child(_camera_plate, 0)
	_camera_toggle = Button.new()
	_camera_toggle.text = "镜头"
	_camera_toggle.custom_minimum_size = Vector2(80, 32)
	_camera_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_camera_toggle.offset_left = -192
	_camera_toggle.offset_right = -112
	_camera_toggle.offset_top = 112
	_camera_toggle.offset_bottom = 144
	root.add_child(_camera_toggle)
	_camera_toggle.pressed.connect(func() -> void:
		if host._modal_blocks_input(): return
		_camera_open = not _camera_open
		_layout_camera_controls()
	)
	_compass = Label.new()
	_compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compass.add_theme_font_size_override("font_size", 14)
	panel.add_child(_compass)
	var row := HBoxContainer.new()
	panel.add_child(row)
	for spec in [["↶", -30.0], ["复位", 0.0], ["↷", 30.0]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(58, 42)
		row.add_child(button)
		var amount: float = spec[1]
		button.pressed.connect(func() -> void:
			if host._modal_blocks_input():
				return
			gestures.cancel()
			if amount == 0.0:
				rig.reset_view()
			else:
				rig.yaw_deg += amount
				rig.apply_pose()
		)
	var focus_button := Button.new()
	focus_button.text = "定位选中队员"
	focus_button.custom_minimum_size.y = 36
	panel.add_child(focus_button)
	focus_button.pressed.connect(func() -> void:
		if not host._modal_blocks_input():
			focus_selected()
	)
	_pitch_slider = HSlider.new()
	_pitch_slider.min_value = Rig.MIN_PITCH
	_pitch_slider.max_value = Rig.MAX_PITCH
	_pitch_slider.value = Rig.DEFAULT_PITCH
	_pitch_slider.custom_minimum_size.y = 36
	_pitch_slider.tooltip_text = "观察俯角"
	panel.add_child(_pitch_slider)
	_pitch_slider.value_changed.connect(func(value: float) -> void:
		if not host._modal_blocks_input():
			rig.pitch_deg = value
			rig.apply_pose()
	)
	_probe_button = Button.new()
	_probe_button.text = "镜头巡检 · 30 秒"
	_probe_button.custom_minimum_size.y = 38
	panel.add_child(_probe_button)
	_probe_button.pressed.connect(func() -> void:
		if host._modal_blocks_input():
			return
		gestures.cancel()
		if _probe.active:
			_probe.stop(rig)
			_probe_button.text = "镜头巡检 · 30 秒"
		elif not _probe.report.is_empty():
			DisplayServer.clipboard_set(JSON.stringify(_probe.report))
			_probe.report.clear()
			_probe_button.text = "镜头巡检 · 30 秒"
		else:
			_probe.start(rig)
			_probe_result.text = "自动转动镜头；可随时取消"
	)
	_probe_result = Label.new()
	_probe_result.add_theme_font_size_override("font_size", 12)
	_probe_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_probe_result)


func _process(delta: float) -> void:
	if host == null or not is_instance_valid(host):
		return
	_occlusion_acc += delta
	refresh()
	if _probe.active:
		_probe_button.text = "取消巡检 · %d 秒" % ceili(DeviceProbe.DURATION - _probe.elapsed)
		if _probe.step(rig, frame):
			_probe_button.text = "复制巡检报告"
			_probe_result.text = "短测 %.1f FPS · p95 %.1f ms\n不代表持续性能验收" % [_probe.report.avg_fps, _probe.report.p95_ms]


func refresh() -> void:
	if host.level == null:
		return
	# Hide only the RenderingServer canvas branch. Node visibility and all
	# simulation participation checks retain their original values.
	RenderingServer.canvas_item_set_visible(host.get_node("World").get_canvas_item(), false)
	var next_frame: Dictionary = ViewState.capture(host)
	if not frame.is_empty() and (frame.run_id != next_frame.run_id or frame.phase != next_frame.phase):
		cancel_input()
	frame = next_frame
	if _event_ring.visible and (_focus_attempt != frame.attempt_id or _focus_wave != frame.wave_id or int(frame.tick) < _focus_tick or (frame.replay and int(frame.playback_tick) < _focus_playback_tick)):
		_event_ring.visible = false
	# Hysteresis avoids rebuilding the static batches while pinching at a boundary.
	if rig.view_size > 26.0:
		_environment_lod = 1
	elif rig.view_size < 22.0:
		_environment_lod = 0
	var layout_hash: int = hash([frame.level_id, frame.blocked, frame.environment_supported,
		frame.environment_revision, frame.environment_layout_revision, frame.environment_cutaway_schema, frame.has_door, frame.door_pos, _environment_lod])
	if layout_hash != _layout_hash:
		_layout_hash = layout_hash
		_rebuild_geometry()
	if _environment_scene != null and _environment_scene.set_door(frame.door_locked):
		_last_pose = Transform3D.IDENTITY
	_sync_actors()
	_sync_corpses()
	_sync_objects()
	shot_fx.update_frame(frame,host._is_power_saving())
	tool_fx.update_frame(frame,host._is_power_saving())
	movement_dust.update_frame(frame,host._is_power_saving())
	_sync_cones()
	_selected_ring.visible = false
	for op in frame.ops:
		if op.id == frame.selected_id and op.active and op.alive:
			_selected_ring.visible = true
			_selected_ring.position = Space.logic_to_world(op.pos, 0.035)
	if _occlusion_acc >= 0.1 or rig.camera.global_transform != _last_pose:
		var targets: Array = []
		for group in [frame.ops, frame.enemies, frame.sentries, frame.stashes, frame.loot]:
			for item in group:
				if bool(item.get("active", true)):
					targets.append(Space.logic_to_world(item.pos, 0.12))
					if bool(item.get("alive", false)):
						targets.append(Space.logic_to_world(item.pos, 0.9))
		Occlusion.update(rig.camera, walls, targets)
		_occlusion_acc = 0.0
		_last_pose = rig.camera.global_transform
	_compass.text = "镜头 %03d° · 俯角 %d°" % [int(rig.yaw_deg), int(rig.pitch_deg)]
	_layout_camera_controls()
	_pitch_slider.set_value_no_signal(rig.pitch_deg)
	# The A0 scene reuses the old HUD, but must describe its actual gestures.
	if host.touch_hud != null and host.touch_hud._hint.text.contains("短拖"):
		host.touch_hud.set_hint("点选 / 点地移动 · 双指平移、旋转、缩放 · ↶↷调整队员射界")
	if host.touch_hud != null:
		host.touch_hud._hint.position.y = 60.0
	if host.c2 != null and host.c2.help_chip != null and host.c2.help_chip.text.contains("短拖"):
		host.c2.help_chip.text = "点选 / 点地移动 · 双指操作镜头 · 近背面出绕背"


func _layout_camera_controls() -> void:
	# Camera chrome lives above the HUD CanvasLayer. Terminal reports must
	# retain the entire area for their scroll content and original actions.
	if host._result_overlay_active():
		_camera_panel.hide()
		_camera_toggle.hide()
		_camera_plate.hide()
		return
	var compact: bool = host._compact_hud()
	if compact != _compact_camera:
		_camera_open = false
		_compact_camera = compact
	_camera_toggle.visible = compact
	_camera_toggle.text = "收镜头" if _camera_open else "镜头"
	_camera_panel.visible = not compact or _camera_open
	_camera_controls.layer = 50 if compact and _camera_open else 4
	var camera_top := 80 if compact else (196 if not host._use_touch_chrome() else 132)
	var key := "%s:%d" % [compact,camera_top]
	if key != _camera_layout_key:
		_camera_layout_key=key
		# Let minimum-size changes grow toward the courtyard. Reassigning
		# horizontal offsets on every frame can queue redundant child layouts.
		_camera_panel.set_anchors_preset(Control.PRESET_TOP_LEFT if compact else Control.PRESET_TOP_RIGHT)
		_camera_panel.offset_right = 216 if compact else -16
		_camera_panel.offset_left = 8 if compact else -204
		_camera_panel.grow_horizontal = Control.GROW_DIRECTION_END if compact else Control.GROW_DIRECTION_BEGIN
		_camera_panel.offset_top = camera_top
	_camera_panel.offset_bottom = _camera_panel.offset_top + _camera_panel.get_combined_minimum_size().y
	_camera_plate.visible = compact and _camera_open
	_camera_plate.position = _camera_panel.position - Vector2(4,4)
	_camera_plate.size = _camera_panel.size + Vector2(8,8)


func _rebuild_geometry() -> void:
	for child in geometry.get_children():
		child.free()
	walls.clear()
	_last_pose = Transform3D.IDENTITY
	_environment_scene = null
	if frame.environment_supported:
		_environment_scene = EnvironmentScene.new()
		geometry.add_child(_environment_scene)
		_environment_scene.build(frame, _environment_lod)
		walls = _environment_scene.walls
	else:
		Geometry.box(geometry, Vector3(40, 0.24, 22), Vector3(0, -0.13, 0), Geometry.material(Color("454b4e")))
		var wall_mat := Geometry.material(Color("777d7d"))
		for rect in Geometry.blocked_rectangles(frame.blocked):
			var height := 2.4 if rect.size.x == 1 or rect.size.y == 1 else 1.7
			var size := Vector3(rect.size.x, height, rect.size.y)
			var at := Vector3(rect.position.x - 20 + rect.size.x * 0.5, height * 0.5,
				rect.position.y - 11 + rect.size.y * 0.5)
			var mesh := Geometry.box(geometry, size - Vector3(0.03, 0, 0.03), at, wall_mat)
			walls.append({"mesh": mesh, "bounds": AABB(at - size * 0.5, size)})
	if frame.visual_schema == 0 or frame.visual_unsupported:
		return
	var exit_mat := Geometry.material(Color("8bac9c"), true)
	Geometry.box(geometry, Vector3(2.3, 0.03, 0.28), Space.logic_to_world(frame.escape, 0.02), exit_mat)
	var exit_label := Label3D.new()
	exit_label.text = "逃逸口"
	exit_label.position = Space.logic_to_world(frame.escape, 0.55)
	exit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	exit_label.font_size = 40
	exit_label.pixel_size = 0.008
	geometry.add_child(exit_label)


func _sync_actors() -> void:
	var scope := [frame.level_id, frame.attempt_id, frame.wave_id, frame.replay, frame.animation_supported, frame.actor_asset_revision]
	if scope != _actor_scope:
		for proxy in actors.values():
			proxy.free()
		actors.clear()
		_actor_scope = scope
	var seen := {}
	for group in ["ops", "enemies", "sentries"]:
		for item in frame[group]:
			var key := "%s:%s" % [group, item.id]
			seen[key] = true
			if not actors.has(key):
				var proxy := Node3D.new()
				proxies.add_child(proxy)
				var label := Label3D.new()
				label.name = "Marker"
				label.text = str(item.id) if group == "ops" else "◆"
				label.position.y = 2.0
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.font_size = 40
				label.pixel_size = 0.009
				label.modulate = Color("cbebe0") if group == "ops" else Color("e79c80")
				label.no_depth_test = true
				proxy.add_child(label)
				actors[key] = proxy
			var proxy: Node3D = actors[key]
			proxy.position = Space.logic_to_world(item.pos)
			proxy.visible = item.active
			_sync_body(proxy, item, group)
			if not item.alive and CorpsePose.supported(frame):
				for corpse in frame.corpses:
					if str(item.get("corpse_id", "")) == str(corpse.get("id", "")) and CorpsePose.valid(corpse, frame):
						proxy.visible = false
			proxy.get_node("Marker").visible = item.alive
	for key in actors.keys():
		if not seen.has(key):
			actors[key].free()
			actors.erase(key)


func _sync_body(proxy: Node3D, item: Dictionary, group: String) -> void:
	var model_id: String = item.visual_model
	var rigged: bool = frame.animation_supported and Assets.has_asset(model_id) and Assets.is_character_asset(model_id)
	var body := proxy.get_node_or_null("Body") as Node3D
	if body != null and (body is ActorVisual) != rigged:
		body.free()
		body = null
	if body == null:
		if rigged:
			body = ActorVisual.new()
			body.name = "Body"
			proxy.add_child(body)
		else:
			var mat: Material = _role_materials[clampi(int(item.get("role", 0)), 0, 2)] if group == "ops" else _hostile
			body = Geometry.actor(proxy, mat, _steel)
	if rigged:
		var pixels: float = 1.85 * get_viewport().get_visible_rect().size.y / rig.view_size
		var lod: int = ActorPose.choose_lod(pixels, body.lod)
		body.rotation = Vector3(0, Space.facing_yaw(item.facing), 0)
		body.position = Vector3.ZERO
		body.scale = Vector3.ONE
		body.set_asset(model_id, lod, frame.actor_asset_revision)
		var pose := ActorPose.sample(item, frame, group)
		body.rotation.y = Space.facing_yaw(float(pose.get("visual_facing", item.facing)))
		var weapon_id: String = str(pose.get("visual_item", item.visual_weapon))
		body.mount_item(weapon_id if Assets.has_asset(weapon_id) else "")
		body.sample_layers(pose)
		body.set_meta("pose_event_id", pose.event_id)
		body.set_meta("pose_fallback", pose.fallback)
	else:
		body.rotation = Vector3(0.0 if item.alive else -PI * 0.5, Space.facing_yaw(item.facing), 0.0)
		body.position.y = 0.0 if item.alive else 0.22
		body.scale.y = 0.7 if item.alive and int(item.get("stance", 0)) == 1 else 1.0


func _sync_objects() -> void:
	var scope := [frame.level_id, frame.attempt_id, frame.wave_id, frame.replay,
		frame.environment_supported, frame.environment_revision]
	if scope != _object_scope:
		for proxy in objects.values():
			proxy.free()
		objects.clear()
		_object_scope = scope
	var seen := {}
	for group in ["stashes", "covers", "loot", "barrels", "tripwires", "mines", "grenades", "decoys", "environment_objects"]:
		for item in frame[group]:
			var key := "%s:%s" % [group, item.id]
			seen[key] = true
			if not objects.has(key):
				var proxy := Node3D.new()
				proxies.add_child(proxy)
				var model_id: String = EnvironmentVisual.model_for(group, item) if frame.environment_supported else ""
				if not model_id.is_empty():
					var visual := EnvironmentVisual.new()
					visual.name = "EnvironmentVisual"
					proxy.add_child(visual)
					visual.set_asset(model_id, _environment_lod)
				elif group in ["stashes", "environment_objects"]:
					Geometry.box(proxy, Vector3(0.85, 0.6, 0.58), Vector3(0, 0.3, 0), _crate)
					Geometry.box(proxy, Vector3(0.9, 0.1, 0.65), Vector3(0, 0.64, 0), _cover)
				elif group == "covers":
					Geometry.cylinder(proxy, 0.42, 0.04, Vector3(0, 0.03, 0), _cover)
				elif group == "barrels":
					Geometry.cylinder(proxy, 0.3, 0.9, Vector3(0, 0.45, 0), _steel)
				elif group in ["tripwires", "mines"]:
					Geometry.cylinder(proxy, 0.2, 0.04, Vector3(0, 0.03, 0), _cover)
				elif group == "grenades":
					Geometry.cylinder(proxy, 0.07, 0.18, Vector3(0, 0.12, 0), _steel)
				elif group == "decoys":
					Geometry.box(proxy, Vector3(0.15, 0.05, 0.15), Vector3(0, 0.04, 0), _crate)
				else:
					Geometry.box(proxy, Vector3(0.4, 0.16, 0.3), Vector3(0, 0.1, 0), _crate)
				objects[key] = proxy
			objects[key].position = Space.logic_to_world(item.pos)
			objects[key].visible = bool(item.get("active", true))
			var visual := objects[key].get_node_or_null("EnvironmentVisual") as Node3D
			if visual != null:
				visual.set_asset(EnvironmentVisual.model_for(group, item), _environment_lod)
				visual.set_lid(float(item.get("progress", 0.0)))
				if group == "covers":
					visual.rotation.y = Space.facing_yaw(float(item.get("facing", 90.0)))
					visual.position = Space.facing_direction(float(item.get("facing", 90.0))) * 0.58
				elif group == "loot":
					visual.scale = Vector3.ONE * 0.7
				elif group in ["stashes", "environment_objects"]:
					visual.scale = Vector3.ONE * 0.8
				if group == "grenades":
					var flight: float = clampf(float(item.get("flight", 0.0)), 0.0, 1.0)
					visual.position.y = sin(flight * PI) * 1.25
			if group == "barrels":
				objects[key].scale.y = 0.3 if bool(item.get("spent", false)) else 1.0
			elif group in ["tripwires", "mines"]:
				objects[key].visible = objects[key].visible and not bool(item.get("spent", false))
	for key in objects.keys():
		if not seen.has(key):
			objects[key].free()
			objects.erase(key)


func _sync_corpses() -> void:
	var seen := {}
	if CorpsePose.supported(frame):
		for item in frame.corpses:
			if not CorpsePose.valid(item, frame):
				continue
			var id := str(item.id)
			seen[id] = true
			if not corpses.has(id):
				var visual := CorpseVisual.new()
				proxies.add_child(visual)
				corpses[id] = visual
			var visual: Node3D = corpses[id]
			var carrier: ActorVisual = null
			var key := "ops:%d" % int(item.carrier_id)
			if str(item.mode)=="release" and CorpsePose.transition_valid(item,frame):
				key="ops:%d" % int(item.transition.actor_id)
			if (bool(item.pairing) or str(item.mode)=="release") and actors.has(key):
				carrier = actors[key].get_node("Body") as ActorVisual
			var lod := ActorPose.choose_lod(1.85 * get_viewport().get_visible_rect().size.y / rig.view_size, visual.body.lod)
			var contact_walls: Array = _environment_scene.contact_bounds() if _environment_scene != null and int(frame.corpse_contact_schema)==1 else []
			visual.visible = bool(item.active) and visual.sync(item, frame, lod, carrier, contact_walls)
	for id in corpses.keys():
		if not seen.has(id):
			corpses[id].free()
			corpses.erase(id)


func focus_selected() -> bool:
	for op in frame.get("ops", []):
		if op.id == frame.get("selected_id", -1) and op.active:
			rig.focus = Space.logic_to_world(op.pos)
			rig.apply_pose()
			return true
	return false


func _sync_cones() -> void:
	var seen := {}
	for group in ["ops", "sentries"]:
		for item in frame[group]:
			if not item.active or not item.alive or (group == "ops" and item.id != frame.selected_id):
				continue
			var points: PackedVector2Array = item.get("cone", PackedVector2Array())
			if points.size() < 3:
				continue
			var key := "%s:%s" % [group, item.id]
			seen[key] = true
			if not cones.has(key):
				var instance := MeshInstance3D.new()
				instance.mesh = ImmediateMesh.new()
				instance.material_override = Geometry.material(Color(0.65, 0.85, 0.75, 0.16) if group == "ops" else Color(0.85, 0.57, 0.32, 0.14), true)
				instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				proxies.add_child(instance)
				cones[key] = instance
			var instance: MeshInstance3D = cones[key]
			instance.position = Space.logic_to_world(item.pos, 0.055)
			var mesh: ImmediateMesh = instance.mesh
			mesh.clear_surfaces()
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(1, points.size() - 1):
				for point in [points[0], points[i], points[i + 1]]:
					mesh.surface_add_vertex(Vector3(point.x, 0, point.y) / Space.PIXELS_PER_METRE)
			mesh.surface_end()
	for key in cones.keys():
		if not seen.has(key):
			cones[key].free()
			cones.erase(key)


func _input(event: InputEvent) -> void:
	if host == null or rig == null:
		return
	if host._modal_blocks_input():
		gestures.cancel()
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			gestures.touch(event, rig, true)
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var blocked: bool = pointer_over_ui(event.position)
		var result: Dictionary = gestures.touch(event, rig, blocked)
		if result.tap:
			Commands.dispatch(host, "primary", pick_at(result.position))
		if result.handled:
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		gestures.middle_down = false
	elif event is InputEventMouseMotion and gestures.middle_down:
		gestures.mouse(event, rig)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION and gestures.block_emulated_mouse:
		get_viewport().set_input_as_handled()


func handle_unhandled_input(event: InputEvent) -> bool:
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return true
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return true
	if event is InputEventMouse or event is InputEventGesture:
		if host._modal_blocks_input():
			return true
		if gestures.mouse(event, rig):
			return true
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				Commands.dispatch(host, "primary", pick_at(event.position))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				var ground: Variant = rig.ground_at(event.position)
				if ground is Vector3:
					Commands.dispatch(host, "face", {"valid": true, "pos": Space.world_to_logic(ground)})
		return true
	return false


func pick_at(screen: Vector2) -> Dictionary:
	return Picker.pick(rig.camera, screen, frame)


func cancel_input(reset_contacts: bool = false) -> void:
	gestures.cancel(reset_contacts)


func focus_event(pos: Vector2, event: Dictionary) -> void:
	if not Space.contains_logic(pos):
		return
	cancel_input()
	_focus_attempt = str(event.get("attempt_id", ""))
	_focus_wave = int(event.get("wave_id", -1))
	_focus_tick = BattleLog.record_tick(event)
	_focus_playback_tick = host.replay.playback_time(event) if host.phase == host.Phase.REPLAY else int(event.get("playback_tick", _focus_tick))
	_event_ring.position = Space.logic_to_world(pos, 0.065)
	_event_ring.visible = true
	rig.focus = Space.logic_to_world(pos)
	rig.apply_pose()


func pointer_logic_position() -> Vector2:
	var screen := get_viewport().get_mouse_position()
	if pointer_over_ui(screen):
		return Vector2.INF
	var result := pick_at(screen)
	return result.pos if bool(result.get("valid", false)) else Vector2.INF


func pointer_over_ui(screen: Vector2) -> bool:
	return _control_at(host, screen)


func _control_at(node: Node, screen: Vector2) -> bool:
	if node is CanvasLayer and not node.visible:
		return false
	if node is Control:
		if not node.is_visible_in_tree():
			return false
		if node.mouse_filter == Control.MOUSE_FILTER_STOP and node.get_global_rect().has_point(screen):
			return true
	for child in node.get_children():
		if child == host.get_node("World"):
			continue
		if _control_at(child, screen):
			return true
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_input(true)
		if _probe.active:
			_probe.stop(rig)
			_probe_button.text = "镜头巡检 · 30 秒"
			_probe_result.text = "巡检已取消（应用离开前台）"


func _exit_tree() -> void:
	cancel_input(true)
	if is_instance_valid(host):
		var world := host.get_node_or_null("World")
		if is_instance_valid(world):
			RenderingServer.canvas_item_set_visible(world.get_canvas_item(), world.visible)
