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
var game_state: Constants.GameState = Constants.GameState.PLANNING
var _elapsed: float = 0.0


func _ready() -> void:
	SB.task_finished.connect(_on_task_finished)
	fill_backlog()


func _process(delta: float) -> void:
	if game_state == Constants.GameState.WORKING:
		_elapsed += delta
		_check_sprint_complete()


func get_time_scale() -> float:
	return 1.0 + _elapsed / 60.0


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


func start_sprint(sprint_tasks: Array[TaskData]) -> void:
	for task: TaskData in sprint_tasks:
		backlog.erase(task)
	task_queue = sprint_tasks.duplicate()
	game_state = Constants.GameState.WORKING
	SB.game_state_changed.emit(game_state)
	SB.sprint_started.emit()
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Sprint started with %d tasks" % task_queue.size())


func end_sprint() -> void:
	game_state = Constants.GameState.PLANNING
	fill_backlog()
	SB.sprint_ended.emit()
	SB.game_state_changed.emit(game_state)
	Log.log_info(name, "Sprint ended, entering planning")


func _check_sprint_complete() -> void:
	if task_queue.size() > 0:
		return
	for dev: Developer in developers:
		if not dev.is_idle():
			return
	end_sprint()


func _on_task_finished(developer: Developer, task: TaskData) -> void:
	_apply_task_rewards(task)
	_apply_tech_debt(developer, task)


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
			Log.log_info(name, "Refactor done")


func _apply_tech_debt(developer: Developer, task: TaskData) -> void:
	if not developer.data:
		return
	match task.task_type:
		Constants.TaskType.FEATURE:
			var debt_gain: float = float(developer.data.tech_debt) / 100.0 * Constants.DEBT_PER_TASK
			if debt_gain > 0.0:
				increase_tech_debt(debt_gain)
		Constants.TaskType.REFACTOR:
			var debt_reduction: float = float(developer.data.refactor_speed) / 100.0
			if debt_reduction > 0.0:
				increase_tech_debt(-debt_reduction)


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
