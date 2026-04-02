class_name TaskData
extends Resource

enum TaskType { FEATURE, BUG, REFACTOR }

@export var task_name: String
@export var task_type: TaskType = TaskType.FEATURE
@export var story_points: int = 1
@export var timer: int = 1
