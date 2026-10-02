extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func find_type(n:Node,kind:String) -> Node:
 if n.is_class(kind):return n
 for child in n.get_children():
  var found:=find_type(child,kind)
  if found!=null:return found
 return null
func run() -> void:
 var n=load("res://art/v2/models/operator_rifle_lod0.glb").instantiate()
 root.add_child(n)
 var sk=find_type(n,"Skeleton3D")
 var ap=find_type(n,"AnimationPlayer")
 ap.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 var samples=[]
 for clip in ["death_prone","corpse_prone"]:
  ap.play(clip);ap.seek(ap.get_animation(clip).length if clip=="death_prone" else 0,true);ap.pause();sk.force_update_all_bone_transforms()
  var bones=[]
  for i in sk.get_bone_count():bones.append(sk.get_bone_global_pose(i))
  samples.append(bones)
 var translation=0.0
 var axis=0.0
 for i in sk.get_bone_count():
  translation=max(translation,samples[0][i].origin.distance_to(samples[1][i].origin))
  for j in 3:axis=max(axis,samples[0][i].basis[j].distance_to(samples[1][i].basis[j]))
 print("DEATH_EXIT_ERROR translation_m=",translation," basis_axis_difference=",axis)
 quit()
