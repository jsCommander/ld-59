@tool
class_name Building
extends Node2D

signal upgrade_applied(upgrade: BuildingUpgrade)

@export var data: BuildingData:
	set(value):
		data = value
		_apply_data()

@onready var sprite: Sprite2D = %Sprite
@onready var storage_trait: StorageTrait = %StorageTrait
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

	if not data.output:
		_configure_storage_only()
	elif data.output.ingredients.is_empty():
		_configure_auto_producer()
	else:
		_configure_factory()


func _configure_storage_only() -> void:
	storage_trait.setup([])
	produce_trait.process_mode = PROCESS_MODE_DISABLED
	Log.log_info(name, "Configured as storage")


func _configure_auto_producer() -> void:
	storage_trait.process_mode = PROCESS_MODE_DISABLED
	var effective_time: float = data.output.produce_time / data.crafting_speed
	produce_trait.setup(data.output, effective_time)
	Log.log_info(name, "Configured as auto-producer: %s" % data.output.product_name)


func _configure_factory() -> void:
	var accepted: Array[ProductData] = []
	for ingredient: RecipeIngredient in data.output.ingredients:
		accepted.append(ingredient.product)
	storage_trait.setup(accepted)
	var effective_time: float = data.output.produce_time / data.crafting_speed
	produce_trait.setup(data.output, effective_time)
	Log.log_info(name, "Configured as factory: %s" % data.output.product_name)


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
	if not data or not data.output:
		return
	var total_speed_bonus: float = 0.0
	var total_extra_produce: int = 0
	for upgrade: BuildingUpgrade in purchased_upgrades:
		var level: int = purchased_upgrades[upgrade]
		total_speed_bonus += upgrade.speed_bonus * level
		total_extra_produce += upgrade.extra_produce * level
	var effective_speed: float = data.crafting_speed * (1.0 + total_speed_bonus)
	var effective_time: float = data.output.produce_time / effective_speed
	produce_trait.setup(data.output, effective_time)
	produce_trait.produce_count = 1 + total_extra_produce
