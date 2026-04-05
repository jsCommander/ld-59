class_name TaskCard
extends PanelContainer

var task_data: TaskData
var draggable: bool = true

@onready var icon: TextureRect = %Icon

var _is_dragging: bool = false
var _original_index: int = 0


func setup(data: TaskData) -> void:
	task_data = data


func _ready() -> void:
	if not task_data:
		return
	icon.texture = task_data.texture


func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_viewport().get_mouse_position() - size / 2


func _gui_input(event: InputEvent) -> void:
	if not draggable:
		return
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
	_original_index = PD.task_queue.find(task_data)
	z_index = 10


func _end_drag() -> void:
	_is_dragging = false
	z_index = 0
	var container: HBoxContainer = get_parent()
	if not container:
		return
	var drop_x: float = get_viewport().get_mouse_position().x
	var new_index: int = _find_drop_index(container, drop_x)
	if new_index != _original_index and _original_index >= 0:
		PD.task_queue.erase(task_data)
		new_index = mini(new_index, PD.task_queue.size())
		PD.task_queue.insert(new_index, task_data)
		SB.task_queue_changed.emit(PD.task_queue)


func _find_drop_index(container: HBoxContainer, drop_x: float) -> int:
	for i: int in container.get_child_count():
		var child: Control = container.get_child(i)
		if drop_x < child.global_position.x + child.size.x / 2:
			return i
	return container.get_child_count()
