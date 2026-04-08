class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var base_feature_mult: float = 1.0
@export var base_bug_mult: float = 1.0
@export var base_debt_mult: float = 1.0
@export var base_attack_speed: float = 2.0
@export var task_select: TaskSelectFunction
