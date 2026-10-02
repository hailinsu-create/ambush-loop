extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const AudioAssets := preload("res://scripts/sfx/audio_assets.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ASSET_PACK: " + message)


func _run() -> void:
	var physical_root := OS.get_environment("AMBUSH_ASSET_PACK_ROOT")
	_check(not physical_root.is_empty() and DirAccess.get_files_at(physical_root).is_empty(), "probe has no physical project files to conceal missing packed resources")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	_check(doc.assets.size() == 22 and doc.source_commit == "194d9c41aaddbf014f05c70c14d40c09e6d8131b", "R4 manifest is included in the pack with fixed provenance")
	_check(FileAccess.file_exists("res://art/v2/manifest.json"), "yard manifest is included in the pack")
	var audio_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AudioAssets.MANIFEST))
	_check(audio_doc.cues.size() == 45 and audio_doc.asset_source_commit == "86df6d0b4af9f30f3f1e670207cc54b22e2f043b", "45-cue audio manifest retains fixed producer provenance in the pack")
	for row in audio_doc.cues:
		var stream := AudioAssets.stream(str(row.cue))
		_check(stream != null, "actual packed imported audio loads: " + str(row.cue))
		if stream != null:
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(stream.data)
			_check(hash.finish().hex_encode() == str(row.pcm_sha256), "packed PCM retains original producer samples: " + str(row.cue))
			_check(stream.data.size() == int(row.frames) * 2 and stream.mix_rate == 22050 and not stream.stereo, "packed PCM retains rate, channels and frames: " + str(row.cue))
			_check(stream.loop_mode == (AudioStreamWAV.LOOP_FORWARD if row.loop else AudioStreamWAV.LOOP_DISABLED) and (not row.loop or (stream.loop_begin == 0 and stream.loop_end == 352800)), "packed audio retains exact exclusive loop period: " + str(row.cue))
	var actor := Assets.material_for_slot("v2_actor_atlas")
	_check(actor.albedo_texture != null and actor.normal_texture != null and actor.roughness_texture != null, "external shared atlas textures load from the pack")
	for entry in doc.assets:
		for lod in entry.lods.size():
			var model := Assets.instantiate(entry.asset_id, lod)
			_check(model != null and _meshes(model) > 0, "accepted equipment scene loads through the packaged manifest")
			if model != null:
				if entry.category == "character":
					var skeleton := Actor.find_type(model, "Skeleton3D") as Skeleton3D
					var player := Actor.find_type(model, "AnimationPlayer") as AnimationPlayer
					_check(skeleton != null and skeleton.get_bone_count() == 20 and player != null, "packed character retains its actual rig/player")
					if player != null:
						for clip in entry.animations:
							_check(player.has_animation(clip.name) and is_equal_approx(player.get_animation(clip.name).length, clip.duration), "packed character retains every named clip and duration")
				model.free()
	var yard := Assets.instantiate("supply_crate")
	_check(yard != null and _meshes(yard) > 0 and Assets.has_asset("operator_rifle", 2), "pack retains old yard and all registered R4 character LODs")
	if yard != null:
		yard.free()
	Assets.release_materials()
	root.get_node("AudioDirector")._stop_music_hard()
	await process_frame
	print("ASSET_PACK_OK" if failures == 0 else "ASSET_PACK_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	if node == null:
		return 0
	for child in node.get_children():
		count += _meshes(child)
	return count
