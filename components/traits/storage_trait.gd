class_name StorageTrait
extends Node

signal resource_received(product: ProductData)
signal resource_removed(product: ProductData)

var _accepted: Array[ProductData] = []
var _accept_all: bool = false
var _storage: Dictionary = {}  # ProductData -> int


func setup(accepted: Array[ProductData]) -> void:
	_accepted = accepted
	_accept_all = accepted.is_empty()
	Log.log_debug(name, "Storage setup: accept_all=%s, types=%d" % [_accept_all, accepted.size()])


func accepts(product: ProductData) -> bool:
	if _accept_all:
		return true
	return product in _accepted


func receive(product: ProductData) -> void:
	if not accepts(product):
		Log.log_warn(name, "Rejected product: %s" % product.product_name)
		return
	_storage[product] = _storage.get(product, 0) + 1
	Log.log_debug(name, "Received %s. Count: %d" % [product.product_name, _storage[product]])
	resource_received.emit(product)


func remove(product: ProductData) -> bool:
	var count: int = _storage.get(product, 0)
	if count <= 0:
		return false
	_storage[product] = count - 1
	if _storage[product] == 0:
		_storage.erase(product)
	Log.log_debug(name, "Removed %s. Count: %d" % [product.product_name, _storage.get(product, 0)])
	resource_removed.emit(product)
	return true


func get_count(product: ProductData) -> int:
	return _storage.get(product, 0)


func has_ingredients(ingredients: Array[RecipeIngredient]) -> bool:
	for ingredient: RecipeIngredient in ingredients:
		if get_count(ingredient.product) < ingredient.count:
			return false
	return true


func consume_ingredients(ingredients: Array[RecipeIngredient]) -> bool:
	if not has_ingredients(ingredients):
		return false
	for ingredient: RecipeIngredient in ingredients:
		for i: int in ingredient.count:
			remove(ingredient.product)
	return true


func is_empty() -> bool:
	return _storage.is_empty()
