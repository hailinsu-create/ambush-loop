extends Node3D

## A visual model and explicit pose sampler. No host, simulation, clock or
## automatic animation advancement is held here. The caller supplies time.
const Assets := preload("res://scripts/presentation/asset_library.gd")
var asset_id := ""
var lod := -1
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var equipped: Node3D
var equipped_id := ""
var sampled_action := "idle"
var sampled_time := 0.0
var _record: Dictionary = {}
var _attachment: BoneAttachment3D


func set_asset(id: String, level: int) -> bool:
	if asset_id == id and lod == level:
		return true
	var entry := Assets.asset_record(id)
	if entry.get("category", "") != "character" or not Assets.has_asset(id, level):
		return false
	var replacement := Assets.instantiate(id, level)
	if replacement == null:
		return false
	var rig := find_type(replacement, "Skeleton3D") as Skeleton3D
	var animation := find_type(replacement, "AnimationPlayer") as AnimationPlayer
	if rig == null or animation == null:
		replacement.free()
		return false
	var previous_item := equipped_id
	var previous_action := sampled_action
	var previous_time := sampled_time
	if model != null:
		model.free()
	model = replacement
	model.name = "Model"
	add_child(model)
	skeleton = rig
	player = animation
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	asset_id = id
	lod = level
	_record = entry
	equipped = null
	_attachment = null
	equipped_id = ""
	if not previous_item.is_empty():
		mount_item(previous_item)
	sample_pose(previous_action, previous_time)
	return true


func sample_pose(action: String, elapsed: float) -> bool:
	if player == null or not is_finite(elapsed):
		return false
	if action == sampled_action and is_equal_approx(maxf(elapsed, 0.0), sampled_time) and player.current_animation == action:
		return true
	var clip: Dictionary = {}
	for row in _record.get("animations", []):
		if str(row.name) == action:
			clip = row
			break
	if clip.is_empty() or not player.has_animation(action):
		return false
	var duration: float = player.get_animation(action).length
	var seconds := fposmod(maxf(elapsed, 0.0), duration) if bool(clip.loop) else clampf(elapsed, 0.0, duration)
	skeleton.reset_bone_poses()
	player.play(action)
	player.seek(seconds, true, true)
	skeleton.force_update_all_bone_transforms()
	_sync_attachment()
	sampled_action = action
	sampled_time = maxf(elapsed, 0.0)
	if equipped != null:
		equipped.visible = action not in ["pickup", "deploy", "haul", "death"]
	return true


func mount_item(id: String) -> bool:
	if id == equipped_id:
		return true
	if id.is_empty():
		if _attachment != null:
			_attachment.free()
		_attachment = null
		equipped = null
		equipped_id = ""
		return true
	var item_record := Assets.asset_record(id)
	if item_record.get("category", "") not in ["weapon", "tool"] or skeleton == null:
		return false
	var replacement := Assets.instantiate(id, mini(lod, 1))
	if replacement == null:
		return false
	var socket: Dictionary = _record.sockets.weapon_hand
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = str(socket.bone)
	skeleton.add_child(attachment)
	attachment.add_child(replacement)
	var rotation := vector(socket.get("rotation_bone_local_deg", [0, 0, 0])) * PI / 180.0
	var basis := Basis.from_euler(rotation)
	var grip := replacement.find_child(id + "__socket_grip", true, false) as Node3D
	var local_grip := _local_transform(replacement, grip).origin if grip != null else Vector3.ZERO
	replacement.transform = Transform3D(basis, vector(socket.position_bone_local_m) - basis * local_grip)
	if _attachment != null:
		_attachment.free()
	_attachment = attachment
	equipped = replacement
	equipped_id = id
	equipped.visible = sampled_action not in ["pickup", "deploy", "haul", "death"]
	skeleton.force_update_all_bone_transforms()
	_sync_attachment()
	return true


func _sync_attachment() -> void:
	# BoneAttachment's deferred skeleton notification otherwise leaves the
	# previous pose's muzzle visible until the next render frame after seek/LOD.
	if _attachment != null:
		_attachment.transform = skeleton.get_bone_global_pose(skeleton.find_bone(_attachment.bone_name))


func bone_socket(name: String) -> Dictionary:
	var socket: Dictionary = _record.get("sockets", {}).get(name, {})
	if socket.is_empty() or skeleton == null:
		return {}
	var bone := skeleton.find_bone(str(socket.bone))
	if bone < 0:
		return {}
	return {"position": skeleton.global_transform * skeleton.get_bone_global_pose(bone) * vector(socket.position_bone_local_m)}


func item_socket(name: String) -> Dictionary:
	if equipped == null:
		return {}
	var marker := equipped.find_child(equipped_id + "__socket_" + name, true, false) as Node3D
	return {"transform": marker.global_transform} if marker != null else {}


static func _local_transform(root: Node3D, marker: Node3D) -> Transform3D:
	var value := marker.transform
	var parent := marker.get_parent()
	while parent != root:
		if parent is Node3D:
			value = parent.transform * value
		parent = parent.get_parent()
	return value


static func vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


static func find_type(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for child in node.get_children():
		var found := find_type(child, type)
		if found != null:
			return found
	return null
