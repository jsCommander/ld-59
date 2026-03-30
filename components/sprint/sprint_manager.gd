class_name SprintManager
extends Node

@export var sprint_duration: float = 60.0
@export var pressure: float = 1.2
@export var min_tasks: int = 3

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


func _ready() -> void:
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
	Log.log_info(name, "Sprint %d started (%d tasks, capacity=%.1f, debt=%.2f)" % [
		sprint_number, pack.size(), _get_capacity(), PD.tech_debt
	])


func _end_sprint() -> void:
	_is_running = false
	Log.log_info(name, "Sprint %d ended" % sprint_number)
	SB.sprint_ended.emit(sprint_number)
	await get_tree().process_frame
	_start_sprint()


func _get_capacity() -> float:
	var devs: Array[Node] = get_tree().get_nodes_in_group("developer")
	var total: float = 0.0
	for node: Node in devs:
		var dev: Developer = node as Developer
		if dev and dev.data:
			# dev processes complexity_units at rate: speed / 8.0 per second
			total += sprint_duration * dev.data.speed / 8.0
	return total


func _generate_pack() -> Array[TaskData]:
	var capacity: float = _get_capacity() * pressure
	var budget: float = maxf(capacity, min_tasks)
	var pack: Array[TaskData] = []
	var spent: float = 0.0

	while spent < budget:
		var task: TaskData = _create_task()
		spent += task.complexity
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
			task.complexity = randi_range(1, 3)
			task.reward = task.complexity * 50
			task.penalty = 0
			task.debt_delta = 0.05
			task.task_type = TaskData.TaskType.FEATURE

		TaskData.TaskType.BUG:
			task.task_name = BUG_NAMES.pick_random()
			task.complexity = randi_range(1, 2)
			task.reward = 0
			task.penalty = task.complexity * 75
			task.debt_delta = 0.0
			task.task_type = TaskData.TaskType.BUG

		TaskData.TaskType.REFACTOR:
			task.task_name = REFACTOR_NAMES.pick_random()
			task.complexity = randi_range(1, 2)
			task.reward = 0
			task.penalty = 0
			task.debt_delta = 0.15 * task.complexity
			task.task_type = TaskData.TaskType.REFACTOR

	Log.log_debug(name, "Created %s: %s (x%d)" % [
		TaskData.TaskType.keys()[task_type], task.task_name, task.complexity
	])
	return task
