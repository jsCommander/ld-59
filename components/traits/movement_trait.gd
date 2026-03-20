class_name MovementTrait
extends Node

signal movement_finished

var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _speed: float = 100.0

const ARRIVAL_DISTANCE: float = 5.0


func setup(speed: float) -> void:
	_speed = speed


func move_to(target_position: Vector2) -> void:
	_target_position = target_position
	_is_moving = true


func stop() -> void:
	_is_moving = false
	var body: CharacterBody2D = get_parent() as CharacterBody2D
	if body:
		body.velocity.x = 0.0


func _physics_process(_delta: float) -> void:
	if not _is_moving:
		return

	var body: CharacterBody2D = get_parent() as CharacterBody2D
	if not body:
		return

	var distance: float = body.global_position.distance_to(_target_position)
	if distance < ARRIVAL_DISTANCE:
		body.velocity.x = 0.0
		_is_moving = false
		movement_finished.emit()
		return

	var direction: Vector2 = body.global_position.direction_to(_target_position)
	body.velocity.x = direction.x * _speed

	var sprite: Sprite2D = body.get_node_or_null("%Sprite")
	if sprite:
		sprite.flip_h = direction.x < 0.0
