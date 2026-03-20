class_name GravityTrait
extends Node

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

func _physics_process(delta: float) -> void:
	var body: CharacterBody2D = get_parent() as CharacterBody2D
	if not body:
		return

	if not body.is_on_floor():
		body.velocity.y += _gravity * delta

	body.move_and_slide()
