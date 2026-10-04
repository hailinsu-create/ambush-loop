extends Node3D

## Fixed saved-confirmation volumes; no particles, simulation or wall clock.
const Reader := preload("res://scripts/presentation/tool_fx_frame.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const CAPACITY := 8
const SAVING_CAPACITY := 2
var _slots: Array = []
var _active: Array = []
var _scope: Array = []
var _rejected_geometry := 0


func _ready() -> void:
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.5
	flash_mesh.height = 1.0
	flash_mesh.radial_segments = 10
	flash_mesh.rings = 4
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.5
	smoke_mesh.height = 1.0
	smoke_mesh.radial_segments = 8
	smoke_mesh.rings = 3
	var ring_template := Geometry.ring(self,1.0,0.10,Vector3.ZERO,null)
	var ring_mesh: Mesh = ring_template.mesh
	ring_template.free()
	var flash_mat := Geometry.material(Color(1.0,0.65,0.22,0.94),true)
	var ring_mat := Geometry.material(Color(0.75,0.57,0.37,0.65),true)
	for index in CAPACITY:
		var smoke_mat := Geometry.material(Color(0.35,0.36,0.35,0.0))
		var slot := {"smoke_mat":smoke_mat,"smoke":[]}
		for kind: String in ["flash","ring","smoke0","smoke1","smoke2"]:
			var node := MeshInstance3D.new()
			node.name = "%s%d" % [kind,index]
			node.mesh = flash_mesh if kind == "flash" else (ring_mesh if kind == "ring" else smoke_mesh)
			node.material_override = flash_mat if kind == "flash" else (ring_mat if kind == "ring" else smoke_mat)
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.visible = false
			add_child(node)
			if kind.begins_with("smoke"): slot.smoke.append(node)
			else: slot[kind] = node
		_slots.append(slot)


func _hide() -> void:
	_active.clear()
	for slot: Dictionary in _slots:
		slot.flash.visible = false
		slot.ring.visible = false
		for puff: MeshInstance3D in slot.smoke: puff.visible = false


func clear() -> void:
	_hide()
	_scope.clear()


func update_frame(frame: Dictionary, power_saving: bool = false) -> void:
	_hide()
	var next_scope := [frame.get("tool_fx_source_token"),frame.get("attempt_id"),frame.get("wave_id"),frame.get("level_id"),frame.get("replay"),frame.get("phase"),frame.get("tool_fx_schema"),frame.get("tool_fx_playback_schema"),frame.get("visual_unsupported"),frame.get("schema")]
	if next_scope != _scope:
		clear()
		_scope = next_scope
	if frame.get("recorded_phase") == 2 and frame.get("tool_fx_terminal_reason") == "abort":
		clear()
		return
	var samples := Reader.active(frame)
	var limit := SAVING_CAPACITY if power_saving else CAPACITY
	for index in range(maxi(0,samples.size() - limit),samples.size()):
		var source: Dictionary = samples[index]
		var center := Space.logic_to_world(source.position)
		var radius: float = float(source.radius) / Space.PIXELS_PER_METRE
		var age: int = source.age_ticks
		var flash_size := 0.65 + float(age) * 0.09
		var ring_size := radius * 2.0 * minf(float(age + 1) / 12.0,1.0)
		var puff_size := (0.35 + radius * 0.28 + float(age) * 0.005)
		if not _geometry(center) or not is_finite(radius) or not _size(flash_size) or not _size(ring_size) or not _size(puff_size):
			_rejected_geometry += 1
			continue
		var count := 1 if power_saving else 3
		var puff_states: Array = []
		for puff_index in count:
			var angle := TAU * fposmod(float(source.seq) * 0.61803398875 + float(puff_index) / 3.0,1.0)
			var offset := Vector3(cos(angle),0,sin(angle)) * radius * 0.16
			var rise := 0.25 + float(age) * 0.014 + float(puff_index) * 0.16
			var position := center + offset + Vector3(0,rise,0)
			var scale := Vector3(1.0,1.15 + float(puff_index) * 0.10,1.0) * puff_size
			if not _geometry(position) or not _geometry(scale):
				puff_states.clear()
				break
			puff_states.append({"position":position,"scale":scale})
		if puff_states.size() != count:
			_rejected_geometry += 1
			continue
		var slot: Dictionary = _slots[_active.size()]
		slot.flash.position = center + Vector3(0,0.30,0)
		slot.flash.scale = Vector3.ONE * flash_size
		slot.flash.visible = age < 8
		slot.ring.position = center + Vector3(0,0.035,0)
		slot.ring.scale = Vector3(ring_size,1,ring_size)
		slot.ring.visible = age < 18
		var smoke_visible := age >= 5
		var opacity := 0.52 * minf(float(age - 4) / 10.0,1.0) * maxf(1.0 - float(age) / Reader.LIFETIME_TICKS,0.0)
		slot.smoke_mat.albedo_color = Color(0.35,0.36,0.35,maxf(opacity,0.0))
		for puff_index in count:
			var puff: MeshInstance3D = slot.smoke[puff_index]
			puff.position = puff_states[puff_index].position
			puff.scale = puff_states[puff_index].scale
			puff.visible = smoke_visible
		_active.append({"effect_id":source.effect_id,"tool_id":source.tool_id,"seq":source.seq,
			"kind":source.kind,"age_ticks":age,"center":center,"flash_visible":slot.flash.visible,
			"ring_visible":slot.ring.visible,"smoke_count":count if smoke_visible else 0,
			"smoke":puff_states if smoke_visible else [],"opacity":maxf(opacity,0.0)})


static func _geometry(value: Vector3) -> bool:
	return value.is_finite() and is_finite(value.length_squared())


static func _size(value: float) -> bool:
	return is_finite(value) and value > 0.0 and _geometry(Vector3.ONE * value)


func diagnostics() -> Dictionary:
	return {"capacity":CAPACITY,"saving_capacity":SAVING_CAPACITY,"mesh_nodes":_slots.size() * 5,
		"shared_meshes":3,"materials":CAPACITY + 2,"rejected_geometry":_rejected_geometry,
		"scope":_scope.duplicate(true),"active":_active.duplicate(true)}
