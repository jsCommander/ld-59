class_name UpgradeData extends BaseGameData
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export var upgrade_type: Constants.UpgradeType
@export var target_dev_type: Constants.DevType
@export var stat: Constants.UpgradeStat
@export var multiplier: float = 1.0
@export var prerequisites: Array[UpgradeData] = []
