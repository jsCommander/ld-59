class_name UiPopupManager
extends Control

var _current_popup: Control
var _anchor_position: Vector2


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _current_popup:
		return
	close_popup()


func _process(_delta: float) -> void:
	if not _current_popup:
		return
	_update_popup_position()


func show_popup(popup: Control, anchor_position: Vector2) -> void:
	close_popup()
	_anchor_position = anchor_position
	_current_popup = popup
	add_child(popup)
	popup.show()

	await get_tree().process_frame
	_update_popup_position()


func close_popup() -> void:
	if _current_popup:
		_current_popup.queue_free()
		_current_popup = null


func _update_popup_position() -> void:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var screen_pos: Vector2 = canvas_transform * _anchor_position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var popup_size: Vector2 = _current_popup.size

	var pos: Vector2 = Vector2(
		screen_pos.x - popup_size.x / 2.0,
		screen_pos.y - popup_size.y
	)

	if pos.y < 0.0:
		pos.y = screen_pos.y

	if pos.x + popup_size.x > viewport_size.x:
		pos.x = viewport_size.x - popup_size.x

	if pos.x < 0.0:
		pos.x = 0.0

	_current_popup.position = pos
