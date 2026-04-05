class_name DeveloperData
extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var feature_speed: int = 50
@export var bug_speed: int = 50
@export var refactor_speed: int = 50
@export var tech_debt: int = 30
@export var salary_mult: float = 2.5
@export var upgrades: Array[DeveloperUpgrade] = []
