class_name BuildManager
extends Node2D

const DEVELOPER_SCENE: PackedScene = preload("res://components/developer/developer.tscn")
const SLOT_SCENE: PackedScene = preload("res://components/slot/slot.tscn")


func _ready() -> void:
	SB.hire_requested.connect(_on_hire_requested)
	SB.fire_requested.connect(_on_fire_requested)


func _on_hire_requested(slot: Slot, developer_data: DeveloperData) -> void:
	var pos: Vector2 = slot.global_position
	slot.queue_free()
	var developer: Developer = DEVELOPER_SCENE.instantiate()
	developer.data = developer_data
	developer.global_position = pos
	add_child(developer)
	Log.log_info(name, "Hired %s at %s" % [developer_data.dev_name, pos])


func _on_fire_requested(developer: Developer) -> void:
	var pos: Vector2 = developer.global_position
	developer.queue_free()
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.global_position = pos
	add_child(slot)
	Log.log_info(name, "Fired developer at %s" % pos)
