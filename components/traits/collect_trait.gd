class_name CollectTrait
extends Node2D

signal collected
signal delivered

@export var carry_offset: Vector2 = Vector2(0, -30)

var is_carrying: bool = false

@onready var _carry_sprite: Sprite2D = %CarrySprite


func _ready() -> void:
	position = carry_offset
	_carry_sprite.visible = false


func collect(texture: Texture2D) -> void:
	is_carrying = true
	_carry_sprite.texture = texture
	_carry_sprite.visible = true
	Log.log_debug(name, "Collected item")
	collected.emit()


func deliver() -> void:
	is_carrying = false
	_carry_sprite.visible = false
	_carry_sprite.texture = null
	Log.log_debug(name, "Delivered item")
	delivered.emit()
