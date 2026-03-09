extends RefCounted

class_name Animations


static func pulse(target: CanvasItem, strength: float = 1.05, duration: float = 1.0, loop: bool = true) -> Tween:
	var tween = target.create_tween()
	var current_scale = target.scale
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "scale", current_scale * strength, duration / 2).from_current()
	tween.tween_property(target, "scale", current_scale, duration / 2)
	
	return tween

static func shake(target: CanvasItem, intensity: float = 3.0, duration: float = 1.0, loop: bool = false) -> Tween:
	var initial_pos = target.position
	var tween = target.create_tween()
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in range(4):
		tween.tween_property(target, "position",
			initial_pos + Vector2(randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)),
			duration / 4
		)
	tween.tween_property(target, "position", initial_pos, duration / 4)
	
	return tween

static func fade_in(target: CanvasItem, duration: float = 1.0) -> Tween:
	target.modulate.a = 0.0
	var tween = target.create_tween()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "modulate:a", 1.0, duration)
	
	return tween

static func fade_out(target: CanvasItem, duration: float = 1.0) -> Tween:
	var tween = target.create_tween()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "modulate:a", 0.0, duration)

	return tween

static func bounce(target: CanvasItem, jump_height: float = -10.0, duration: float = 1.0, loop: bool = true) -> Tween:
	var tween = target.create_tween()
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "position:y", target.position.y + jump_height, duration / 2)
	tween.tween_property(target, "position:y", target.position.y, duration / 2)
	
	return tween

static func bounce_up(target: CanvasItem, jump_height: float = 10.0, duration: float = 1.0) -> Tween:
	var tween = target.create_tween()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "position:y", target.position.y - jump_height, duration / 2)
	tween.tween_property(target, "position:y", target.position.y, duration / 2)
	
	return tween

static func walk(target: Node2D, sway_angle: float = 0.1, sway_duration: float = 0.3, loop: bool = true) -> Tween:
	var tween = target.create_tween()
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Left-right rotation swaying like walking
	tween.tween_property(target, "rotation", target.rotation - sway_angle, sway_duration / 2)
	tween.tween_property(target, "rotation", target.rotation + sway_angle, sway_duration / 2)
	tween.tween_property(target, "rotation", target.rotation, sway_duration / 2)
	
	return tween

static func blink(target: CanvasItem, target_modulate: Color, duration: float = 0.5, loop: bool = false) -> Tween:
	var initial_modulate = target.modulate
	var tween = target.create_tween()
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target, "modulate", target_modulate, duration / 2)
	tween.tween_property(target, "modulate", initial_modulate, duration / 2)
	
	return tween

static func rotate(target: CanvasItem, rotation_time: float, clockwise: bool = true, loop: bool = true) -> Tween:
	var tween = target.create_tween()
	
	if loop:
		tween.set_loops()
	
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_OUT_IN)
	
	var initial_rotation = target.rotation
	
	var angular_velocity_rad = 2 * PI / rotation_time
	if not clockwise:
		angular_velocity_rad = - angular_velocity_rad
	
	var update_rotation = func(progress: float):
		target.rotation = initial_rotation + angular_velocity_rad * progress
	
	tween.tween_method(update_rotation, 0.0, rotation_time, rotation_time)
	
	return tween

static func spawn_arc(target: CanvasItem, end_pos: Vector2, arc_height: float = 50.0, duration: float = 1.0) -> Tween:
	var start_pos = target.global_position
	
	var tween = target.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Create arc animation using tween_method
	var arc_animation = func(progress: float):
		var current_pos = start_pos.lerp(end_pos, progress)
		# Add arc height - higher in the middle, lower at start/end
		var arc_offset = sin(progress * PI) * arc_height
		current_pos.y -= arc_offset
		target.global_position = current_pos
	
	tween.tween_method(arc_animation, 0.0, 1.0, duration)
	
	return tween
