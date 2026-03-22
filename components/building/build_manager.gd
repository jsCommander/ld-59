class_name BuildManager
extends Node2D

const BUILDING_SCENE: PackedScene = preload("res://components/building/building.tscn")
const SLOT_SCENE: PackedScene = preload("res://components/slot/slot.tscn")


func _ready() -> void:
	SB.build_requested.connect(_on_build_requested)
	SB.demolish_requested.connect(_on_demolish_requested)


func _on_build_requested(slot: Slot, building_data: BuildingData) -> void:
	var pos: Vector2 = slot.global_position
	slot.queue_free()
	var building: Building = BUILDING_SCENE.instantiate()
	building.data = building_data
	building.global_position = pos
	add_child(building)
	Log.log_info(name, "Built %s at %s" % [building_data.building_name, pos])


func _on_demolish_requested(building: Building) -> void:
	var pos: Vector2 = building.global_position
	building.queue_free()
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.global_position = pos
	add_child(slot)
	Log.log_info(name, "Demolished building at %s" % pos)
