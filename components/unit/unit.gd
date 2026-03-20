@tool
class_name Unit
extends CharacterBody2D

@export var data: UnitData:
	set(value):
		data = value
		_apply_data()

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	_setup_traits()


func _apply_data() -> void:
	if not data or not is_instance_valid(sprite):
		return
	if data.texture:
		sprite.texture = data.texture


func _setup_traits() -> void:
	if not data:
		return
	var movement: MovementTrait = _find_child_trait(MovementTrait)
	if movement:
		movement.setup(data.speed)


func _find_child_trait(type: Variant) -> Node:
	for child: Node in get_children():
		if is_instance_of(child, type):
			return child
	return null
