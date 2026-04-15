class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.DEVELOPER
@export var description: String = ""
@export var head_texture: Texture2D
@export var head_offset: Vector2 = Vector2.ZERO
@export var task_mults: Dictionary = {}
@export var base_attack_speed: float = 2.0
@export var task_select: TaskSelectFunction
