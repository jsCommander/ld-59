class_name PlayerData extends Node

const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")

var money: int = Constants.STARTING_BUDGET
var tech_debt: float = 0.0
var sprint_number: int = 0
var bug_multiplier: float = 0.5
var task_queue: Array[TaskData] = []
var developers: Array[Developer] = []
var _sprint_active: bool = false


func _ready() -> void:
	SB.sprint_execute_requested.connect(start_sprint)
	SB.task_finished.connect(_on_task_finished)


func start_sprint() -> void:
	sprint_number += 1
	var bug_count: int = roundi(tech_debt * bug_multiplier)
	for i: int in bug_count:
		var bug: TaskData = TASK_DATA_BUG.duplicate()
		task_queue.append(bug)
	SB.task_queue_changed.emit(task_queue)
	_sprint_active = true
	SB.sprint_started.emit()
	Log.log_info(name, "Sprint %d started (%d bugs, debt=%.0f)" % [
		sprint_number, bug_count, tech_debt
	])


func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)
	Log.log_info(name, "Fired %s" % Constants.DevType.keys()[developer.data.dev_type])


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


func _on_task_finished(developer: Developer, task: TaskData) -> void:
	var dev_data: DeveloperData = developer.data

	match task.task_type:
		Constants.TaskType.FEATURE:
			var earned: int = Constants.BASE
			earn(earned)
			var debt_gain: float = float(dev_data.tech_debt) / 100.0 * Constants.DEBT_PER_TASK
			increase_tech_debt(debt_gain)
			Log.log_info(name, "Feature done: +$%d, +%.1f debt" % [earned, debt_gain])

		Constants.TaskType.BUG:
			Log.log_info(name, "Bug fixed")

		Constants.TaskType.REFACTOR:
			var debt_reduction: float = float(dev_data.refactor_speed) / 100.0
			increase_tech_debt(-debt_reduction)
			Log.log_info(name, "Refactor done: -%.1f debt" % debt_reduction)

	_check_sprint_end()


func _check_sprint_end() -> void:
	if not _sprint_active:
		return
	for dev: Developer in developers:
		if dev.has_tasks():
			return
	_sprint_active = false
	SB.sprint_ended.emit()
	Log.log_info(name, "Sprint %d ended" % sprint_number)


func expire_task(task: TaskData) -> void:
	task_queue.erase(task)
	match task.task_type:
		Constants.TaskType.BUG:
			var penalty: int = Constants.BASE * roundi(get_bug_priority())
			spend(penalty)
			increase_tech_debt(10.0)
			Log.log_warn(name, "Bug expired! Penalty: $%d" % penalty)
		_:
			Log.log_info(name, "Task expired")
	SB.task_queue_changed.emit(task_queue)
