class_name TaskCard
extends PanelContainer

var task_data: TaskData

@onready var icon: TextureRect = %Icon

var _is_dragging: bool = false
var _original_parent: Node
var _original_index: int = 0


func setup(data: TaskData) -> void:
	task_data = data


func _ready() -> void:
	if not task_data:
		return
	icon.texture = task_data.texture
	SB.task_drop_consumed.connect(_on_drop_consumed)


func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_viewport().get_mouse_position() - size / 2


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_start_drag()


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag()


func _start_drag() -> void:
	_is_dragging = true
	_original_parent = get_parent()
	_original_index = get_index()
	var saved_pos: Vector2 = global_position
	reparent(get_tree().get_first_node_in_group("drag_layer"))
	global_position = saved_pos
	move_to_front()


func _end_drag() -> void:
	_is_dragging = false
	var drop_pos: Vector2 = get_viewport().get_mouse_position()
	SB.task_drop_requested.emit(task_data, drop_pos)
	await get_tree().process_frame
	if is_inside_tree() and not is_queued_for_deletion():
		reparent(_original_parent)
		_original_parent.move_child(self, _original_index)


func _on_drop_consumed(consumed_task: TaskData) -> void:
	if consumed_task == task_data and task_data.task_type == Constants.TaskType.BUG:
		queue_free()
