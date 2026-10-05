extends RefCounted

## Separate disconnected authored solids without moving vertices or changing
## the immutable GLB. Each solid gets its own cutaway bounds, so empty space
## in a landmark's overall AABB cannot hide the whole landmark.
const FORMAT := 1

static func split(root: Node) -> int:
	var count := 0
	for child in root.get_children():
		count+=split(child)
	if not root is MeshInstance3D or root.mesh==null:
		return count
	# This policy is for the accepted static ENV landmark only. Preserve any
	# future animated/non-triangle resource intact rather than discarding data.
	if root.mesh.get_blend_shape_count()>0:
		return count
	for surface in root.mesh.get_surface_count():
		if root.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES or root.mesh.surface_get_format(surface)&Mesh.ARRAY_FORMAT_BONES:
			return count
	var parts: Array = []
	for surface in root.mesh.get_surface_count():
		var encoded: Dictionary = RenderingServer.mesh_get_surface(root.mesh.get_rid(),surface)
		for component: Dictionary in _components(root.mesh.surface_get_arrays(surface)):
			var mesh := ArrayMesh.new()
			# Godot 4.7.2's serialized surface format preserves imported compressed
			# positions and tangent frames exactly. Never decode/re-encode them.
			mesh.set("_surfaces",[_packed_surface(encoded,component)])
			mesh.custom_aabb=component.bounds
			parts.append({"mesh":mesh,"bounds":component.bounds,"material":root.get_active_material(surface)})
	if parts.size()<=root.mesh.get_surface_count():
		return count
	var parent := Node3D.new()
	parent.name=str(root.name)+"_Cutaway"
	root.get_parent().add_child(parent)
	parent.transform=root.transform
	for index in parts.size():
		var display := MeshInstance3D.new()
		display.name="Solid_%d" % index
		display.mesh=parts[index].mesh
		display.set_surface_override_material(0,parts[index].material)
		display.cast_shadow=root.cast_shadow
		display.layers=root.layers
		display.set_meta("cutaway_part",index)
		display.set_meta("cutaway_bounds",parts[index].bounds)
		parent.add_child(display)
	root.free()
	return count+parts.size()

static func _gather(bytes: PackedByteArray, used: PackedInt32Array, stride: int, offset: int = 0) -> PackedByteArray:
	var dense := PackedByteArray()
	for index in used:
		dense.append_array(bytes.slice(offset+index*stride,offset+(index+1)*stride))
	return dense

static func _packed_surface(source: Dictionary, component: Dictionary) -> Dictionary:
	var used: PackedInt32Array = component.used
	var format: int = source.format
	var count: int = source.vertex_count
	var position_stride := RenderingServer.mesh_surface_get_format_vertex_stride(format,count)
	var normal_stride := RenderingServer.mesh_surface_get_format_normal_tangent_stride(format,count)
	var bytes: PackedByteArray = source.vertex_data
	var vertices := _gather(bytes,used,position_stride)
	vertices.append_array(_gather(bytes,used,normal_stride,count*position_stride))
	var indices: PackedInt32Array = component.indices
	var index_stride := RenderingServer.mesh_surface_get_format_index_stride(format,used.size())
	var packed_indices := PackedByteArray()
	packed_indices.resize(indices.size()*index_stride)
	for index in indices.size():
		if index_stride==2:
			packed_indices.encode_u16(index*index_stride,indices[index])
		else:
			packed_indices.encode_u32(index*index_stride,indices[index])
	# Original AABB/UV scale are the decoder's coordinate basis for compressed
	# attributes. Per-solid bounds are separate, for cutaway and GPU culling.
	var result := {"format":format,"primitive":source.primitive,"vertex_data":vertices,
		"vertex_count":used.size(),"aabb":source.aabb,"index_data":packed_indices,"index_count":indices.size()}
	if source.has("uv_scale"):
		result.uv_scale=source.uv_scale
	if source.has("attribute_data"):
		result.attribute_data=_gather(source.attribute_data,used,RenderingServer.mesh_surface_get_format_attribute_stride(format,count))
	return result

static func _find(parents: PackedInt32Array, index: int) -> int:
	while parents[index]!=index:
		index=parents[index]
	return index

static func _join(parents: PackedInt32Array, left: int, right: int) -> void:
	var a := _find(parents,left)
	var b := _find(parents,right)
	if a!=b:
		parents[maxi(a,b)]=mini(a,b)

static func _components(arrays: Array) -> Array:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		for index in vertices.size():
			indices.append(index)
	var parents := PackedInt32Array()
	parents.resize(vertices.size())
	var points := {}
	for index in vertices.size():
		parents[index]=index
	for index in vertices.size():
		# GLB hard-normal seams use separate indices at identical positions.
		var point: Vector3 = vertices[index]*100000.0
		var key := Vector3i(roundi(point.x),roundi(point.y),roundi(point.z))
		if points.has(key):
			_join(parents,index,int(points[key]))
		else:
			points[key]=index
	for offset in range(0,indices.size(),3):
		_join(parents,indices[offset],indices[offset+1])
		_join(parents,indices[offset],indices[offset+2])
	var groups := {}
	for offset in range(0,indices.size(),3):
		var key := _find(parents,indices[offset])
		if not groups.has(key):
			groups[key]=PackedInt32Array()
		for slot in 3:
			groups[key].append(indices[offset+slot])
	var result := []
	for group: PackedInt32Array in groups.values():
		var mapped := {}
		var used := PackedInt32Array()
		var remapped := PackedInt32Array()
		for index in group:
			if not mapped.has(index):
				mapped[index]=used.size()
				used.append(index)
			remapped.append(mapped[index])
		var bounds := AABB(vertices[used[0]],Vector3.ZERO)
		for index in used:
			bounds=bounds.expand(vertices[index])
		result.append({"used":used,"indices":remapped,"bounds":bounds})
	return result
