class_name PopupDeveloper
extends PanelContainer

var _developer: Developer

@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel
@onready var task_label: Label = %TaskLabel


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer or not _developer.data:
		Log.log_warn(name, "Invalid developer target")
		return
	name_label.text = Constants.DevType.keys()[_developer.data.dev_type]
	stats_label.text = "Фичи: %d  Баги: %d  Рефактор: %d" % [
		_developer.data.feature_speed,
		_developer.data.bug_speed,
		_developer.data.refactor_speed,
	]
	SB.task_finished.connect(_update_task_label.unbind(2))
	_update_task_label()


func _update_task_label() -> void:
	if not is_instance_valid(_developer):
		return
	if _developer.is_idle():
		task_label.text = "Свободен"
	else:
		task_label.text = "Работает"
