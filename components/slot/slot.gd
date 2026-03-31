class_name Slot
extends Node2D

@export var data: SlotData

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
	if data and data.texture:
		sprite.texture = data.texture
