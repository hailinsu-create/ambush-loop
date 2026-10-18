extends SceneTree

## W10 (T1 web audio export fix): the six extra runtime cues must survive the
## Web export filter and ship in the pck.
##
## The Web preset excludes `art/*`; G2SfxPlayer now points at byte-copies under
## assets/audio_v2/. This test parses export_presets.cfg, reimplements Godot's
## comma-separated wildcard filter, and asserts every referenced audio path is
## not excluded, while positive controls prove the matcher and the art/* rule
## are still in force.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SfxPlayerScript := preload("res://view/g2_sfx_player.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")

const WEB_PRESET := "Web"
const EXTRA_DIR_PREFIX := "res://assets/audio_v2/"
const EXPECTED_CUES := ["hit", "body_drop", "alert_shout", "kill", "tension", "ambient_yard"]
const AUDIO_LITERAL_RE := "res://[\\w./-]*\\.(wav|ogg|mp3)"

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	var cf := ConfigFile.new()
	var load_err := cf.load("res://export_presets.cfg")
	_assert(load_err == OK, "export_presets.cfg loads err=%s" % load_err)

	var web_section := _find_web_section(cf)
	_assert(not web_section.is_empty(), "Web preset section found sections=%s" % str(cf.get_sections()))

	var export_filter := ""
	var exclude_raw := ""
	if not web_section.is_empty():
		export_filter = str(cf.get_value(web_section, "export_filter", ""))
		exclude_raw = str(cf.get_value(web_section, "exclude_filter", ""))
	_assert(export_filter == "all_resources", "Web export_filter all_resources got=%s" % export_filter)

	var filters := _split_filters(exclude_raw)
	_assert(_has_filter(filters, "art/*"), "Web exclude_filter keeps art/* rule got=%s" % exclude_raw)

	var extra_cues: Array = []
	var extra_paths: Array = []
	for pair in SfxPlayerScript.EXTRA_CUES:
		extra_cues.append(str(pair[0]))
		extra_paths.append(str(pair[1]))
	_assert(
		extra_cues.size() == EXPECTED_CUES.size() and _same_set(extra_cues, EXPECTED_CUES),
		"EXTRA_CUES six expected cues got=%s" % str(extra_cues)
	)

	var bad_prefix: Array = []
	for p in extra_paths:
		if not p.begins_with(EXTRA_DIR_PREFIX):
			bad_prefix.append(p)
	_assert(bad_prefix.is_empty(), "extra paths under res://assets/audio_v2/ bad=%s" % str(bad_prefix))

	var extra_excluded: Array = []
	for p in extra_paths:
		if _is_excluded(p, filters):
			extra_excluded.append(p)
	_assert(extra_excluded.is_empty(), "extra paths not excluded bad=%s" % str(extra_excluded))

	var extra_unloaded: Array = []
	for p in extra_paths:
		if not ResourceLoader.exists(p) or (load(p) as AudioStream) == null:
			extra_unloaded.append(p)
	_assert(extra_unloaded.is_empty(), "extra paths exist+load as AudioStream bad=%s" % str(extra_unloaded))

	var ref_excluded: Array = []
	var ref_missing: Array = []
	for cue in G2AssetsScript.referenced_sfx_cues():
		var p := G2AssetsScript.SFX_BASE + str(cue) + ".wav"
		if _is_excluded(p, filters):
			ref_excluded.append(p)
		if (load(p) as AudioStream) == null:
			ref_missing.append(p)
	_assert(ref_excluded.is_empty(), "referenced_sfx_cues not excluded bad=%s" % str(ref_excluded))
	_assert(ref_missing.is_empty(), "referenced_sfx_cues load as AudioStream bad=%s" % str(ref_missing))

	var lit_excluded: Array = []
	var lit_found: Dictionary = {}
	var lit_file_count := 0
	var re := RegEx.new()
	re.compile(AUDIO_LITERAL_RE)
	for f in _collect_source_files():
		var text := FileAccess.get_file_as_string(f)
		var matches := re.search_all(text)
		if not matches.is_empty():
			lit_file_count += 1
		for m in matches:
			var lit := m.get_string(0)
			lit_found[lit] = true
			if _is_excluded(lit, filters):
				lit_excluded.append("%s -> %s" % [f, lit])
	var lit_missing: Array = []
	for p in extra_paths:
		if not lit_found.has(p):
			lit_missing.append(p)
	_assert(
		lit_found.size() >= 6 and lit_missing.is_empty(),
		"source audio literals cover EXTRA_CUES files=%d literals=%d missing=%s" % [lit_file_count, lit_found.size(), str(lit_missing)]
	)
	_assert(
		lit_excluded.is_empty(),
		"source audio literals not excluded files=%d literals=%d bad=%s" % [lit_file_count, lit_found.size(), str(lit_excluded)]
	)

	var pos_glb := _is_excluded("res://art/environment_v2/models/env_ammo_can_lod0.glb", filters)
	var pos_wav := _is_excluded("res://art/audio_v2/hit.wav", filters)
	_assert(pos_glb and pos_wav, "positive controls excluded glb=%s art_audio=%s" % [pos_glb, pos_wav])

	var mismatches: Array = []
	for p in extra_paths:
		var src: String = "res://art/audio_v2/" + str(p.get_file())
		var a := FileAccess.get_file_as_bytes(p)
		var b := FileAccess.get_file_as_bytes(src)
		if a.is_empty() or b.is_empty() or a != b:
			mismatches.append(p)
	_assert(mismatches.is_empty(), "assets/audio_v2 byte-identical to art/audio_v2 bad=%s" % str(mismatches))

	var sfx = SfxPlayerScript.new()
	sfx.configure(null)
	var extras_ok: bool = sfx._extra.size() == EXPECTED_CUES.size()
	for cue in EXPECTED_CUES:
		if sfx._extra.get(cue, null) == null:
			extras_ok = false
	_assert(extras_ok, "G2SfxPlayer.configure(null) loads 6 non-null streams got=%d" % sfx._extra.size())
	sfx.free()

	print("W10_AUDIO_EXPORT_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _find_web_section(cf: ConfigFile) -> String:
	for section in cf.get_sections():
		if str(cf.get_value(section, "name", "")) == WEB_PRESET:
			return section
	return ""


func _split_filters(raw: String) -> PackedStringArray:
	var out := PackedStringArray()
	for part in raw.split(","):
		var f := part.strip_edges()
		if not f.is_empty():
			out.append(f)
	return out


func _has_filter(filters: PackedStringArray, want: String) -> bool:
	for f in filters:
		if f == want:
			return true
	return false


func _is_excluded(path: String, filters: PackedStringArray) -> bool:
	## Godot's EditorExportPlatform matches path.matchn(filter) and also tries the
	## full "res://"+path form; `*` spans `/`, so art/* covers nested art files.
	var rel := path.replace("\\", "/")
	if rel.begins_with("res://"):
		rel = rel.substr("res://".length())
	for f in filters:
		if rel.matchn(f) or ("res://" + rel).matchn(f):
			return true
	return false


func _same_set(a: Array, b: Array) -> bool:
	var sa := a.duplicate()
	var sb := b.duplicate()
	sa.sort()
	sb.sort()
	return sa == sb


func _collect_source_files() -> Array:
	var out: Array = []
	for dir in ["res://view", "res://ui", "res://scripts", "res://sim", "res://scenes"]:
		_walk(dir, out)
	return out


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if d.current_is_dir():
			if not name.begins_with("."):
				_walk(dir + "/" + name, out)
		else:
			var base := name.get_file()
			var is_test := base.ends_with("_test.gd")
			if (name.ends_with(".gd") or name.ends_with(".tscn")) and not is_test:
				out.append(dir + "/" + name)
		name = d.get_next()
	d.list_dir_end()
