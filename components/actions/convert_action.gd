class_name ConvertAction
extends Node

var _storage_trait: StorageTrait
var _produce_trait: ProduceTrait
var _is_converting: bool = false


func _ready() -> void:
	_storage_trait = _find_sibling(StorageTrait)
	_produce_trait = _find_sibling(ProduceTrait)
	if not _storage_trait or not _produce_trait:
		Log.log_error(name, "Missing StorageTrait or ProduceTrait")
		return

	_storage_trait.resource_received.connect(_on_resource_received)
	_produce_trait.produced.connect(_on_conversion_complete)
	# If there are already resources, start converting
	if not _storage_trait.is_empty():
		_start_conversion()


func _on_resource_received() -> void:
	if not _is_converting:
		_start_conversion()


func _start_conversion() -> void:
	if _storage_trait.is_empty():
		_is_converting = false
		return
	_storage_trait.remove()
	_is_converting = true
	_produce_trait.start()
	Log.log_info(name, "Converting...")


func _on_conversion_complete(_product: Node2D) -> void:
	_is_converting = false
	SB.battery_produced.emit()
	Log.log_info(name, "Battery produced!")
	_start_conversion()


func _find_sibling(type: Variant) -> Node:
	for child: Node in get_parent().get_children():
		if is_instance_of(child, type):
			return child
	return null
