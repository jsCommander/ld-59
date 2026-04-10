class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var task_mults: Dictionary = {}
@export var base_attack_speed: float = 0.5
@export var task_select: TaskSelectFunction
