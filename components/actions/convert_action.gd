class_name ConvertAction
extends Node

signal converted(product: ProductData)

var _storage_trait: StorageTrait
var _produce_trait: ProduceTrait
var _ingredients: Array[RecipeIngredient] = []
var _product_data: ProductData
var _is_converting: bool = false


func setup(ingredients: Array[RecipeIngredient], product: ProductData) -> void:
	_ingredients = ingredients
	_product_data = product

	_storage_trait = _find_sibling(StorageTrait)
	_produce_trait = _find_sibling(ProduceTrait)
	if not _storage_trait or not _produce_trait:
		Log.log_error(name, "Missing StorageTrait or ProduceTrait")
		return

	_storage_trait.resource_received.connect(_on_resource_received)
	_produce_trait.produced.connect(_on_conversion_complete)


func try_start_conversion() -> void:
	if _is_converting:
		return
	_start_conversion()


func _on_resource_received(_product: ProductData) -> void:
	if not _is_converting:
		_start_conversion()


func _start_conversion() -> void:
	if not _storage_trait.has_ingredients(_ingredients):
		_is_converting = false
		return
	_storage_trait.consume_ingredients(_ingredients)
	_is_converting = true
	_produce_trait.start()
	Log.log_info(name, "Converting to %s..." % _product_data.product_name)


func _on_conversion_complete(_product: Node2D) -> void:
	_is_converting = false
	converted.emit(_product_data)
	Log.log_info(name, "%s produced!" % _product_data.product_name)
	_start_conversion()


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
