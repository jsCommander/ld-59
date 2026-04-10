class_name TaskDisplay
extends Control

@onready var icon_rect: TextureRect = %IconRect
@onready var hp_bar: ProgressBar = %HpBar

var _flash_tween: Tween = null

const YOUTUBE_ICON: Texture2D = preload("res://assets/icons/icn_sleep.png")
const BURNOUT_ICON: Texture2D = preload("res://assets/icons/icn_fire.png")


func show_task(task: TaskData) -> void:
	if task.texture:
		icon_rect.texture = task.texture
	hp_bar.value = 1.0
	hp_bar.visible = true
	visible = true


func update_hp(current_hp: float, max_hp: float) -> void:
	if max_hp > 0.0:
		hp_bar.value = current_hp / max_hp


func flash_hit() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	icon_rect.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(icon_rect, "modulate", Color.WHITE, 0.15)


func show_youtube() -> void:
	icon_rect.texture = YOUTUBE_ICON
	hp_bar.visible = false
	visible = true


func show_burnout() -> void:
	icon_rect.texture = BURNOUT_ICON
	hp_bar.visible = false
	visible = true


func hide_task() -> void:
	visible = false
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	icon_rect.modulate = Color.WHITE
