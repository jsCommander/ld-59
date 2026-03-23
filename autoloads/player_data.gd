class_name PlayerData extends Node

signal data_changed

var _products: Dictionary[String, int] = {
	C.PRODUCT_FRUIT: 0,
	C.PRODUCT_BATTERY: 0,
}


func _ready() -> void:
	SB.product_produced.connect(_on_product_produced)


func get_product(product_id: String) -> int:
	return _products.get(product_id, 0)


func can_afford(cost: Dictionary) -> bool:
	for product_id: String in cost:
		if get_product(product_id) < cost[product_id]:
			return false
	return true


func spend(cost: Dictionary) -> void:
	for product_id: String in cost:
		_products[product_id] -= cost[product_id]
	data_changed.emit()


func _on_product_produced(type: String, count: int) -> void:
	if not _products.has(type):
		return
	_products[type] += count
	data_changed.emit()
