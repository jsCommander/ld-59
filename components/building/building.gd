@tool
class_name Building
extends Node2D

signal upgrade_applied(upgrade: BuildingUpgrade)

@export var data: BuildingData:
	set(value):
		data = value
		_apply_data()

@onready var sprite: Sprite2D = %Sprite
@onready var produce_trait: ProduceTrait = %ProduceTrait

var purchased_upgrades: Dictionary = {}


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	_configure_traits()


func _apply_data() -> void:
	if not data or not is_instance_valid(sprite):
		return
	if data.texture:
		sprite.texture = data.texture


func _configure_traits() -> void:
	if not data:
		return
	_configure_produce_trait()


func _configure_produce_trait() -> void:
	if not data.recipe:
		Log.log_info(name, "No recipe, produce disabled")
		return
	produce_trait.setup(data.recipe)
	if data.recipe.ingredients.is_empty():
		Log.log_info(name, "Configured as auto-producer: %s" % data.recipe.output.product_name)
	else:
		Log.log_info(name, "Configured as factory: %s" % data.recipe.output.product_name)



func get_upgrade_level(upgrade: BuildingUpgrade) -> int:
	return purchased_upgrades.get(upgrade, 0)


func apply_upgrade(upgrade: BuildingUpgrade) -> void:
	purchased_upgrades[upgrade] = get_upgrade_level(upgrade) + 1
	_recalculate_stats()
	upgrade_applied.emit(upgrade)
	Log.log_info(name, "Applied upgrade: %s (Lv.%d)" % [upgrade.upgrade_name, get_upgrade_level(upgrade)])


func get_available_upgrades() -> Array[BuildingUpgrade]:
	if not data:
		return []
	return data.upgrades.filter(
		func(u: BuildingUpgrade) -> bool:
			return u.max_level == 0 or get_upgrade_level(u) < u.max_level
	)


func _recalculate_stats() -> void:
	if not data or not data.recipe:
		return
	var total_speed_bonus: float = 0.0
	var total_extra_produce: int = 0
	for upgrade: BuildingUpgrade in purchased_upgrades:
		var level: int = purchased_upgrades[upgrade]
		total_speed_bonus += upgrade.speed_bonus * level
		total_extra_produce += upgrade.extra_produce * level
	var effective_time: float = data.recipe.produce_time / (1.0 + total_speed_bonus)
	produce_trait.setup(data.recipe, effective_time, 1 + total_extra_produce)
