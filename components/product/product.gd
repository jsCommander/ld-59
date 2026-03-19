class_name Product
extends Node2D

@export var data: ProductData

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	_apply_data()


func _apply_data() -> void:
	if not data:
		return
	if data.group:
		add_to_group(data.group)
	if is_instance_valid(sprite) and data.texture:
		sprite.texture = data.texture
