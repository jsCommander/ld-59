class_name ProduceAction
extends Node

var _produce_trait: ProduceTrait


func _ready() -> void:
	_produce_trait = _find_sibling(ProduceTrait)
	if not _produce_trait:
		Log.log_error(name, "No ProduceTrait found on parent")
		return
	_produce_trait.produced.connect(_on_produced)
	_produce_trait.start()


func _on_produced(_product: Node2D) -> void:
	_produce_trait.start()


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
