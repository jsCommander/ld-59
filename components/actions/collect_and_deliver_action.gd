class_name CollectAndDeliverAction
extends Node

enum State { IDLE, FIND_FRUIT, MOVE_TO_FRUIT, COLLECT, MOVE_TO_FACTORY, DELIVER }

const RETRY_DELAY: float = 1.0

var _state: State = State.FIND_FRUIT
var _movement_trait: MovementTrait
var _collect_trait: CollectTrait
var _target_fruit: Node2D
var _target_factory: Node2D
var _retry_timer: float = 0.0


func _ready() -> void:
	_movement_trait = _find_sibling(MovementTrait)
	_collect_trait = _find_sibling(CollectTrait)
	if not _movement_trait or not _collect_trait:
		Log.log_error(name, "Missing required traits (MovementTrait, CollectTrait)")
		return
	_movement_trait.movement_finished.connect(_on_movement_finished)
	_change_state(State.FIND_FRUIT)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_retry_timer -= delta
			if _retry_timer <= 0.0:
				_change_state(State.FIND_FRUIT)
		State.MOVE_TO_FRUIT:
			if not is_instance_valid(_target_fruit):
				_change_state(State.FIND_FRUIT)


func _change_state(new_state: State) -> void:
	Log.log_debug(name, "State: %s -> %s" % [State.keys()[_state], State.keys()[new_state]])
	_state = new_state

	match _state:
		State.FIND_FRUIT:
			_find_fruit()


func _find_fruit() -> void:
	var parent: Node2D = get_parent() as Node2D
	if not parent:
		return
	_target_fruit = Utils.find_closest_target_in_group("fruit", parent)
	if not _target_fruit:
		_retry_timer = RETRY_DELAY
		_change_state(State.IDLE)
		return
	_movement_trait.move_to(_target_fruit.global_position)
	_state = State.MOVE_TO_FRUIT


func _on_movement_finished() -> void:
	match _state:
		State.MOVE_TO_FRUIT:
			_do_collect()
		State.MOVE_TO_FACTORY:
			_do_deliver()


func _do_collect() -> void:
	var texture: Texture2D = null
	if is_instance_valid(_target_fruit):
		var product: Product = _target_fruit as Product
		if product and product.stat:
			texture = product.stat.texture
		_target_fruit.queue_free()
	_target_fruit = null
	_collect_trait.collect(texture)

	var parent: Node2D = get_parent() as Node2D
	if not parent:
		return
	_target_factory = Utils.find_closest_target_in_group("factory", parent)
	if not _target_factory:
		Log.log_warn(name, "No factory found")
		_retry_timer = RETRY_DELAY
		_change_state(State.IDLE)
		return
	_movement_trait.move_to(_target_factory.global_position)
	_state = State.MOVE_TO_FACTORY


func _do_deliver() -> void:
	if is_instance_valid(_target_factory):
		var storage: StorageTrait = _find_trait_on(_target_factory, StorageTrait)
		if storage:
			storage.receive()
	_collect_trait.deliver()
	_target_factory = null
	_change_state(State.FIND_FRUIT)


func _find_trait_on(node: Node, type: Variant) -> Node:
	for child: Node in node.get_children():
		if is_instance_of(child, type):
			return child
	return null


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
