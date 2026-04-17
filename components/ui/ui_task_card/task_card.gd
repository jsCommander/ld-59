@tool
class_name TaskCard
extends Control

# --- Exports ---

@export var task_data: TaskData:
	set(value):
		task_data = value
		_apply_task()

# --- State ---

@export var show_hp: bool = false

# --- @onready ---

@onready var icon: TextureRect = %Icon
@onready var hp_bar: ProgressBar = %HpBar
@onready var flashable: FlashableTrait = %FlashableTrait
@onready var hp_label: Label = %HpLabel
@onready var damage_number: DamageNumber = %DamageNumber

# --- Lifecycle ---

func _ready() -> void:
	_apply_task()

# --- Public ---

func setup(data: TaskData) -> void:
	task_data = data


func update_hp() -> void:
	if not is_instance_valid(hp_bar) or not task_data or task_data.max_hp <= 0.0:
		return
	hp_bar.visible = true
	hp_bar.max_value = task_data.max_hp
	hp_bar.value = maxf(task_data.current_hp, 0.0)
	hp_label.text = Utils.format_number(int(task_data.current_hp))


func flash() -> void:
	flashable.flash()


func show_damage(damage: int) -> void:
	damage_number.spawn("-%d" % damage, Vector2.UP, Color.YELLOW)

func kill() -> void:
	task_data = null
	hide_content()


func hide_task() -> void:
	task_data = null
	hide_content()


func show_content() -> void:
	icon.visible = true
	hp_bar.visible = true


func hide_content() -> void:
	icon.visible = false
	hp_bar.visible = false

# --- Private ---

func _apply_task() -> void:
	if not is_instance_valid(icon):
		return
	if not task_data:
		hide_content()
		return

	show_content()
	icon.texture = task_data.texture
	if task_data.max_hp > 0.0:
		hp_bar.visible = true
		hp_bar.max_value = task_data.max_hp
		hp_bar.value = task_data.current_hp
		hp_label.text = Utils.format_number(int(task_data.current_hp))
