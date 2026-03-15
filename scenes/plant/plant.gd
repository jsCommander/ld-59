class_name Plant
extends Node2D

@export var stat: PlantStat

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
	_apply_stat()

func _apply_stat() -> void:
	if not stat or not is_instance_valid(sprite):
		return
	if stat.texture:
		sprite.texture = stat.texture
