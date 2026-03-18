class_name Unit
extends CharacterBody2D

@export var stat: UnitStat

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	_apply_stat()
	_setup_traits()


func _apply_stat() -> void:
	if not stat or not is_instance_valid(sprite):
		return
	if stat.texture:
		sprite.texture = stat.texture


func _setup_traits() -> void:
	if not stat:
		return
	var movement: MovementTrait = _find_child_trait(MovementTrait)
	if movement:
		movement.setup(stat.speed)


func _find_child_trait(type: Variant) -> Node:
	for child: Node in get_children():
		if is_instance_of(child, type):
			return child
	return null
