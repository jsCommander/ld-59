class_name BuildingData
extends BaseGameData

@export var texture: Texture2D
@export var building_name: String
@export var icon: Texture2D
@export var output: ProductData
@export var crafting_speed: float = 1.0
@export var upgrades: Array[BuildingUpgrade] = []
