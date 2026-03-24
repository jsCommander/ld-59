class_name CollectAndDeliverAction
extends Node

enum State { IDLE, FIND_JOB, MOVE_TO_PRODUCT, COLLECT, MOVE_TO_BUILDING, DELIVER }

const RETRY_DELAY: float = 1.0

var _state: State = State.FIND_JOB
var _movement_trait: MovementTrait
var _collect_trait: CollectTrait
var _target_product: Node2D
var _target_product_data: ProductData
var _target_building: Building
var _retry_timer: float = 0.0


func _ready() -> void:
	_movement_trait = _find_sibling(MovementTrait)
	_collect_trait = _find_sibling(CollectTrait)
	if not _movement_trait or not _collect_trait:
		Log.log_error(name, "Missing required traits (MovementTrait, CollectTrait)")
		return
	_movement_trait.movement_finished.connect(_on_movement_finished)
	_change_state(State.FIND_JOB)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_retry_timer -= delta
			if _retry_timer <= 0.0:
				_change_state(State.FIND_JOB)
		State.MOVE_TO_PRODUCT:
			if not is_instance_valid(_target_product):
				_change_state(State.FIND_JOB)


func _change_state(new_state: State) -> void:
	Log.log_debug(name, "State: %s -> %s" % [State.keys()[_state], State.keys()[new_state]])
	_state = new_state

	match _state:
		State.FIND_JOB:
			_find_job()


func _find_job() -> void:
	var parent: Node2D = get_parent() as Node2D
	if not parent:
		return

	# TODO: юниты пока без работы — storage выпилен, доставка отключена
	_retry_timer = RETRY_DELAY
	_change_state(State.IDLE)


func _on_movement_finished() -> void:
	match _state:
		State.MOVE_TO_PRODUCT:
			_do_collect()
		State.MOVE_TO_BUILDING:
			_do_deliver()


func _do_collect() -> void:
	var texture: Texture2D = null
	if is_instance_valid(_target_product):
		var product: Product = _target_product as Product
		if product and product.data:
			texture = product.data.texture
		_target_product.queue_free()
	_target_product = null
	_collect_trait.collect(texture)

	if not is_instance_valid(_target_building):
		Log.log_warn(name, "Target building gone")
		_collect_trait.deliver()
		_retry_timer = RETRY_DELAY
		_change_state(State.IDLE)
		return
	_movement_trait.move_to(_target_building.global_position)
	_state = State.MOVE_TO_BUILDING


func _do_deliver() -> void:
	_collect_trait.deliver()
	_target_building = null
	_target_product_data = null
	_change_state(State.FIND_JOB)


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
