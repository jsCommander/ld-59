# Utils library, contains some useful functions
# Should not contain any game logic or dependencies
class_name Utils extends RefCounted

static func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.end.x),
		randf_range(rect.position.y, rect.end.y)
	)

static func get_random_direction() -> Vector2:
	var direction := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	return direction

static func get_enum_key_name(_enum, key) -> String:
	return _enum.find_key(key)

static func get_timestamp() -> String:
	return Time.get_datetime_string_from_system(true)

static func find_closest_target_in_group(group: String, node: Node2D) -> Node2D:
	var targets = node.get_tree().get_nodes_in_group(group)
	return find_closest_target(targets, node)

static func find_closest_target(targets: Array, node: Node2D) -> Node2D:
	var closest_target: Node2D = null
	var closest_distance = INF
	
	for target in targets:
		var distance = node.global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	return closest_target

static func get_follow_velocity(node: Node2D, target: Node2D, speed: float, target_offset: float = 5.0) -> Vector2:
	var direction = node.global_position.direction_to(target.global_position)
	var distance = node.global_position.distance_to(target.global_position)

	if distance < target_offset:
		return Vector2.ZERO

	return direction.normalized() * speed

static func deactivate_collider(collider: CollisionShape2D, duration: float) -> void:
	if duration == 0:
		return

	collider.set_deferred("disabled", true)
	await collider.get_tree().create_timer(duration).timeout
	
	if is_instance_valid(collider):
		collider.set_deferred("disabled", false)

static func get_move_input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
