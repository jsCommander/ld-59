class_name SprintManager
extends Node

@export var sprint_duration: float = 30.0
@export var pressure: float = 1.2
@export var max_tasks: int = 8
@export var min_tasks: int = 3
@export var first_sprint_tasks: int = 6

var sprint_number: int = 0
var _time_remaining: float = 0.0
var _is_running: bool = false

const FEATURE_NAMES: Array[String] = [
	"Implement login",
	"Deploy to staging",
	"Add new feature",
	"Update REST API",
	"Add pagination",
]

const BUG_NAMES: Array[String] = [
	"Fix null pointer",
	"Fix database query",
	"Fix memory leak",
	"Fix race condition",
	"Fix broken auth",
]

const REFACTOR_NAMES: Array[String] = [
	"Refactor module",
	"Write unit tests",
	"Code review",
	"Optimize query",
	"Clean up legacy code",
]

const DEBT_TIERS: Array[Dictionary] = [
	{"max_debt": 0.3, "feature": 0.8, "bug": 0.2, "refactor": 0.0},
	{"max_debt": 0.6, "feature": 0.5, "bug": 0.3, "refactor": 0.2},
	{"max_debt": 0.8, "feature": 0.2, "bug": 0.5, "refactor": 0.3},
	{"max_debt": 1.1, "feature": 0.05, "bug": 0.6, "refactor": 0.35},
]


const BONUS_TASKS: int = 4

func _ready() -> void:
	SB.queue_empty.connect(_on_queue_empty)
	_start_sprint()


func _process(delta: float) -> void:
	if not _is_running:
		return
	_time_remaining -= delta
	SB.sprint_tick.emit(_time_remaining)
	if _time_remaining <= 0.0:
		_end_sprint()


func _start_sprint() -> void:
	sprint_number += 1
	_time_remaining = sprint_duration
	_is_running = true

	var pack: Array[TaskData] = _generate_pack()
	for task: TaskData in pack:
		SB.task_spawned.emit(task)

	SB.sprint_started.emit(sprint_number, sprint_duration)
	Log.log_info(name, "Sprint %d started (%d tasks, debt=%.2f)" % [
		sprint_number, pack.size(), PD.tech_debt
	])


func _on_queue_empty() -> void:
	if not _is_running:
		return
	Log.log_info(name, "Bonus tasks mid-sprint")
	for i: int in BONUS_TASKS:
		var task: TaskData = _create_task()
		task.complexity = _pick_complexity()
		task.reward = task.complexity * 50 if task.task_type == TaskData.TaskType.FEATURE else 0
		task.debt_delta = 0.15 * task.complexity if task.task_type == TaskData.TaskType.REFACTOR else task.debt_delta
		SB.task_spawned.emit(task)


func _end_sprint() -> void:
	_is_running = false
	Log.log_info(name, "Sprint %d ended" % sprint_number)
	SB.sprint_ended.emit(sprint_number)
	await get_tree().process_frame
	_start_sprint()


func _get_task_count() -> int:
	var devs: Array[Node] = get_tree().get_nodes_in_group("developer")
	var dev_count: int = devs.size()
	if sprint_number == 1:
		return first_sprint_tasks
	if dev_count == 0:
		return min_tasks
	# ~2 tasks per dev, clamped to [min_tasks, max_tasks]
	return clampi(dev_count * 2, min_tasks, max_tasks)


func _get_avg_speed() -> float:
	var devs: Array[Node] = get_tree().get_nodes_in_group("developer")
	if devs.is_empty():
		return 1.0
	var total: float = 0.0
	for node: Node in devs:
		var dev: Developer = node as Developer
		if dev and dev.data:
			total += dev.data.speed
	return total / devs.size()


func _pick_complexity() -> int:
	# Higher avg speed → higher complexity tasks (they'll handle it)
	# Lower avg speed → simpler tasks (but more pressure from quantity)
	var avg_speed: float = _get_avg_speed() * pressure
	if avg_speed >= 2.0:
		return randi_range(2, 3)
	elif avg_speed >= 1.0:
		return randi_range(1, 3)
	else:
		return randi_range(1, 2)


func _generate_pack() -> Array[TaskData]:
	var count: int = _get_task_count()
	var pack: Array[TaskData] = []
	for i: int in count:
		var task: TaskData = _create_task()
		task.complexity = _pick_complexity()
		task.reward = task.complexity * 50 if task.task_type == TaskData.TaskType.FEATURE else 0
		task.penalty = task.complexity * 75 if task.task_type == TaskData.TaskType.BUG else 0
		task.debt_delta = 0.15 * task.complexity if task.task_type == TaskData.TaskType.REFACTOR else task.debt_delta
		pack.append(task)
	return pack


func _get_tier() -> Dictionary:
	for tier: Dictionary in DEBT_TIERS:
		if PD.tech_debt < tier["max_debt"]:
			return tier
	return DEBT_TIERS[-1]


func _pick_task_type() -> TaskData.TaskType:
	var tier: Dictionary = _get_tier()
	var roll: float = randf()
	if roll < tier["feature"]:
		return TaskData.TaskType.FEATURE
	elif roll < tier["feature"] + tier["bug"]:
		return TaskData.TaskType.BUG
	else:
		return TaskData.TaskType.REFACTOR


func _create_task() -> TaskData:
	var task: TaskData = TaskData.new()
	var task_type: TaskData.TaskType = _pick_task_type()

	match task_type:
		TaskData.TaskType.FEATURE:
			task.task_name = FEATURE_NAMES.pick_random()
			task.debt_delta = 0.05
			task.task_type = TaskData.TaskType.FEATURE

		TaskData.TaskType.BUG:
			task.task_name = BUG_NAMES.pick_random()
			task.debt_delta = 0.0
			task.task_type = TaskData.TaskType.BUG

		TaskData.TaskType.REFACTOR:
			task.task_name = REFACTOR_NAMES.pick_random()
			task.task_type = TaskData.TaskType.REFACTOR

	Log.log_debug(name, "Created %s: %s" % [
		TaskData.TaskType.keys()[task_type], task.task_name
	])
	return task
