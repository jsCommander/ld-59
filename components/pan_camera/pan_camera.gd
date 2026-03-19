extends Camera2D
class_name PanCamera

@export var pan_speed: float = 800.0
@export var edge_scroll_margin: float = 50.0
@export var edge_scroll_speed: float = 600.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("cam_drag"):
		global_position.x -= event.relative.x / zoom.x


func _process(delta: float) -> void:
	var direction: float = Input.get_axis("cam_left", "cam_right")
	if direction != 0.0:
		global_position.x += direction * pan_speed * delta
		return

	if Input.is_action_pressed("cam_drag"):
		return

	var viewport_w: float = get_viewport_rect().size.x
	var mouse_x: float = get_viewport().get_mouse_position().x

	if mouse_x < edge_scroll_margin:
		var factor: float = clampf(1.0 - (mouse_x / edge_scroll_margin), 0.0, 1.0)
		global_position.x -= edge_scroll_speed * factor * delta
	elif mouse_x > viewport_w - edge_scroll_margin:
		var factor: float = clampf(1.0 - ((viewport_w - mouse_x) / edge_scroll_margin), 0.0, 1.0)
		global_position.x += edge_scroll_speed * factor * delta
