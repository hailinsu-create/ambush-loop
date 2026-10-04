extends Node3D

const Reader := preload("res://scripts/presentation/movement_dust_frame.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
const CAPACITY := 24
const SAVING_CAPACITY := 6
var _slots: Array = []
var _active: Array = []
var _scope: Array = []
var _rejected_geometry := 0


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 3
	for index in CAPACITY:
		var mat := Geometry.material(Color(0.50,0.43,0.31,0.0))
		var slot := {"material":mat,"puffs":[]}
		for puff_index in 2:
			var node := MeshInstance3D.new()
			node.name = "Dust%d_%d" % [index,puff_index]
			node.mesh = mesh
			node.material_override = mat
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.visible = false
			add_child(node)
			slot.puffs.append(node)
		_slots.append(slot)


func clear() -> void:
	_hide()
	_scope.clear()


func _hide() -> void:
	_active.clear()
	for slot: Dictionary in _slots:
		for puff: MeshInstance3D in slot.puffs: puff.visible = false


func update_frame(frame: Dictionary, power_saving: bool = false) -> void:
	_hide()
	var next_scope := [frame.get("movement_fx_source_token"),frame.get("attempt_id"),frame.get("wave_id"),frame.get("level_id"),frame.get("phase"),frame.get("replay"),frame.get("movement_fx_schema"),frame.get("movement_fx_playback_schema")]
	if next_scope != _scope:
		clear()
		_scope = next_scope
	var samples := Reader.active(frame)
	var limit := SAVING_CAPACITY if power_saving else CAPACITY
	for source: Dictionary in samples.slice(0,limit):
		var center := Space.logic_to_world(source.position)
		var direction := Space.facing_direction(source.facing)
		var side := Vector3(-direction.z,0,direction.x)
		var period := 0.62 if source.stance == 1 else (0.36 if source.sprinting else 0.48)
		var clock_cycles: float = source.clock_s / period
		if not _geometry(center) or not _geometry(direction) or not is_finite(clock_cycles):
			_rejected_geometry += 1
			continue
		var phase := fposmod(clock_cycles + float(source.id) * 0.173 + (0.31 if source.group == "enemies" else 0.0),2.0)
		var count := 1 if power_saving else 2
		var states: Array = []
		var opacity := 0.14 if source.stance == 1 else (0.35 if source.sprinting else 0.26)
		for index in count:
			var cycle := fposmod(phase + float(index) * 0.5,1.0)
			var sign_side := -1.0 if (phase < 1.0) == (index == 0) else 1.0
			var size := (0.18 if source.sprinting else 0.13) + cycle * 0.18
			var position := center + side * sign_side * 0.16 - direction * (0.05 + cycle * 0.20) + Vector3(0,0.045 + cycle * 0.10,0)
			var scale := Vector3(size,size * 0.45,size)
			if not _geometry(position) or not _geometry(scale):
				states.clear()
				break
			states.append({"position":position,"scale":scale,"cycle":cycle})
		if states.size() != count:
			_rejected_geometry += 1
			continue
		var slot: Dictionary = _slots[_active.size()]
		slot.material.albedo_color = Color(0.50,0.43,0.31,opacity)
		for index in count:
			var node: MeshInstance3D = slot.puffs[index]
			node.position = states[index].position
			node.scale = states[index].scale
			node.visible = true
		_active.append({"identity":source.identity,"group":source.group,"id":source.id,
			"center":center,"clock_s":source.clock_s,"stance":source.stance,"sprinting":source.sprinting,
			"puff_count":count,"puffs":states,"opacity":opacity})


static func _geometry(value: Vector3) -> bool:
	return value.is_finite() and is_finite(value.length_squared())


func diagnostics() -> Dictionary:
	return {"capacity":CAPACITY,"saving_capacity":SAVING_CAPACITY,"mesh_nodes":_slots.size() * 2,
		"shared_meshes":1,"materials":CAPACITY,"scope":_scope.duplicate(true),
		"active":_active.duplicate(true),"rejected_geometry":_rejected_geometry}
