class_name Slot
extends Node2D

@export var data: SlotData

var is_occupied: bool = false:
	set(value):
		is_occupied = value
		_update_texture()

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
	_update_texture()

func _update_texture() -> void:
	if not data or not is_instance_valid(sprite):
		return
	if is_occupied and data.occupied_texture:
		sprite.texture = data.occupied_texture
	elif data.texture:
		sprite.texture = data.texture
