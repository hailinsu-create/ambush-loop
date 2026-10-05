extends Polygon2D
# External prototype for the official 4.7.2 WebGL index-update defect.
# Alternating an equivalent white sampler changes the native UV layout, forcing
# the safe mesh rebuild path. Restore texture before returning to game logic.
static var _white_sampler: ImageTexture
var _next_textured := true
var _restore_texture := false
var compat_draws := 0

func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAW or not OS.has_feature("web"):
		return
	if texture != null or material != null or use_parent_material or polygon.size() < 3:
		return
	if not uv.is_empty() or not vertex_colors.is_empty() or invert_enabled or internal_vertex_count != 0 or not polygons.is_empty() or not skeleton.is_empty() or get_bone_count() != 0:
		return
	if _white_sampler == null:
		var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		pixel.fill(Color.WHITE)
		_white_sampler = ImageTexture.create_from_image(pixel)
	_restore_texture = true
	if _next_textured:
		texture = _white_sampler
	_next_textured = not _next_textured
	compat_draws += 1

func _draw() -> void:
	if _restore_texture:
		texture = null
		_restore_texture = false
