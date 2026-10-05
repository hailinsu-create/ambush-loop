extends Polygon2D
# External diagnostic only; observes DRAW, never mutates the polygon or GL.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and is_inside_tree():
		JavaScriptBridge.get_interface("window").pr15PolygonDraw = str(get_path())
