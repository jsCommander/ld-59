class_name TaskData
extends Resource

enum TaskType { FEATURE, BUG, REFACTOR }

@export var task_name: String
@export var complexity: int = 1
@export var reward: int = 100
@export var penalty: int = 150
@export var debt_delta: float = 0.05
@export var task_type: TaskType = TaskType.FEATURE
