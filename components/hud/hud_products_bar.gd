extends MarginContainer
class_name HudProductsBar

const UI_RESOURCE_COUNT: PackedScene = preload("res://game_kit/ui/components/ui_resource_count/ui_resource_count.tscn")

@onready var hbox: HBoxContainer = %HBoxContainer

var _counters: Dictionary[String, UiResourceCount] = {}


func update(products: Dictionary) -> void:
	Log.log_debug(name, "Updating products: %s" % str(products))
	for product_id: String in products:
		var count: int = products[product_id]
		if _counters.has(product_id):
			_counters[product_id].count = count
		else:
			Log.log_debug(name, "Adding new counter for: %s" % product_id)
			_add_counter(product_id, count)


func _add_counter(product_id: String, count: int) -> void:
	var counter: UiResourceCount = UI_RESOURCE_COUNT.instantiate()
	counter.count = count
	var product_data: ProductData = DR.products.get(product_id)
	if product_data:
		counter.icon = product_data.texture
	hbox.add_child(counter)
	_counters[product_id] = counter
