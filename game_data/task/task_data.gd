class_name TaskData
extends Resource

@export var task_type: Constants.TaskType = Constants.TaskType.FEATURE
@export var texture: Texture2D
@export var base_hp_mult: float = 1.0
@export var base_reward_mult: float = 1.0
@export var base_debt_reduction: float = 0.0
var current_hp: float = 0.0
var max_hp: float = 0.0
