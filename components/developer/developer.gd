@tool
class_name Developer
extends Node2D

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var sprite: Sprite2D = %Sprite
@onready var produce_trait: ProduceTrait = %ProduceTrait
@onready var name_label: Label = %NameLabel

var _current_task: TaskData = null


func _ready() -> void:
	add_to_group("developer")
	_apply_data()
	if Engine.is_editor_hint():
		return
	produce_trait.stopped.connect(_on_work_finished)
	SB.task_drop_requested.connect(_on_task_drop_requested)


func _apply_data() -> void:
	if not data:
		return
	if is_instance_valid(name_label):
		name_label.text = data.dev_name


func is_idle() -> bool:
	return _current_task == null


func assign_task(task_data: TaskData) -> void:
	if not is_idle():
		return
	_current_task = task_data
	var work_time: float = float(task_data.complexity) * 8.0 / data.speed
	produce_trait.setup_simple(work_time)
	produce_trait.start()
	Log.log_info(name, "Assigned: %s (%.1fs)" % [task_data.task_name, work_time])


func _on_work_finished() -> void:
	if not _current_task:
		return
	SB.task_completed.emit(self, _current_task)
	Log.log_info(name, "Completed: %s" % _current_task.task_name)
	_current_task = null


func _on_task_drop_requested(task_data: TaskData, screen_pos: Vector2) -> void:
	if not is_idle():
		return
	var my_screen_pos: Vector2 = get_global_transform_with_canvas().origin
	if my_screen_pos.distance_to(screen_pos) < 120.0:
		assign_task(task_data)
		SB.task_drop_consumed.emit(task_data)
