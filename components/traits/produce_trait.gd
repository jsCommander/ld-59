class_name ProduceTrait
extends Node

signal started
signal stopped

var product_data: ProductData
var produce_time: float = 5.0
var produce_count: int = 1

var _elapsed: float = 0.0
var _is_producing: bool = false


func setup(product: ProductData, time: float) -> void:
	product_data = product
	produce_time = time
	Log.log_debug(name, "Setup: %s (%.1fs)" % [product.product_name, time])


func start() -> void:
	_elapsed = 0.0
	_is_producing = true
	started.emit()
	Log.log_debug(name, "Production started (%.1fs)" % produce_time)


func stop() -> void:
	_is_producing = false
	_elapsed = 0.0
	stopped.emit()


func _process(delta: float) -> void:
	if not _is_producing:
		return
	_elapsed += delta
	if _elapsed >= produce_time:
		_is_producing = false
		_elapsed = 0.0
		stopped.emit()
		_produce()


func _produce() -> void:
	if not product_data:
		Log.log_warn(name, "No product_data set")
		return
	Log.log_debug(name, "Produced %s" % product_data.product_name)
	SB.product_produced.emit(product_data.id, produce_count)
