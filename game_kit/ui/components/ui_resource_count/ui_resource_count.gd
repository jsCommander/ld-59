@tool
extends Control
class_name UiResourceCount

@export var count: int
@export var icon: Texture2D

@onready var label: Label = %Label
@onready var texture_rect: TextureRect = %TextureRect

func _process(delta: float) -> void:
	label.text = str(count)
	texture_rect.texture = icon
