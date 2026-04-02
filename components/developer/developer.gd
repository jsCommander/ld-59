@tool
class_name Developer
extends Node2D

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var desk_sprite: Sprite2D = %DeskSprite
@onready var dev_sprite: Sprite2D = %DevSprite
@onready var produce_trait: ProduceTrait = %ProduceTrait
@onready var progress_bar: Control = %ProduceProgressBar
@onready var task_icons: HBoxContainer = %TaskIcons
@onready var damage_number: DamageNumber = $DamageNumber

var current_tasks: Array[TaskData] = []
var _sprint_active: bool = false


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	produce_trait.stopped.connect(_on_work_finished)
	SB.task_drop_requested.connect(_on_task_drop_requested)
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)


func _apply_data() -> void:
	if not is_instance_valid(dev_sprite):
		return

	if data:
		dev_sprite.texture = data.texture
		dev_sprite.visible = true
		if is_instance_valid(progress_bar):
			progress_bar.visible = true
		if not Engine.is_editor_hint():
			add_to_group("developer")
			if is_in_group("desk"):
				remove_from_group("desk")
	else:
		dev_sprite.visible = false
		if is_instance_valid(progress_bar):
			progress_bar.visible = false
		if not Engine.is_editor_hint():
			add_to_group("desk")
			if is_in_group("developer"):
				remove_from_group("developer")


func is_idle() -> bool:
	return current_tasks.is_empty()


func has_tasks() -> bool:
	return not current_tasks.is_empty()


func get_speed_for_task(task: TaskData) -> int:
	match task.task_type:
		Constants.TaskType.FEATURE: return data.feature_speed
		Constants.TaskType.BUG: return data.bug_speed
		Constants.TaskType.REFACTOR: return data.refactor_speed
	return data.feature_speed


func get_task_cost(task: TaskData) -> float:
	return 1.0 - float(get_speed_for_task(task)) / 100.0


func get_current_capacity() -> float:
	var total: float = 0.0
	for task: TaskData in current_tasks:
		total += get_task_cost(task)
	return total


func can_accept_task(task: TaskData) -> bool:
	if not data:
		return false
	var can_accept: bool = get_current_capacity() + get_task_cost(task) <= data.max_capacity
	if not can_accept:
		Log.log_debug(name, "Rejected %s (cost=%.2f, capacity=%.2f/%.1f)" % [
			Constants.TaskType.keys()[task.task_type],
			get_task_cost(task),
			get_current_capacity(),
			data.max_capacity,
		])
	return can_accept


func assign_task(task_data: TaskData) -> void:
	if not can_accept_task(task_data):
		return
	current_tasks.append(task_data)
	_add_task_icon(task_data)
	Log.log_info(name, "Assigned %s (cost=%.2f, capacity=%.2f/%.1f)" % [
		Constants.TaskType.keys()[task_data.task_type],
		get_task_cost(task_data),
		get_current_capacity(),
		data.max_capacity,
	])


func _start_current_task() -> void:
	if current_tasks.is_empty():
		return
	var task: TaskData = current_tasks[0]
	var speed: int = get_speed_for_task(task)
	var work_time: float = 10.0 / maxf(float(speed), 1.0)
	produce_trait.setup_simple(work_time)
	produce_trait.start()


func _on_sprint_started() -> void:
	_sprint_active = true
	_start_current_task()


func _on_sprint_ended() -> void:
	_sprint_active = false
	produce_trait.cancel()


func _on_work_finished() -> void:
	if current_tasks.is_empty():
		return
	var finished_task: TaskData = current_tasks.pop_front()
	_remove_first_task_icon()
	_show_completion_numbers(finished_task)
	SB.task_finished.emit(self, finished_task)
	Log.log_info(name, "Completed %s" % Constants.TaskType.keys()[finished_task.task_type])
	if _sprint_active:
		_start_current_task()


func _show_completion_numbers(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			var earned: int = Constants.BASE
			damage_number.spawn("+$%d" % earned, Vector2.UP)

		Constants.TaskType.BUG:
			damage_number.spawn("Fixed!", Vector2.UP)

		Constants.TaskType.REFACTOR:
			var reduced: float = float(data.refactor_speed) / 100.0
			damage_number.spawn("-%.0f debt" % reduced, Vector2.UP)


func _add_task_icon(task: TaskData) -> void:
	var tex_rect: TextureRect = TextureRect.new()
	tex_rect.texture = task.texture
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(40, 40)
	task_icons.add_child(tex_rect)


func _remove_first_task_icon() -> void:
	if task_icons.get_child_count() > 0:
		task_icons.get_child(0).queue_free()


func _on_task_drop_requested(task_data: TaskData, screen_pos: Vector2) -> void:
	if not can_accept_task(task_data):
		return
	var my_screen_pos: Vector2 = get_global_transform_with_canvas().origin
	if my_screen_pos.distance_to(screen_pos) < 120.0:
		var task_copy: TaskData = task_data.duplicate()
		assign_task(task_copy)
		if task_data.task_type == Constants.TaskType.BUG:
			PD.task_queue.erase(task_data)
			SB.task_queue_changed.emit(PD.task_queue)
		SB.task_drop_consumed.emit(task_data)
