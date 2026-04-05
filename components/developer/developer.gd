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
@onready var damage_number: DamageNumber = $DamageNumber
@onready var task_icon: TextureRect = %TaskIcon

var current_task: TaskData = null
var purchased_upgrades: Dictionary = {}


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	produce_trait.stopped.connect(_on_work_done)
	SB.task_queue_changed.connect(_on_task_queue_changed)


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)
	_try_grab_task()


func get_speed_for_task(task: TaskData) -> int:
	match task.task_type:
		Constants.TaskType.FEATURE: return data.feature_speed
		Constants.TaskType.BUG: return data.bug_speed
		Constants.TaskType.REFACTOR: return data.refactor_speed
	return data.feature_speed


func get_work_time(task: TaskData) -> float:
	var speed: int = get_speed_for_task(task)
	var time: float = task.base_time * PD.get_time_scale() / maxf(float(speed) / 50.0, 0.1)
	return time / get_speed_multiplier()


func get_speed_multiplier() -> float:
	var mult: float = 1.0
	for upgrade: DeveloperUpgrade in purchased_upgrades:
		mult += upgrade.speed_bonus * purchased_upgrades[upgrade]
	return mult


func get_upgrade_level(upgrade: DeveloperUpgrade) -> int:
	return purchased_upgrades.get(upgrade, 0)


func get_available_upgrades() -> Array[DeveloperUpgrade]:
	if not data:
		return []
	return data.upgrades.filter(
		func(u: DeveloperUpgrade) -> bool:
			return u.max_level == 0 or get_upgrade_level(u) < u.max_level
	)


func apply_upgrade(upgrade: DeveloperUpgrade) -> void:
	purchased_upgrades[upgrade] = get_upgrade_level(upgrade) + 1
	Log.log_info(name, "Upgraded %s to Lv.%d" % [upgrade.upgrade_name, purchased_upgrades[upgrade]])


func is_idle() -> bool:
	return current_task == null


func _try_grab_task() -> void:
	if not data or current_task != null or PD.task_queue.is_empty():
		return
	current_task = PD.task_queue.pop_front()
	_update_task_icon()
	SB.task_queue_changed.emit(PD.task_queue)
	var work_time: float = get_work_time(current_task)
	produce_trait.setup_simple(work_time)
	produce_trait.start()
	Log.log_debug(name, "Working on %s (%.1fs)" % [
		Constants.TaskType.keys()[current_task.task_type],
		work_time,
	])


func _on_work_done() -> void:
	if not current_task:
		return
	var finished: TaskData = current_task
	current_task = null
	_update_task_icon()
	_show_completion(finished)
	SB.task_finished.emit(self, finished)
	Log.log_info(name, "Completed %s" % Constants.TaskType.keys()[finished.task_type])
	_try_grab_task()


func _show_completion(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			damage_number.spawn("+$%d" % Constants.BASE, Vector2.UP, Color.GREEN)
			var debt_gain: float = float(data.tech_debt) / 100.0 * Constants.DEBT_PER_TASK
			if debt_gain > 0.0:
				damage_number.spawn("+%.1f debt" % debt_gain, Vector2.UP, Color.RED)
		Constants.TaskType.BUG:
			damage_number.spawn("Fixed!", Vector2.UP, Color.GREEN)
		Constants.TaskType.REFACTOR:
			var debt_reduction: float = float(data.refactor_speed) / 100.0
			damage_number.spawn("-%.1f debt" % debt_reduction, Vector2.UP, Color.GREEN)


func _update_task_icon() -> void:
	if not is_instance_valid(task_icon):
		return
	if current_task:
		task_icon.texture = current_task.texture
		task_icon.visible = true
	else:
		task_icon.texture = null
		task_icon.visible = false


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


func _on_task_queue_changed(_tasks: Array[TaskData]) -> void:
	if is_idle():
		_try_grab_task()
