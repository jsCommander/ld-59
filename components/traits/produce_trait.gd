class_name ProduceTrait
extends Node2D

const PRODUCT_SCENE: PackedScene = preload("res://components/product/product.tscn")

signal produced(product: Product)

var product_data: ProductData
var produce_time: float = 5.0

@export var bar_offset: Vector2 = Vector2(0, -40)
@export var bar_size: Vector2 = Vector2(32, 4)
@export var bar_color: Color = Color.GREEN
@export var bar_bg_color: Color = Color(0.2, 0.2, 0.2, 0.8)

var _elapsed: float = 0.0
var _is_producing: bool = false


func setup(product: ProductData, time: float) -> void:
	product_data = product
	produce_time = time
	Log.log_debug(name, "Setup: %s (%.1fs)" % [product.product_name, time])


func start() -> void:
	_elapsed = 0.0
	_is_producing = true
	visible = true
	Log.log_debug(name, "Production started (%.1fs)" % produce_time)


func stop() -> void:
	_is_producing = false
	_elapsed = 0.0
	visible = false


func _ready() -> void:
	visible = false
	position = bar_offset


func _process(delta: float) -> void:
	if not _is_producing:
		return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= produce_time:
		_is_producing = false
		_elapsed = 0.0
		visible = false
		_spawn_product()


func _draw() -> void:
	if not _is_producing:
		return
	var bg_rect := Rect2(-bar_size.x / 2.0, 0, bar_size.x, bar_size.y)
	draw_rect(bg_rect, bar_bg_color)
	var progress: float = _elapsed / produce_time
	var fill_rect := Rect2(-bar_size.x / 2.0, 0, bar_size.x * progress, bar_size.y)
	draw_rect(fill_rect, bar_color)


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
