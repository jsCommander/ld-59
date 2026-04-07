class_name DeveloperData
extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var feature_damage: int = 50
@export var bug_damage: int = 50
@export var refactor_damage: int = 50
@export var tech_debt: int = 30
@export var base_attack_speed: float = 2.0
@export var salary_mult: float = 2.5
@export var upgrades: Array[DeveloperUpgrade] = []
