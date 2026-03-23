class_name AutoProduceAction
extends Node

var _produce_trait: ProduceTrait


func _ready() -> void:
	_produce_trait = _find_sibling(ProduceTrait)
	if not _produce_trait:
		Log.log_error(name, "Missing ProduceTrait")
		return
	_produce_trait.stopped.connect(_on_stopped)
	_deferred_start()


func _deferred_start() -> void:
	await get_tree().process_frame
	_produce_trait.start()


func _on_stopped() -> void:
	_produce_trait.call_deferred("start")


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
