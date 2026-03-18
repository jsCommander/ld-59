extends Node2D
class_name DamageNumber

@onready var label_to_clone: Label = %LabelToClone

var spawned_labels: Array = []

func _ready() -> void:
	label_to_clone.visible = false

func test_spawn() -> void:
	for i in range(1000):
		spawn(str(randi_range(-100, -1)), Vector2.RIGHT)
		await get_tree().create_timer(1).timeout

func spawn(damage: String, direction: Vector2) -> void:
	var new_label = label_to_clone.duplicate()
	new_label.text = damage
	new_label.visible = true

	get_tree().root.add_child(new_label)
	spawned_labels.append(new_label)
	new_label.global_position = global_position

	await animate_damage_number(new_label, direction)

func animate_damage_number(new_label: Label, direction: Vector2) -> void:
	Animations.fade_in(new_label, 0.2)

	# var velocity = Vector2(direction.x * 100.0, 100.0)
	# var target_position = global_position + velocity
	# var move_tween = Animations.spawn_arc(new_label, target_position, 200, 1)

	var random_offset = 30.0
	var force = 150.0
	var random_offset_vector = Vector2(randf_range(-random_offset, random_offset), randf_range(-random_offset, random_offset))
	var target_position = global_position + direction.normalized() * force
	
	var move_tween = new_label.create_tween()
	move_tween.tween_property(new_label, "global_position", target_position + random_offset_vector, 0.5)

	var scale_tween = new_label.create_tween()

	scale_tween.tween_property(new_label, "scale", Vector2(1.1, 1.1), 1)
	scale_tween.tween_property(new_label, "scale", Vector2(1.0, 1.0), 1)
	scale_tween.set_loops()

	await move_tween.finished

	var fade_tween = Animations.fade_out(new_label, 0.2)

	await fade_tween.finished

	new_label.queue_free()

func _on_tree_exiting() -> void:
	for label in spawned_labels:
		if is_instance_valid(label):
			Animations.fade_out(label, 0.2).finished.connect(func(): 
				if is_instance_valid(label):
					label.queue_free())
