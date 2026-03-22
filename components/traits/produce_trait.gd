class_name ProduceTrait
extends Node

const PRODUCT_SCENE: PackedScene = preload("res://components/product/product.tscn")

signal produced(product: Product)
signal started
signal stopped

var product_data: ProductData
var produce_time: float = 5.0

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
		_spawn_product()


func _spawn_product() -> void:
	if not product_data:
		Log.log_warn(name, "No product_data set")
		produced.emit(null)
		return

	var level: Node2D = get_tree().get_first_node_in_group("level") as Node2D
	if not level:
		Log.log_warn(name, "No level found, can't spawn product")
		produced.emit(null)
		return

	var product: Product = PRODUCT_SCENE.instantiate() as Product
	product.data = product_data
	level.add_child(product)
	product.global_position = get_parent().global_position
	Log.log_debug(name, "Produced %s at %s" % [product_data.product_name, str(product.global_position)])
	produced.emit(product)
