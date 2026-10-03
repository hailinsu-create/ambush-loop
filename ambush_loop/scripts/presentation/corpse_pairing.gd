extends RefCounted

## Optional visual policy. The approach and return intervals are ungripped;
## the lift/lower interval uses a crouched torso and two unstretched arms.
const FORMAT := 1
const FLOOR_Y := 0.006
const REACH_SECONDS := 0.2
const LET_GO_SECONDS := 0.5
const EDGE_EPSILON := 0.0000001

static func clip_seconds(mode: String, age: float) -> float:
	if mode=="grab":
		return clampf((age-REACH_SECONDS)/(1.0-REACH_SECONDS),0.0,1.0)
	if mode=="release":
		return clampf(age/LET_GO_SECONDS,0.0,1.0)*0.7
	return 0.0

static func gripping(mode: String, age: float) -> bool:
	return mode=="hold" or (mode=="grab" and age+EDGE_EPSILON>=REACH_SECONDS) or (mode=="release" and age<=LET_GO_SECONDS+EDGE_EPSILON)

static func _poses(reference: Node3D, anchor: Dictionary, lod: int, kind: String, cache: Dictionary, frame: Dictionary) -> Array:
	var key := "%s:%d:%d:%s" % [anchor.model,lod,int(anchor.stance),kind]
	if kind=="neutral" or not cache.has(key):
		if not reference.set_asset(str(anchor.model),lod,preload("res://scripts/presentation/corpse_pose.gd").REVISION):
			return []
		var stance: int = int(anchor.stance)
		var pose: Dictionary
		if kind=="neutral":
			pose={"action":"idle" if stance==0 else "crouch","seconds":0.0}
			for recorded: Dictionary in frame.ops:
				if int(recorded.id)==int(anchor.id):
					var ordinary: Dictionary = recorded.duplicate(true)
					ordinary.erase("corpse_pose")
					ordinary.hauling=false
					pose=preload("res://scripts/presentation/actor_pose.gd").sample(ordinary,frame,"ops")
					break
		else:
			pose={"action":"corpse_drag","seconds":0.0}
			if kind=="deep" or stance==1:
				pose.merge({"base_action":"crouch","base_seconds":0.0,"upper_action":"corpse_drag","upper_seconds":0.0,"preserve_upper_world_basis":false})
		if not reference.sample_layers(pose):
			return []
		var bones := []
		for index in reference.skeleton.get_bone_count():
			bones.append(reference.skeleton.get_bone_pose(index))
		if kind=="neutral":
			return bones # A changing weapon/clock must not grow a pose cache.
		cache[key]=bones
	return cache[key]

static func prepare(carrier: Node3D, reference: Node3D, anchor: Dictionary, mode: String, age: float, contact_facing: float, cache: Dictionary, frame: Dictionary) -> bool:
	if mode not in ["grab","release"]:
		return true
	var feet := []
	for side in ["L","R"]:
		feet.append(carrier.skeleton.get_bone_global_pose(carrier.skeleton.find_bone("foot."+side)))
	var amount: float
	var endpoint := "held"
	var turn_amount := 1.0
	if mode=="grab":
		if age<REACH_SECONDS:
			amount=smoothstep(0.0,REACH_SECONDS,age)
			endpoint="neutral"
			turn_amount=amount
		else:
			amount=1.0-smoothstep(REACH_SECONDS,1.0,age)
	else:
		if age<=LET_GO_SECONDS:
			amount=smoothstep(0.0,LET_GO_SECONDS,age)
		else:
			amount=1.0-smoothstep(LET_GO_SECONDS,0.7,age)
			endpoint="neutral"
			turn_amount=amount
	var base := _poses(reference,anchor,carrier.lod,endpoint,cache,frame)
	var deep := _poses(reference,anchor,carrier.lod,"deep",cache,frame)
	if base.is_empty() or deep.is_empty():
		return false
	for index in base.size():
		carrier.skeleton.set_bone_pose(index,base[index].interpolate_with(deep[index],amount))
	carrier.skeleton.force_update_all_bone_transforms()
	var spine: int = carrier.skeleton.find_bone("spine")
	var torso: Transform3D = carrier.skeleton.get_bone_global_pose(spine)
	var tilt := atan2(torso.basis.y.z,torso.basis.y.y)
	var desired := lerpf(tilt,deg_to_rad(90.0),amount)
	torso.basis=Basis(Vector3.RIGHT,desired-tilt)*torso.basis
	carrier.skeleton.set_bone_global_pose(spine,torso)
	carrier.skeleton.force_update_all_bone_transforms()
	var space := preload("res://scripts/presentation/world_space.gd")
	carrier.rotation.y=lerp_angle(space.facing_yaw(float(anchor.facing)),space.facing_yaw(contact_facing),turn_amount)
	var planted := true
	for index in 2:
		var side: String = ["L","R"][index]
		var skeleton: Skeleton3D = carrier.skeleton
		var target: Transform3D = feet[index]
		planted=_limb(skeleton,skeleton.find_bone("thigh."+side),skeleton.find_bone("shin."+side),skeleton.find_bone("foot."+side),target.origin,target.basis) and planted
	carrier.mark_pose_modified()
	return planted

