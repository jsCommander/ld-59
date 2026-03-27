class_name TaskCard
extends PanelContainer

signal expired(task_data: TaskData)

var task_data: TaskData

@onready var title_label: Label = %TitleLabel
@onready var complexity_label: Label = %ComplexityLabel
@onready var deadline_bar: ProgressBar = %DeadlineBar

var _elapsed: float = 0.0
var _is_dragging: bool = false
var _original_parent: Node
var _original_index: int = 0


func setup(data: TaskData) -> void:
	task_data = data


func _ready() -> void:
	if not task_data:
		return
	var type_str: String = "BUG" if task_data.task_type == TaskData.TaskType.BUG else "TASK"
	title_label.text = "[%s] %s" % [type_str, task_data.task_name]
	complexity_label.text = "x%d" % task_data.complexity
	deadline_bar.max_value = task_data.deadline
	deadline_bar.value = task_data.deadline
	if task_data.task_type == TaskData.TaskType.BUG:
		add_theme_color_override("font_color", Color.RED)
	SB.task_drop_consumed.connect(_on_drop_consumed)


func _process(delta: float) -> void:
	_elapsed += delta
	deadline_bar.value = task_data.deadline - _elapsed

	if _elapsed >= task_data.deadline:
		SB.task_expired.emit(task_data)
		expired.emit(task_data)
		queue_free()
		return

	if _is_dragging:
		global_position = get_viewport().get_mouse_position() - size / 2


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_start_drag()
	elif _is_dragging:
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
	if consumed_task == task_data:
		queue_free()
