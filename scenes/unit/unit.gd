class_name Unit
extends CharacterBody2D

@export var stat: UnitStat

var direction: float = 1.0

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
	_apply_stat()

func _apply_stat() -> void:
	if not stat or not is_instance_valid(sprite):
		return
	if stat.texture:
		sprite.texture = stat.texture

func _physics_process(_delta: float) -> void:
	if not stat:
		return
	velocity.x = direction * stat.speed
	move_and_slide()
	if is_on_wall():
		direction *= -1.0
	if direction < 0.0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
