class_name DeveloperPopup
extends PanelContainer

var _developer: Developer

@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel
@onready var task_label: Label = %TaskLabel
@onready var fire_button: Button = %FireButton


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer or not _developer.data:
		Log.log_warn(name, "Invalid developer target")
		return
	name_label.text = _developer.data.dev_name
	stats_label.text = "Скорость: %.1f  Качество: %d%%" % [_developer.data.speed, int(_developer.data.quality * 100)]
	fire_button.pressed.connect(_on_fire_pressed)
	SB.task_completed.connect(_update_task_label)
	_update_task_label()


func _update_task_label(_dev: Developer = null, _task: TaskData = null) -> void:
	if not is_instance_valid(_developer):
		return
	if _developer.is_idle():
		task_label.text = "Свободен"
	else:
		task_label.text = "Работает"


func _on_fire_pressed() -> void:
	SB.fire_requested.emit(_developer)
