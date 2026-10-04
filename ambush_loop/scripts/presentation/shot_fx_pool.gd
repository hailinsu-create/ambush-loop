extends Node3D

## Saved presentation only. Fixed meshes, one hidden R5 sampler, bounded values.
const Reader := preload("res://scripts/presentation/shot_fx_frame.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const CAPACITY := 12
const SAVING_CAPACITY := 4
const CACHE_CAPACITY := 48
const SAMPLE_LOD := 0
const TARGET_HEIGHT := 1.05 # Saved 2D hit cue, not a 3D collision point.
var _slots: Array = []
var _cache: Array = []
var _scope: Array = []
var _sampler: Node3D
var _active: Array = []
var _sample_calls := 0
var _rejected_sockets := 0


func _ready() -> void:
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.5
	flash_mesh.height = 1.0
	flash_mesh.radial_segments = 6
	flash_mesh.rings = 4
	var tracer_mesh := CylinderMesh.new()
	tracer_mesh.top_radius = 0.018
	tracer_mesh.bottom_radius = 0.018
	tracer_mesh.height = 1.0
	tracer_mesh.radial_segments = 6
	tracer_mesh.rings = 1
	var hit_mesh := SphereMesh.new()
	hit_mesh.radius = 0.5
	hit_mesh.height = 1.0
	hit_mesh.radial_segments = 6
	hit_mesh.rings = 4
	var flash_mat := Geometry.material(Color(1.0,0.82,0.34),true)
	var tracer_mat := Geometry.material(Color(1.0,0.79,0.40,0.72),true)
	var hit_mat := Geometry.material(Color(1.0,0.50,0.24,0.85),true)
	for index in CAPACITY:
		var slot := {}
		for kind in ["muzzle","tracer","impact"]:
			var mesh := MeshInstance3D.new()
			mesh.name = "%s%d" % [kind,index]
			mesh.mesh = flash_mesh if kind=="muzzle" else (tracer_mesh if kind=="tracer" else hit_mesh)
			mesh.material_override = flash_mat if kind=="muzzle" else (tracer_mat if kind=="tracer" else hit_mat)
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.visible = false
			add_child(mesh)
			slot[kind] = mesh
		_slots.append(slot)
	_new_sampler()


func _new_sampler() -> void:
	_sampler = ActorVisual.new()
	_sampler.name = "SavedMuzzleSampler"
	_sampler.visible = false
	add_child(_sampler)


func clear() -> void:
	_hide()
	_cache.clear()
	_scope.clear()
	# Neutral/phase changes release the old model too. No per-id asset cache.
	if _sampler != null and not _sampler.asset_id.is_empty():
		_sampler.free()
		_new_sampler()


func _hide() -> void:
	_active.clear()
	for slot: Dictionary in _slots:
		for mesh: MeshInstance3D in slot.values(): mesh.visible = false


func update_frame(frame: Dictionary, power_saving: bool = false) -> void:
	_hide()
	var next_scope := [frame.get("shot_fx_source_token"),frame.get("attempt_id"),frame.get("wave_id"),frame.get("level_id"),frame.get("replay"),frame.get("phase"),frame.get("actor_asset_revision"),frame.get("animation_schema"),frame.get("shot_fx_schema"),frame.get("shot_fx_playback_schema"),frame.get("animation_supported"),frame.get("visual_unsupported"),frame.get("schema"),frame.get("wave_count")]
	if next_scope != _scope:
		clear()
		_scope = next_scope
	if frame.get("recorded_phase") != 1 or frame.get("phase") not in [1,4] or frame.get("shot_fx_schema") != Reader.FORMAT:
		clear()
		return
	var samples := Reader.active(frame)
	var limit := SAVING_CAPACITY if power_saving else CAPACITY
	# Keep the most recent original events. Slots never grow on repeated seek.
	for index in range(maxi(0,samples.size()-limit),samples.size()):
		var shot: Dictionary = samples[index]
		var saved := shot.duplicate(true)
		saved.erase("age_ticks")
		var socket := _saved_muzzle(saved)
		if socket.is_empty(): continue
		var slot: Dictionary = _slots[_active.size()]
		var muzzle: Vector3 = socket.position
		var target := Space.logic_to_world(shot.target_pos,TARGET_HEIGHT)
		var age: int = shot.age_ticks
		var delta := target-muzzle
		var flash: MeshInstance3D = slot.muzzle
		flash.position = muzzle
		flash.scale = Vector3.ONE*(0.22-0.04*age)
		flash.visible = age<3
		var tracer: MeshInstance3D = slot.tracer
		tracer.visible = not power_saving and age<6 and delta.length()>0.0001
		if tracer.visible:
			var direction := delta.normalized()
			var across := direction.cross(Vector3.UP if absf(direction.y)<0.99 else Vector3.RIGHT).normalized()
			tracer.transform = Transform3D(Basis(across,direction*delta.length(),across.cross(direction)),(muzzle+target)*0.5)
		var hit: MeshInstance3D = slot.impact
		hit.position = target
		hit.scale = Vector3.ONE*(0.16+0.015*age)
		hit.visible = float(shot.damage)>0.0
		_active.append({"event_id":shot.event_id,"seq":shot.seq,"age_ticks":age,"visual_weapon":shot.visual_weapon,"muzzle":muzzle,"target":target,"damage":shot.damage,"muzzle_visible":flash.visible,"tracer_visible":tracer.visible,"impact_visible":hit.visible})


func _saved_muzzle(saved: Dictionary) -> Dictionary:
	var key := hash([SAMPLE_LOD,saved])
	for entry: Dictionary in _cache:
		# A hash is only a fast prefilter, never evidence of descriptor equality.
		if entry.key==key and entry.saved==saved: return {"position":entry.position}
	_sample_calls += 1
	_sampler.position = Space.logic_to_world(saved.source_pos)
	_sampler.rotation = Vector3(0,Space.facing_yaw(float(saved.pose.get("visual_facing",saved.source_facing))),0)
	_sampler.scale = Vector3.ONE
	if not _sampler.set_asset(saved.visual_model,SAMPLE_LOD,saved.actor_asset_revision) or not _sampler.mount_item(saved.visual_weapon) or not _sampler.sample_layers(saved.pose):
		_rejected_sockets += 1
		return {}
	if _sampler.asset_id != saved.visual_model or _sampler.asset_revision != saved.actor_asset_revision or _sampler.equipped_id != saved.visual_weapon:
		_rejected_sockets += 1
		return {}
	var socket: Dictionary = _sampler.item_socket("muzzle")
	var transform: Variant = socket.get("transform")
	if not transform is Transform3D or not transform.origin.is_finite() or not transform.basis.is_finite():
		_rejected_sockets += 1
		return {}
	var point: Vector3 = transform.origin
	_cache.append({"key":key,"saved":saved.duplicate(true),"position":point})
	if _cache.size()>CACHE_CAPACITY: _cache.pop_front()
	return {"position":point}


func diagnostics() -> Dictionary:
	return {"capacity":CAPACITY,"mesh_nodes":_slots.size()*3,"cache_size":_cache.size(),"cache_capacity":CACHE_CAPACITY,"sample_lod":SAMPLE_LOD,"sample_calls":_sample_calls,"rejected_sockets":_rejected_sockets,"scope":_scope.duplicate(true),"active":_active.duplicate(true)}
