extends RefCounted
class_name SimWeapons

## Load weapons.csv into id → Dictionary.


static func load_csv(path: String = "res://data/weapons.csv") -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SimWeapons: cannot open %s" % path)
		return out
	var header := f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.is_empty() or row[0].is_empty():
			continue
		if row.size() < header.size():
			continue
		var rec := {}
		for i in header.size():
			rec[header[i]] = row[i]
		var id: String = str(rec.get("id", ""))
		if id.is_empty():
			continue
		var bands := str(rec.get("射程带_近中远发数", "1/1/1")).split("/")
		var sn := int(bands[0]) if bands.size() > 0 else 1
		var sm := int(bands[1]) if bands.size() > 1 else 1
		var sf := int(bands[2]) if bands.size() > 2 else 1
		out[id] = {
			"id": id,
			"name": str(rec.get("名称", id)),
			"sector_deg": float(rec.get("扇形角_deg", 0)),
			"shots_near": sn,
			"shots_mid": sm,
			"shots_far": sf,
			"rpm": float(rec.get("射速_rpm", 0)),
			"mag": int(rec.get("弹匣", 0)),
			"reload_s": float(rec.get("换弹_s", 0)),
			"suppress": int(rec.get("压制", 0)),
			"equipable": str(rec.get("可装备", "")) == "是",
			"max_range": SimGeom.weapon_max_range(sn, sm, sf),
		}
	return out


static func shots_needed(w: Dictionary, dist: float) -> int:
	var band := SimGeom.range_band(dist)
	match band:
		"near":
			return int(w.get("shots_near", 99))
		"mid":
			return int(w.get("shots_mid", 99))
		_:
			return int(w.get("shots_far", 99))
