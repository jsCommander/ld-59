class_name PlayerData extends Node

var money: int = 500
var tech_debt: float = 0.0


func _ready() -> void:
	SB.task_completed.connect(_on_task_completed)
	SB.task_expired.connect(_on_task_expired)


func earn(amount: int) -> void:
	money += amount
	SB.money_changed.emit()


func spend(amount: int) -> void:
	money -= amount
	SB.money_changed.emit()


func increase_tech_debt(delta: float) -> void:
	tech_debt = clampf(tech_debt + delta, 0.0, 1.0)
	SB.tech_debt_changed.emit()


func _on_task_completed(developer: Developer, task: TaskData) -> void:
	earn(task.reward)
	increase_tech_debt((1.0 - developer.data.quality) * 0.05)
	var bugs: int = roundi(task.complexity * (1.0 - developer.data.quality) * (1.0 + tech_debt))
	Log.log_info(name, "Task completed: %s, earned %d, bugs: %d" % [task.task_name, task.reward, bugs])
	for i: int in bugs:
		var bug: TaskData = TaskData.new()
		bug.task_name = "Bug in %s" % task.task_name
		bug.complexity = task.complexity
		bug.reward = 0
		bug.penalty = task.penalty
		bug.deadline = 20.0 + task.complexity * 5.0
		bug.task_type = TaskData.TaskType.BUG
		SB.bug_generated.emit(bug)


func _on_task_expired(task: TaskData) -> void:
	if task.task_type == TaskData.TaskType.BUG:
		spend(task.penalty)
		increase_tech_debt(0.1)
		Log.log_warn(name, "Bug expired! Penalty: %d" % task.penalty)
