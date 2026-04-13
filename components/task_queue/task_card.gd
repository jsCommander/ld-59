class_name TaskCard
extends Control

# --- State ---

var task_data: TaskData
var show_hp: bool = false

# --- @onready ---

@onready var icon: TextureRect = %Icon
@onready var hp_bar: ProgressBar = %HpBar
@onready var level_label: Label = %LevelLabel

# --- Public ---

func setup(data: TaskData) -> void:
	task_data = data

func update_hp(current: float, max_hp: float) -> void:
	if not is_instance_valid(hp_bar) or max_hp <= 0.0:
		return
	hp_bar.visible = true
	hp_bar.value = maxf(current / max_hp, 0.0)

# --- Lifecycle ---

func _ready() -> void:
	if not task_data:
		return
	icon.texture = task_data.texture
	level_label.text = str(task_data.level)
	if show_hp and task_data.max_hp > 0.0:
		hp_bar.visible = true
		hp_bar.value = task_data.current_hp / task_data.max_hp
