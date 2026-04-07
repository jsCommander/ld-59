class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

var money: int = 0
var tech_debt: float = 0.0
var valuation: int = 0
var task_queue: Array[TaskData] = []
var backlog: Array[TaskData] = []
var developers: Array[Developer] = []


func _ready() -> void:
	SB.developer_attack.connect(_on_developer_attack)
	fill_backlog()


func fill_backlog() -> void:
	while backlog.size() < Constants.BACKLOG_SIZE:
		var bug_chance: float = tech_debt * Constants.BUG_SPAWN_MULTIPLIER
		var refactor_chance: float = tech_debt * Constants.REFACTOR_SPAWN_MULTIPLIER
		var roll: float = randf()
		if roll < bug_chance:
			backlog.append(TASK_DATA_BUG.duplicate())
		elif roll < bug_chance + refactor_chance:
			backlog.append(TASK_DATA_REFACTOR.duplicate())
		else:
			backlog.append(TASK_DATA_FEATURE.duplicate())


func add_tasks_to_queue(tasks: Array[TaskData]) -> void:
	for task: TaskData in tasks:
		backlog.erase(task)
		task.current_hp = task.base_hp
		task.max_hp = task.base_hp
		task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)
	fill_backlog()
	Log.log_info(name, "Added %d tasks to queue (total: %d)" % [tasks.size(), task_queue.size()])


func _on_developer_attack(developer: Developer) -> void:
	if task_queue.is_empty():
		return
	var task: TaskData = task_queue[0]
	var damage: int = _get_damage_for_task(developer.data, task.task_type)
	task.current_hp -= damage
	developer.show_damage(damage)
	increase_tech_debt(Constants.TECH_DEBT_PER_HIT)
	SB.task_hp_changed.emit(task, task.current_hp, task.max_hp)
	if task.current_hp <= 0.0:
		task_queue.pop_front()
		_on_task_destroyed(task)


func _get_damage_for_task(dev_data: DeveloperData, task_type: Constants.TaskType) -> int:
	match task_type:
		Constants.TaskType.FEATURE: return dev_data.feature_damage
		Constants.TaskType.BUG: return dev_data.bug_damage
		Constants.TaskType.REFACTOR: return dev_data.refactor_damage
	return 0


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	SB.task_destroyed.emit(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])


func _apply_task_rewards(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			var earned: int = Constants.BASE
			earn(earned)
			valuation += earned
			SB.valuation_changed.emit()
			Log.log_info(name, "Feature done: +$%d, valuation=%d" % [earned, valuation])
		Constants.TaskType.BUG:
			Log.log_info(name, "Bug fixed")
		Constants.TaskType.REFACTOR:
			var debt_reduction: float = Constants.DEBT_PER_TASK
			increase_tech_debt(-debt_reduction)
			Log.log_info(name, "Refactor done: -%.1f debt" % debt_reduction)


func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)
	Log.log_info(name, "Fired %s" % Constants.DevType.keys()[developer.data.dev_type])


func can_afford(amount: int) -> bool:
	return money >= amount


func earn(amount: int) -> void:
	money += amount
	SB.resource_money_changed.emit()


func spend(amount: int) -> void:
	money = maxi(0, money - amount)
	SB.resource_money_changed.emit()


func increase_tech_debt(delta: float) -> void:
	tech_debt = clampf(tech_debt + delta, 0.0, 100.0)
	SB.resource_tech_debt_changed.emit()


func get_bug_priority() -> float:
	for tier: Dictionary in Constants.PRIORITY_TIERS:
		if tech_debt < tier["max_debt"]:
			return tier["priority"]
	return Constants.MAX_PRIORITY
