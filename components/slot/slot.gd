class_name Slot
extends Node2D

@export var stat: SlotStat

var is_occupied: bool = false:
	set(value):
		is_occupied = value
		_update_texture()

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
	_update_texture()

func _update_texture() -> void:
	if not stat or not is_instance_valid(sprite):
		return
	if is_occupied and stat.occupied_texture:
		sprite.texture = stat.occupied_texture
	elif stat.texture:
		sprite.texture = stat.texture
