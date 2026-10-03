extends Node3D

const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Pose := preload("res://scripts/presentation/corpse_pose.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Contact := preload("res://scripts/presentation/corpse_contact.gd")
var body := Actor.new()
var reference := Actor.new()
var _palm_cache := {}
var _bounds_cache := {}


func _init() -> void:
	body.name = "Body"
	add_child(body)
	reference.name = "Reference"
	reference.visible = false
	add_child(reference)


func sync(item: Dictionary, frame: Dictionary, lod: int, carrier: Actor, walls: Array = []) -> bool:
	if not Pose.valid(item, frame) or not body.set_asset(str(item.model), lod, Pose.REVISION):
		return false
	# Root is always the historical gameplay loot position. Each refresh resets
	# the child transform before socket alignment, so seeks cannot accumulate it.
	position = Space.logic_to_world(item.pos)
	body.transform = Transform3D.IDENTITY
	body.mount_item("")
	var age := Pose.age(item, frame, "transition_age_s")
	var mode := str(item.mode)
	if mode in ["grab", "release"] and not Pose.transition_valid(item, frame):
		mode = "hold" if bool(item.pairing) else "ground"
	if mode == "grab" and age >= 1.0:
		mode = "hold"
	if mode == "release" and age >= 0.7:
		mode = "ground"
	var clip := "corpse_lift" if mode == "grab" else ("corpse_lower" if mode == "release" else ("corpse_dragged" if mode == "hold" else "corpse_prone"))
	var anchor: Dictionary = item.carrier if bool(item.pairing) else item.ground_anchor
	if anchor.is_empty() and bool(item.ever_grabbed):
		anchor = item.carrier
	if anchor.is_empty():
		body.rotation.y = Space.facing_yaw(float(item.facing))
		var death_age := Pose.age(item, frame, "death_age_s")
		body.sample_pose("death_prone" if death_age < 1.2 else "corpse_prone", death_age if death_age < 1.2 else 0.0)
		return true
	body.rotation.y = Space.facing_yaw(float(anchor.facing))
	body.sample_pose("corpse_dragged", 0.0)
	var shoulders := (body.shoulder("L") + body.shoulder("R")) * 0.5
	var local_shoulders := body.global_transform.affine_inverse()*shoulders
	var palms: Vector3
	if mode == "hold" and carrier != null:
		palms = (carrier.bone_socket("support_hand").position + carrier.bone_socket("weapon_hand").position) * 0.5
	else:
		# Lift/lower use the held endpoint anchor, not a moving intermediate
		# shoulder marker. The authored 20cm backshift is applied by the clip once.
		palms = Space.logic_to_world(anchor.pos) + Basis(Vector3.UP, Space.facing_yaw(float(anchor.facing))) * _reference_palms(anchor, lod)
	var correction := palms - shoulders
	body.sample_pose(clip, age if mode in ["grab", "release"] else 0.0)
	body.position += correction
	set_meta("contact_supported",int(frame.get("corpse_contact_schema",0))==Contact.FORMAT and bool(frame.get("environment_supported",false)) and not walls.is_empty())
	set_meta("contact_resolved",true)
	if bool(get_meta("contact_supported")):
		var local_palms := _reference_palms(anchor,0)
		if mode=="hold" and carrier != null:
			local_palms=carrier.global_transform.affine_inverse()*palms
		var contact := Contact.choose(_pose_bounds(str(item.model),clip,age if mode in ["grab","release"] else 0.0),local_shoulders,local_palms,Space.logic_to_world(anchor.pos),float(anchor.facing),walls)
		set_meta("contact_resolved",bool(contact.resolved))
		if bool(contact.resolved):
			body.global_transform=contact.transform
			if carrier != null and mode in ["hold","grab","release"]:
				carrier.rotation.y=Space.facing_yaw(float(contact.facing))
			set_meta("contact_facing",float(contact.facing))
	set_meta("mode", mode)
	set_meta("source_wave_id", item.source_wave_id)
	return true


func _pose_bounds(model: String, clip: String, seconds: float) -> AABB:
	var key := model+":"+clip
	# Static endpoints dominate; transient poses are sampled from the same
	# immutable LOD0 rig without an accumulating clock or unbounded age cache.
	if is_zero_approx(seconds) and _bounds_cache.has(key):
		return _bounds_cache[key]
	reference.transform=Transform3D.IDENTITY
	reference.set_asset(model,0,Pose.REVISION)
	reference.sample_pose(clip,seconds)
	var bounds := Contact.skin_bounds(reference)
	if is_zero_approx(seconds):
		_bounds_cache[key]=bounds
	return bounds


func _reference_palms(anchor: Dictionary, lod: int) -> Vector3:
	var key := "%s:%d:%d" % [anchor.model, lod, int(anchor.stance)]
	if not _palm_cache.has(key):
		reference.transform = Transform3D.IDENTITY
		reference.set_asset(str(anchor.model), lod, Pose.REVISION)
		var pose := {"action": "corpse_drag", "seconds": 0.0}
		if int(anchor.stance) == 1:
			pose.merge({"base_action": "crouch", "base_seconds": 0.0, "upper_action": "corpse_drag", "upper_seconds": 0.0, "preserve_upper_world_basis": false})
		reference.sample_layers(pose)
		_palm_cache[key] = (reference.bone_socket("support_hand").position + reference.bone_socket("weapon_hand").position) * 0.5 - reference.global_position
	return _palm_cache[key]