static func _turn(skeleton: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	var source := from.normalized()
	var target := to.normalized()
	var axis := source.cross(target)
	var dot := clampf(source.dot(target),-1.0,1.0)
	# Quaternion(from,to) treats tiny rotations as identity. At a nearly held
	# endpoint that left a measurable palm error even though reach was valid.
	if axis.length_squared()>0.000000000001:
		pose.basis=Basis(axis.normalized(),atan2(axis.length(),dot))*pose.basis
	elif dot<0.0:
		axis=source.cross(Vector3.RIGHT if absf(source.x)<0.9 else Vector3.UP)
		pose.basis=Basis(axis.normalized(),PI)*pose.basis
	skeleton.set_bone_global_pose(bone,pose)
	skeleton.force_update_all_bone_transforms()

static func hand(carrier: Node3D, side: String, socket: String, target: Vector3) -> bool:
	var skeleton: Skeleton3D = carrier.skeleton
	var upper := skeleton.find_bone("upper_arm."+side)
	var lower := skeleton.find_bone("forearm."+side)
	var wrist := skeleton.find_bone("hand."+side)
	if mini(upper,mini(lower,wrist))<0:
		return false
	var c := skeleton.get_bone_global_pose(wrist).origin
	var palm: Vector3 = skeleton.global_transform.affine_inverse()*carrier.bone_socket(socket).position
	var goal := skeleton.global_transform.affine_inverse()*target-(palm-c)
	var solved := _limb(skeleton,upper,lower,wrist,goal,skeleton.get_bone_global_pose(wrist).basis)
	carrier.mark_pose_modified()
	return solved and carrier.bone_socket(socket).position.distance_to(target)<0.001

static func _limb(skeleton: Skeleton3D, upper: int, lower: int, endpoint: int, goal: Vector3, endpoint_basis: Basis) -> bool:
	var a := skeleton.get_bone_global_pose(upper).origin
	var b := skeleton.get_bone_global_pose(lower).origin
	var c := skeleton.get_bone_global_pose(endpoint).origin
	var first := a.distance_to(b)
	var second := b.distance_to(c)
	var distance := a.distance_to(goal)
	if distance>first+second+0.00001 or distance<absf(first-second)+0.00001:
		return false
	var direction := (goal-a).normalized()
	var along := (first*first-second*second+distance*distance)/(2.0*distance)
	var height := sqrt(maxf(first*first-along*along,0.0))
	var pole := (b-a)-direction*(b-a).dot(direction)
	if pole.length_squared()<0.000001:
		pole=Vector3.RIGHT-direction*direction.x
	if pole.length_squared()<0.000001:
		pole=Vector3.UP-direction*direction.y
	var elbow := a+direction*along+pole.normalized()*height
	_turn(skeleton,upper,b-a,elbow-a)
	b=skeleton.get_bone_global_pose(lower).origin
	c=skeleton.get_bone_global_pose(endpoint).origin
	_turn(skeleton,lower,c-b,goal-b)
	var end_pose := skeleton.get_bone_global_pose(endpoint)
	end_pose.basis=endpoint_basis
	skeleton.set_bone_global_pose(endpoint,end_pose)
	skeleton.force_update_all_bone_transforms()
	return skeleton.get_bone_global_pose(endpoint).origin.distance_to(goal)<0.0001
