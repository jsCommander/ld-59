class_name StorageTrait
extends Node

signal resource_received
signal resource_removed

var count: int = 0


func receive() -> void:
	count += 1
	Log.log_debug(name, "Resource received. Count: %d" % count)
	resource_received.emit()


func remove() -> bool:
	if count <= 0:
		return false
	count -= 1
	Log.log_debug(name, "Resource removed. Count: %d" % count)
	resource_removed.emit()
	return true


func is_empty() -> bool:
	return count <= 0
