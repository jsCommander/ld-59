extends Camera2D
class_name CameraMan

# Smoothing controls camera movement speed:
# - Higher values (5.0+) = faster, more responsive, may be jerky
# - Lower values (1.0-3.0) = smoother, may lag behind fast targets
@export var smoothing: float = 2.5
@export var follow_target_offset: Vector2 = Vector2.ZERO
@export var arrive_point_min_distance: float = 5.0

enum CameraMode {
	IDLE,
	FOLLOW_TARGET,
	ARRIVE_TO_POINT
}

var _current_mode: CameraMode = CameraMode.IDLE
var _target_node: Node2D
var _arrive_point: Vector2 = Vector2.ZERO

var _shake_intensity: float = 10.0
var _shake_duration: float = 0.5
var _shake_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

var _zoom_start: Vector2 = Vector2.ONE
var _zoom_target: Vector2 = Vector2.ONE
var _zoom_duration: float = 1.0
var _zoom_timer: float = 0.0

func _physics_process(delta):
	_handle_effects(delta)
	_handle_mode(delta)

func _handle_effects(delta):
	_handle_shake_effect(delta)
	_handle_zoom_effect(delta)

func _handle_shake_effect(delta):
	if _shake_timer > 0:
		_shake_timer -= delta
		var shake_strength = _shake_intensity * (_shake_timer / _shake_duration)
		_shake_offset = Vector2(
			[shake_strength, -shake_strength].pick_random(),
			[shake_strength, -shake_strength].pick_random(),
		)
	else:
		_shake_offset = Vector2.ZERO

func _handle_zoom_effect(delta):
	if _zoom_timer > 0:
		_zoom_timer -= delta
		var progress = 1.0 - (_zoom_timer / _zoom_duration)
		zoom = _zoom_start.lerp(_zoom_target, progress)
	else:
		zoom = _zoom_target

func _handle_mode(delta):
	match _current_mode:
		CameraMode.FOLLOW_TARGET:
			_handle_follow_target(delta)
		CameraMode.ARRIVE_TO_POINT:
			_handle_arrive_to_point(delta)
		CameraMode.IDLE:
			return

func _handle_follow_target(delta):
	if !_target_node:
		_current_mode = CameraMode.IDLE
		return
	
	var target_pos = _target_node.global_position + follow_target_offset + _shake_offset
	global_position = global_position.lerp(target_pos, smoothing * delta)

func _handle_arrive_to_point(delta):
	var target_pos = _arrive_point + _shake_offset
	position = position.lerp(target_pos, smoothing * delta)
	
	# Stop when close enough to the point
	if position.distance_to(_arrive_point) < arrive_point_min_distance:
		_current_mode = CameraMode.IDLE

func follow_target(target: Node2D):
	Log.log_debug(self.name, "Following target: " + str(target.name) + " with offset: " + str(follow_target_offset))
	_target_node = target
	_current_mode = CameraMode.FOLLOW_TARGET

func arrive_to_point(point: Vector2):
	Log.log_debug(self.name, "Arriving to point: " + str(point))
	_arrive_point = point
	_current_mode = CameraMode.ARRIVE_TO_POINT

func set_idle():
	Log.log_debug(self.name, "Camera set to idle")
	_current_mode = CameraMode.IDLE

func shake(intensity: float = -1, duration: float = -1):
	var final_intensity = intensity if intensity > 0 else _shake_intensity
	var final_duration = duration if duration > 0 else _shake_duration
	
	Log.log_debug(self.name, "Shaking with intensity: " + str(final_intensity) + " for: " + str(final_duration) + "s")
	_shake_timer = final_duration

func zoom_to(target_zoom: float, duration: float = 1.0):
	Log.log_debug(self.name, "Zooming to: " + str(target_zoom) + " over: " + str(duration) + "s")
	_zoom_start = zoom
	_zoom_target = Vector2(target_zoom, target_zoom)
	_zoom_duration = duration
	_zoom_timer = duration
