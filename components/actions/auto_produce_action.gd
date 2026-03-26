class_name AutoProduceAction
extends Node

var _produce_trait: ProduceTrait
var _cost: Dictionary = {}


func _ready() -> void:
	_produce_trait = _find_sibling(ProduceTrait)
	if not _produce_trait:
		Log.log_error(name, "Missing ProduceTrait")
		return
	_produce_trait.stopped.connect(_on_stopped)
	_deferred_start()


func _deferred_start() -> void:
	await get_tree().process_frame
	if _produce_trait.recipe:
		_cost = _produce_trait.recipe.get_cost()
	_try_start()


func _try_start() -> void:
	if _cost.is_empty() or PD.can_afford(_cost):
		if not _cost.is_empty():
			PD.spend(_cost)
		_produce_trait.start()
	else:
		SB.player_data_changed.connect(_on_data_changed)


func _on_data_changed() -> void:
	if PD.can_afford(_cost):
		SB.player_data_changed.disconnect(_on_data_changed)
		PD.spend(_cost)
		_produce_trait.start()


func _on_stopped() -> void:
	call_deferred("_try_start")


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
