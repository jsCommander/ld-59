class_name Product
extends Node2D

@export var stat: ProductStat

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	_apply_stat()


func _apply_stat() -> void:
	if not stat:
		return
	if stat.group:
		add_to_group(stat.group)
	if is_instance_valid(sprite) and stat.texture:
		sprite.texture = stat.texture
