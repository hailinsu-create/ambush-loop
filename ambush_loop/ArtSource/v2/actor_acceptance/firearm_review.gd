extends "res://base_review.gd"

# Optional presentation clips, mounted in a standalone scene. No World/state.
const ROLES = ["operator_rifle", "operator_mg", "operator_scout"]
var baseline := OS.get_environment("ACTOR_FIREARM_BASELINE") == "1"
var contacts: Array = []
var seams: Array = []
var speed_checks: Array = []

func vec(point: Array) -> Vector3:
	return Vector3(float(point[0]), float(point[1]), float(point[2]))

func named_point(gun: Node3D, profile: Dictionary, key: String) -> Vector3:
	var marker := gun.find_child(profile.weapon_id + "__socket_" + key, true, false) as Node3D
	if baseline and key != "muzzle": return gun.global_transform * vec(profile.sockets[key])
	check(marker != null, "actual gun marker: " + profile.weapon_id + "/" + key)
	return marker.global_position if marker != null else Vector3(INF, INF, INF)

func sample_contact(subject: Node3D, gun: Node3D, profile: Dictionary) -> Dictionary:
	var sk := rig(subject)
	var left := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.L")) * Vector3(0, .035, 0)
	var right := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.R")) * Vector3(0, .035, 0)
	var eye := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head")) * Vector3(.037, .139, -.106)
	var sight := named_point(gun, profile, "sight")
	var direction := -gun.global_basis.z.normalized()
	var delta := eye - sight
	var muzzle := named_point(gun, profile, "muzzle")
	var grip := gun.find_child(profile.weapon_id + "__socket_grip", true, false) as Node3D
	return {"support_m": left.distance_to(named_point(gun, profile, "pose_support")),
		"reload_contact_m": left.distance_to(named_point(gun, profile, "reload_contact")),
		"sight_line_m": (delta - direction * delta.dot(direction)).length(),
		"right_grip_m": right.distance_to(grip.global_position),
		"muzzle_forward_m": (muzzle - grip.global_position).dot(direction),
		"muzzle_world": [muzzle.x, muzzle.y, muzzle.z], "muzzle_direction": [direction.x, direction.y, direction.z]}

func skeleton_matrices(subject: Node3D) -> Array:
	var sk := rig(subject); var result: Array = []
	for index in sk.get_bone_count(): result.append(sk.get_bone_global_pose(index))
	return result

func matrix_error(before: Array, after: Array) -> float:
	var error := 0.0
	for i in before.size():
		error = maxf(error, before[i].origin.distance_to(after[i].origin))
		for axis in 3: error = maxf(error, before[i].basis[axis].distance_to(after[i].basis[axis]))
	return error

