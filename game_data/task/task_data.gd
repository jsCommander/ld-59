class_name TaskData
extends Resource

enum TaskType { TASK, BUG }

@export var task_name: String
@export var complexity: int = 1
@export var reward: int = 100
@export var penalty: int = 150
@export var deadline: float = 30.0
@export var task_type: TaskType = TaskType.TASK
