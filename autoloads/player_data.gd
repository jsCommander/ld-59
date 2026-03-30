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
	var quality: float = developer.data.quality

	match task.task_type:
		TaskData.TaskType.FEATURE:
			var earned: int = roundi(task.reward * quality)
			earn(earned)
			increase_tech_debt(task.debt_delta * (1.0 - quality))
			Log.log_info(name, "Feature completed: %s, earned %d" % [task.task_name, earned])

		TaskData.TaskType.BUG:
			Log.log_info(name, "Bug fixed: %s" % task.task_name)

		TaskData.TaskType.REFACTOR:
			increase_tech_debt(-task.debt_delta * quality)
			Log.log_info(name, "Refactor completed: %s" % task.task_name)


func _on_task_expired(task: TaskData) -> void:
	match task.task_type:
		TaskData.TaskType.BUG:
			spend(task.penalty)
			increase_tech_debt(0.1)
			Log.log_warn(name, "Bug expired! Penalty: %d" % task.penalty)
		TaskData.TaskType.REFACTOR:
			Log.log_info(name, "Refactor expired: %s" % task.task_name)
