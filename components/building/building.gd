class_name Building
extends Node2D

@export var data: BuildingData

@onready var sprite: Sprite2D = %Sprite
@onready var storage_trait: StorageTrait = %StorageTrait
@onready var produce_trait: ProduceTrait = %ProduceTrait
@onready var convert_action: ConvertAction = %ConvertAction


func _ready() -> void:
	_apply_data()
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
	convert_action.process_mode = PROCESS_MODE_DISABLED
	Log.log_info(name, "Configured as storage")


func _configure_auto_producer() -> void:
	storage_trait.process_mode = PROCESS_MODE_DISABLED
	convert_action.process_mode = PROCESS_MODE_DISABLED

	var effective_time: float = data.output.produce_time / data.crafting_speed
	produce_trait.setup(data.output, effective_time)
	produce_trait.produced.connect(_on_auto_produced)
	produce_trait.start()
	Log.log_info(name, "Configured as auto-producer: %s" % data.output.product_name)


func _configure_factory() -> void:
	var accepted: Array[ProductData] = []
	for ingredient: RecipeIngredient in data.output.ingredients:
		accepted.append(ingredient.product)
	storage_trait.setup(accepted)

	var effective_time: float = data.output.produce_time / data.crafting_speed
	produce_trait.setup(data.output, effective_time)
	convert_action.setup(data.output.ingredients, data.output)
	convert_action.converted.connect(_on_product_converted)
	Log.log_info(name, "Configured as factory: %s" % data.output.product_name)


func _on_auto_produced(_product: Product) -> void:
	produce_trait.start()


func _on_product_converted(product: ProductData) -> void:
	SB.product_produced.emit(product)
