@tool
class_name DeveloperTaskCard
extends Control

# --- Exports ---
@export var task: TaskData:
	set(value):
		task = value
		_apply_task()

# --- @onready ---
@onready var icon_rect: TextureRect = %IconRect
@onready var hp_bar: ProgressBar = %HpBar
@onready var level_label: Label = %LevelLabel
@onready var flashable: FlashableTrait = %FlashableTrait
@onready var damage_number: DamageNumber = %DamageNumber


# --- Public ---

func update_health_bar() -> void:
	if task and task.max_hp > 0.0:
		hp_bar.value = task.current_hp / task.max_hp


func flash() -> void:
	flashable.flash()


func show_damage(damage: int) -> void:
	damage_number.spawn("-%dsp" % damage, Vector2.UP, Color.YELLOW)


func kill() -> void:
	task = null
	visible = false


func hide_task() -> void:
	task = null
	visible = false


# --- Private ---

func _apply_task() -> void:
	if not is_instance_valid(icon_rect):
		return
	if not task:
		visible = false
		return
	icon_rect.texture = task.texture
	level_label.text = str(task.level)
	update_health_bar()
	hp_bar.visible = true
	visible = true
