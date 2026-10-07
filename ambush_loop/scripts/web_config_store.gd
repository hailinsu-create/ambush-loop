extends RefCounted

## Small, atomic browser checkpoint. ConfigFile/IDBFS remains the native format.
## Public Web Storage only; no GodotFS/FS hooks, timers, or replay data.
const KEY := "ambush-loop.config.v1"
const NAMES := ["ambush_loop_settings.cfg", "ambush_loop.cfg"]
const MAX_BYTES := 65536


static func decode(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false, "error": "oversize"}
	var doc = JSON.parse_string(text)
	if not doc is Dictionary or doc.get("schema") != 1 or not doc.get("files") is Dictionary:
		return {"ok": false, "error": "schema"}
	var files: Dictionary = doc.files
	if files.size() != NAMES.size():
		return {"ok": false, "error": "files"}
	# Validate every entry before touching either live ConfigFile.
	for name in NAMES:
		if not files.has(name):
			return {"ok": false, "error": "files"}
		var text_or_null = files[name]
		if text_or_null == null:
			continue
		if not text_or_null is String or ConfigFile.new().parse(text_or_null) != OK:
			return {"ok": false, "error": "config"}
	return {"ok": true, "files": files}


static func read_browser() -> Dictionary:
	var script := """(function(){try{return JSON.stringify({ok:true,text:window.localStorage.getItem(%s)});}catch(e){return JSON.stringify({ok:false,error:String(e.name)});}})()""" % JSON.stringify(KEY)
	var value = JavaScriptBridge.eval(script, true)
	var result = JSON.parse_string(str(value))
	return result if result is Dictionary else {"ok": false, "error": "bridge"}


static func write_browser(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false, "error": "oversize"}
	# setItem is synchronous and atomic. Read back this exact checkpoint before
	# acknowledging it; quota/security exceptions retain the preceding checkpoint.
	var script := """(function(){try{const key=%s,text=%s;window.localStorage.setItem(key,text);return JSON.stringify({ok:window.localStorage.getItem(key)===text});}catch(e){return JSON.stringify({ok:false,error:String(e.name)});}})()""" % [JSON.stringify(KEY), JSON.stringify(text)]
	var value = JavaScriptBridge.eval(script, true)
	var result = JSON.parse_string(str(value))
	return result if result is Dictionary else {"ok": false, "error": "bridge"}


static func snapshot() -> String:
	var files := {}
	for name in NAMES:
		var path: String = "user://" + str(name)
		files[name] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
	return JSON.stringify({"schema": 1, "files": files})


static func restore(files: Dictionary) -> Error:
	for name in NAMES:
		var path: String = "user://" + str(name)
		if files[name] == null:
			if FileAccess.file_exists(path):
				var remove_error := DirAccess.remove_absolute(path)
				if remove_error != OK:
					return remove_error
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file == null:
				return FileAccess.get_open_error()
			file.store_string(files[name])
			var write_error := file.get_error()
			file.close()
			if write_error != OK:
				return write_error
	return OK
