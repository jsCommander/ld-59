class_name TaskDisplay
extends Control

@onready var icon_rect: TextureRect = %IconRect
@onready var hp_bar: ProgressBar = %HpBar


func show_task(task: TaskData) -> void:
	if task.texture:
		icon_rect.texture = task.texture
	hp_bar.value = 1.0
	visible = true


func update_hp(current_hp: float, max_hp: float) -> void:
	if max_hp > 0.0:
		hp_bar.value = current_hp / max_hp


func hide_task() -> void:
	visible = false
