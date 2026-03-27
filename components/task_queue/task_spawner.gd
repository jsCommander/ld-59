class_name TaskSpawner
extends Node

@export var spawn_interval: float = 8.0
@export var max_tasks: int = 6

const TASK_NAMES: Array[String] = [
	"Implement login",
	"Fix database query",
	"Deploy to staging",
	"Write unit tests",
	"Code review",
	"Add new feature",
	"Refactor module",
	"Update REST API",
	"Optimize query",
	"Add pagination",
]

var _timer: float = 0.0


func _ready() -> void:
	_spawn_task()
	_spawn_task()
	_spawn_task()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_task()


func _spawn_task() -> void:
	var task: TaskData = TaskData.new()
	task.task_name = TASK_NAMES.pick_random()
	task.complexity = randi_range(1, 3)
	task.reward = task.complexity * 50
	task.penalty = task.complexity * 75
	task.deadline = 25.0 + task.complexity * 10.0
	task.task_type = TaskData.TaskType.TASK
	SB.task_spawned.emit(task)
	Log.log_debug(name, "Spawned task: %s (x%d)" % [task.task_name, task.complexity])
