class_name PlayerData extends Node


var products: Dictionary[String, int]:
	get:
		return _products

var _products: Dictionary[String, int] = {
	C.PRODUCT_FRUIT: 0,
	C.PRODUCT_BATTERY: 0,
}


func _ready() -> void:
	SB.product_produced.connect(_on_product_produced)
	SB.upgrade_unlocked.connect(_on_upgrade_unlocked)


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
	SB.player_data_changed.emit()


func _on_product_produced(type: String, count: int) -> void:
	if not _products.has(type):
		return
	_products[type] += count
	SB.player_data_changed.emit()


# --- Upgrade Tree ---

var _unlocked_upgrades: Array[String] = []


func is_upgrade_unlocked(upgrade: UpgradeTree) -> bool:
	return upgrade.id in _unlocked_upgrades


func can_unlock_upgrade(upgrade: UpgradeTree) -> bool:
	if is_upgrade_unlocked(upgrade):
		return false
	for req: UpgradeTree in upgrade.prerequisites:
		if not is_upgrade_unlocked(req):
			return false
	return true


func _on_upgrade_unlocked(upgrade: UpgradeTree) -> void:
	_unlocked_upgrades.append(upgrade.id)
	SB.player_data_changed.emit()