func capture(name: String, context: Dictionary) -> void:
	# Poses are already forced and camera/material setters are synchronous.
	# Wait for one rendered frame; multiple warm-up frames are needed only when
	# the scene's BoneAttachments enter the tree, handled explicitly in run().
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(out.path_join(name + ".png")) == OK,"save: " + name)
	context["image"] = name + ".png"
	context["draw_calls"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	context["primitives"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	records.append(context)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out); root.size = Vector2i(1280, 720)
	fixture = Node3D.new(); root.add_child(fixture); stage = Node3D.new(); fixture.add_child(stage)
	material = StandardMaterial3D.new(); material.albedo_texture = load("res://art/v2/textures/actor_atlas_albedo.png")
	material.normal_enabled = true; material.normal_texture = load("res://art/v2/textures/actor_atlas_normal.png"); material.normal_scale = .4
	material.roughness_texture = load("res://art/v2/textures/actor_atlas_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = material.roughness_texture; material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE; material.metallic = 1
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var env := WorldEnvironment.new(); fixture.add_child(env); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("25303d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b1c8e0"); env.environment.ambient_light_energy = .45
	var sun := DirectionalLight3D.new(); fixture.add_child(sun); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_energy = 1.3; sun.shadow_enabled = true
	var fill := DirectionalLight3D.new(); fixture.add_child(fill); fill.rotation_degrees = Vector3(-25, 145, 0); fill.light_color = Color("e6bd92"); fill.light_energy = .5
	var floor := MeshInstance3D.new(); fixture.add_child(floor); var plane := PlaneMesh.new(); plane.size = Vector2(40, 40); floor.mesh = plane
	var floor_mat := StandardMaterial3D.new(); floor_mat.albedo_color = Color("49545a"); floor.material_override = floor_mat
	camera = Camera3D.new(); fixture.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.current = true
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://firearm_profiles_candidate.json"))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	for profile in contract.profiles:
		for lod in 3:
			var subjects: Array = []; var guns: Array = []
			for i in ROLES.size():
				var n := load_asset(ROLES[i], lod)
				n.position = Vector3(cos(deg_to_rad(245)), 0, -sin(deg_to_rad(245))) * (i - 1) * 1.8
				subjects.append(n); guns.append(mount(n, profile.weapon_id, lod))
				var ap := player(n); var asset: Dictionary = catalog.assets[i]
				ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				for clip in asset.animations: ap.get_animation(clip.name).loop_mode = Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
			# BoneAttachment registers against the imported skeleton on tree entry.
			# Wait explicitly before the first pose; do not measure its old bind pose.
			await process_frame
			await process_frame
			for action in ["ready", "aim", "fire", "raise", "lower", "reload_contact"]:
				if baseline and action not in ["ready", "aim", "fire"]: continue
				var clip_name: String = ("idle" if action == "ready" else action) if baseline else profile.clips[action]
				var by_role: Array = []
				for i in ROLES.size(): by_role.append([])
				for n in subjects:
					pose(n, clip_name, 0)
					player(n).play(clip_name)
				var duration := player(subjects[0]).get_animation(clip_name).length
				for sample in 25:
					var phase := sample / 24.0
					for n in subjects:
						if sample > 0: player(n).advance(duration / 24.0)
						rig(n).force_update_all_bone_transforms()
						if sample < 24: check(abs(player(n).current_animation_position - duration * phase) < .0001,"manual playback time: " + clip_name)
					# BoneAttachment consumes Skeleton3D's updated palette during
					# the scene frame, even after force_update_all_bone_transforms.
					# Measure the actual mounted gun after that update, not a guessed
					# matrix derived directly from the bone.
					await process_frame
					for i in ROLES.size(): by_role[i].append(sample_contact(subjects[i], guns[i], profile))
					if lod != 1 and action in ["fire", "raise", "lower", "reload_contact"] and sample % 3 == 0:
						look(245, 25, 3.0 if lod == 0 else 9.0, Vector3(0, 1.05, -.15))
						await capture("%s_lod%d_%s_%02d" % [profile.weapon_id, lod, action, sample / 3],
							{"weapon":profile.weapon_id, "roles":ROLES, "lod":lod, "action":action, "clip":clip_name, "phase":phase, "contacts":[by_role[0][-1],by_role[1][-1],by_role[2][-1]]})
					if lod != 1 and action == "ready" and sample == 12:
						look(245, 25, 3.0 if lod == 0 else 9.0, Vector3(0, 1.05, -.15))
						await capture("%s_lod%d_ready" % [profile.weapon_id, lod], {"weapon":profile.weapon_id, "roles":ROLES, "lod":lod, "clip":clip_name})
					if lod == 0 and action == "reload_contact" and sample == 12:
						for i in ROLES.size():
							look(245,18,.70,subjects[i].position+Vector3(.12,1.28,-.30))
							await capture("%s_%s_reload_close" % [profile.weapon_id,ROLES[i]],{"weapon":profile.weapon_id,"role":ROLES[i],"lod":0,"action":action,"phase":phase,"contact":by_role[i][-1]})
				for i in ROLES.size():
					var row := {"weapon":profile.weapon_id,"role":ROLES[i],"lod":lod,"action":action,"clip":clip_name,"samples":25,"max_support_m":0.0,"max_sight_m":0.0,"max_right_grip_m":0.0,"max_reload_contact_m":0.0,"min_muzzle_forward_m":INF}
					for j in 25:
						var c: Dictionary = by_role[i][j]
						row.max_support_m = maxf(row.max_support_m,c.support_m); row.max_sight_m = maxf(row.max_sight_m,c.sight_line_m)
						row.max_right_grip_m = maxf(row.max_right_grip_m,c.right_grip_m)
						row.min_muzzle_forward_m = minf(row.min_muzzle_forward_m,c.muzzle_forward_m)
						if j/24.0 >= .40 and j/24.0 <= .60: row.max_reload_contact_m = maxf(row.max_reload_contact_m,c.reload_contact_m)
					if not baseline:
						check(row.max_support_m < .015 if action != "reload_contact" else row.max_reload_contact_m < .015, "contact: " + str(row))
						if action in ["aim","fire"]: check(row.max_sight_m < .035,"sight: " + str(row))
					check(row.max_right_grip_m < .0001 and row.min_muzzle_forward_m > .10, "right grip/muzzle: " + str(row))
					contacts.append(row)
				if action == "aim" and lod != 1:
					for yaw in [65,155,245,335]:
						look(yaw, 35, 5.5 if lod == 0 else 11, Vector3(0, 1.05, -.15))
						await capture("%s_lod%d_aim_yaw%d" % [profile.weapon_id,lod,yaw],{"weapon":profile.weapon_id,"roles":ROLES,"lod":lod,"action":"aim","clip":clip_name,"yaw":yaw})
					if lod == 0:
						for i in ROLES.size():
							look(245,18,.80,subjects[i].position+Vector3(.10,1.53,-.35))
							await capture("%s_%s_grip_close" % [profile.weapon_id,ROLES[i]],{"weapon":profile.weapon_id,"role":ROLES[i],"lod":0,"action":"aim","clip":clip_name})
			if not baseline:
				# Real AnimationPlayer.advance at 2x must match the authored .25 pose.
				for i in ROLES.size():
					var n: Node3D = subjects[i]; var ap := player(n); var clip_name: String = profile.clips.raise
					pose(n,clip_name,0); ap.speed_scale = 2; ap.play(clip_name); ap.advance(ap.get_animation(clip_name).length * .125)
					rig(n).force_update_all_bone_transforms(); var actual := skeleton_matrices(n)
					var position := ap.current_animation_position
					ap.speed_scale = 1; pose(n,clip_name,.25)
					var error := matrix_error(actual,skeleton_matrices(n))
					check(error < .0001,"2x pose advance: " + ROLES[i] + "/" + profile.weapon_id)
					speed_checks.append({"weapon":profile.weapon_id,"role":ROLES[i],"lod":lod,"speed":2,"normalized_phase":position/ap.get_animation(clip_name).length,"transform_error":error})
				for key in contract.transitions:
					var transition: Dictionary = contract.transitions[key]
					for i in ROLES.size():
						var n: Node3D = subjects[i]
						pose(n,profile.clips[transition.entry.clip_key],0); var before := skeleton_matrices(n)
						pose(n,profile.clips[transition.clip_key],0); var start := skeleton_matrices(n)
						pose(n,profile.clips[transition.clip_key],1); var end := skeleton_matrices(n)
						pose(n,profile.clips[transition.exit.clip_key],0); var after := skeleton_matrices(n)
						var error := maxf(matrix_error(before,start),matrix_error(end,after))
						check(error < .0001,"transition endpoint: %s/%s/lod%d/%s = %f" % [profile.weapon_id,ROLES[i],lod,key,error])
						seams.append({"weapon":profile.weapon_id,"role":ROLES[i],"lod":lod,"transition":key,"max_transform_error":error})
			await clear_stage()
			print("FIREARM_REVIEW_PROGRESS ",profile.weapon_id," lod",lod)
	FileAccess.open(out.path_join("firearm-report.json"),FileAccess.WRITE).store_string(JSON.stringify({"version":Engine.get_version_info(),"baseline":baseline,"contacts":contacts,"transition_endpoints":seams,"speed_checks":speed_checks,"captures":records,"failures":failures,"playback":"AnimationPlayer manual process and advance; 25 actual playback phases, not independent seek-only samples; 2 initial frames for BoneAttachment registration","scope":"isolated assets; source-authored normalized transitions; no combat/replay/event approval"},"\t"))
	print("FIREARM_ENGINE_REVIEW captures=",records.size()," contact_rows=",contacts.size()," seam_rows=",seams.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
