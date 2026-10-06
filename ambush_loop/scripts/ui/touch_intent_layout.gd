extends RefCounted
## Pure screen-space placement for the touch confirmation affordance.

const TARGET_GAP := 18.0
const OBSTACLE_GAP := 8.0


static func choose_position(
	target_screen: Vector2,
	viewport_size: Vector2,
	panel_size: Vector2,
	safe_insets: Vector4,
	obstacles: Array = []
) -> Dictionary:
	var min_x := maxf(0.0, safe_insets.x)
	var min_y := maxf(0.0, safe_insets.y)
	var max_x := maxf(min_x, viewport_size.x - maxf(0.0, safe_insets.z) - panel_size.x)
	var max_y := maxf(min_y, viewport_size.y - maxf(0.0, safe_insets.w) - panel_size.y)
	var has_target := target_screen.is_finite() and Rect2(Vector2.ZERO, viewport_size).grow(24.0).has_point(target_screen)
	var candidates: Array[Vector2] = []
	if has_target:
		candidates = [
			target_screen + Vector2(TARGET_GAP, -panel_size.y - TARGET_GAP),
			target_screen + Vector2(-panel_size.x - TARGET_GAP, -panel_size.y - TARGET_GAP),
			target_screen + Vector2(TARGET_GAP, TARGET_GAP),
			target_screen + Vector2(-panel_size.x - TARGET_GAP, TARGET_GAP),
			target_screen + Vector2(TARGET_GAP, -panel_size.y * 0.5),
			target_screen + Vector2(-panel_size.x - TARGET_GAP, -panel_size.y * 0.5),
		]
	var target_candidate_count := candidates.size()
	# Keep a predictable non-target fallback above the resident command rail.
	candidates.append(Vector2(max_x, max_y))
	candidates.append(Vector2(min_x, max_y))
	candidates.append(Vector2(max_x, min_y))
	candidates.append(Vector2(min_x, min_y))

	var best_position := Vector2(min_x, min_y)
	var best_score := INF
	var best_overlaps := true
	var best_is_target := false
	for index in candidates.size():
		var raw := candidates[index]
		var position := Vector2(clampf(raw.x, min_x, max_x), clampf(raw.y, min_y, max_y))
		var rect := Rect2(position, panel_size)
		var overlap_count := _overlap_count(rect, obstacles)
		var is_target_candidate := index < target_candidate_count
		var score := float(overlap_count) * 1000000.0 + float(index) * 0.25
		if is_target_candidate:
			var nearest := Vector2(
				clampf(target_screen.x, rect.position.x, rect.end.x),
				clampf(target_screen.y, rect.position.y, rect.end.y)
			)
			score += nearest.distance_to(target_screen)
		else:
			score += 10000.0
		if score < best_score:
			best_position = position
			best_score = score
			best_overlaps = overlap_count > 0
			best_is_target = is_target_candidate

	return {
		"position": best_position,
		"mode": "target_nearby" if best_is_target else "safe_fallback",
		"overlaps_obstacle": best_overlaps,
		"safe_rect": Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x + panel_size.x, max_y - min_y + panel_size.y)),
	}


static func _overlap_count(panel_rect: Rect2, obstacles: Array) -> int:
	var expanded := panel_rect.grow(OBSTACLE_GAP)
	var count := 0
	for obstacle in obstacles:
		if obstacle is Rect2 and obstacle.size.x > 0.0 and obstacle.size.y > 0.0 and expanded.intersects(obstacle):
			count += 1
	return count
